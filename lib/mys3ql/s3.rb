require 'mys3ql/shell'
require 'fog'

module Mys3ql
  class S3
    include Shell

    def initialize(config)
      @config = config
      Fog::Logger[:warning] = nil
    end

    def store(file, dump = true)
      key = key_for(dump ? :dump : :bin_log, file)
      s3_file = save file, key
      if dump && s3_file
        copy_key = key_for :latest
        s3_file.copy @config.bucket, copy_key
        log "s3: copied #{key} to #{copy_key}"
      end
    end

    def delete_bin_logs
      each_bin_log do |file|
        file.destroy
        log "s3: destroyed #{file.key}"
      end
    end

    def each_bin_log(&block)
      bucket.files.all(:prefix => "#{bin_logs_prefix}").sort_by { |file| file.key[/\d+/].to_i }.each do |file|
        yield file
      end
    end

    def retrieve(s3_file, local_file)
      key = (s3_file == :latest) ? key_for(:latest) : s3_file.key
      get key, local_file
    end

    private

    def get(s3_key, local_file_name)
      s3_file = bucket.files.get s3_key
      File.open(local_file_name, 'wb') do |file|
        file.write s3_file.body
      end
      log "s3: pulled #{s3_key} to #{local_file_name}"
    end

    # returns Fog::Storage::AWS::File if we pushed, nil otherwise.
    def save(local_file_name, s3_key)
      unless bucket.files.head(s3_key)
        s3_file = bucket.files.create(
          :key    => s3_key,
          :body   => File.open(local_file_name),
          :public => false
        )
        log "s3: pushed #{local_file_name} to #{s3_key}"
        s3_file
      end
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
        s = Fog::Storage.new(
          :provider              => 'AWS',
          :aws_secret_access_key => @config.secret_access_key,
          :aws_access_key_id     => @config.access_key_id
        )
        log 's3: connected'
        s
      end
    end

    def bucket
      @directory ||= begin
        d = s3.directories.get @config.bucket
        raise "S3 bucket #{@config.bucket} not found" unless d  # create bucket instead?
        log "s3: opened bucket #{@config.bucket}"
        d
      end
    end

    def dumps_prefix
      "#{@config.database}/dumps"
    end

    def bin_logs_prefix
      "#{@config.database}/bin_logs"
    end

    def bin_logs_exist?
      @config.bin_log && @config.bin_log.length > 0 && File.exist?(@config.bin_log)
    end

  end
end
