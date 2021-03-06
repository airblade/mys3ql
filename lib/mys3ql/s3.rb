require 'mys3ql/shell'
require 'aws-sdk-s3'

module Mys3ql
  class S3
    include Shell

    def initialize(config)
      @config = config
    end

    def store(file, dump = true)
      key = key_for(dump ? :dump : :bin_log, file)
      s3_file = save file, key
      if dump && s3_file
        copy_key = key_for :latest
        s3_file.copy_to bucket: bucket_name, key: copy_key
        log "s3: copied #{key} to #{copy_key}"
      end
    end

    def delete_bin_logs
      each_bin_log do |file|
        file.delete
        log "s3: deleted #{file.key}"
      end
    end

    def each_bin_log(after = nil, &block)
      if after && after !~ /^\d{6}$/
        puts 'Binary log file number must be 6 digits.'
        exit 1
      end

      bucket.objects(prefix: bin_logs_prefix)
            .sort_by { |file| file.key[/\d+/].to_i }
            .select  { |file| after.nil? || (file.key[/\d+/].to_i > after.to_i) }
            .each do |file|
        yield file
      end
    end

    def retrieve(s3_file, local_file)
      key = (s3_file == :latest) ? key_for(:latest) : s3_file.key
      get key, local_file
    end

    private

    def get(s3_key, local_file_name)
      s3.get_object(
        response_target: local_file_name,
        bucket:          bucket_name,
        key:             s3_key
      )
      log "s3: pulled #{s3_key} to #{local_file_name}"
    end

    def save(local_file_name, s3_key)
      if bucket.object(s3_key).exists?
        log "s3: skipped #{local_file_name} - already exists"
        return
      end

      s3_file = bucket.put_object(
        key:           s3_key,
        body:          File.open(local_file_name),
        storage_class: 'STANDARD_IA',
        acl:           'private'
      )
      log "s3: pushed #{local_file_name} to #{s3_key}"
      s3_file
    end

    def key_for(kind, file = nil)
      name = File.basename file if file
      case kind
        when :dump;    "#{dumps_prefix}/#{name}"
        when :bin_log; "#{bin_logs_prefix}/#{name}"
        when :latest;  "#{dumps_prefix}/latest.sql.gz"
      end
    end

    def s3
      @s3 ||= begin
        client = Aws::S3::Client.new(
          secret_access_key: @config.secret_access_key,
          access_key_id:     @config.access_key_id,
          region:            @config.region
        )
        client
      end
    end

    def bucket
      @bucket ||= begin
        b = Aws::S3::Bucket.new bucket_name, client: s3
        raise "S3 bucket #{bucket_name} not found" unless b.exists?
        b
      end
    end

    def bucket_name
      @config.bucket
    end

    def dumps_prefix
      "#{@config.database}/dumps"
    end

    def bin_logs_prefix
      "#{@config.database}/bin_logs"
    end
  end
end
