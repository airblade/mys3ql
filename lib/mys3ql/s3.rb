require 'mys3ql/shell'
require 'fog'

module Mys3ql
  class S3
    include Shell

    def initialize(config)
      @config = config
    end

    def push_dump_to_s3(dump_file)
      key      = "#{dumps_prefix}/#{dump_file}"
      copy_key = "#{dumps_prefix}/latest.sql.gz"
      s3_file  = push_to_s3 dump_file, key
      if s3_file
        s3_file.copy @config.bucket, copy_key
        debug "copied #{key} to #{copy_key}"
      end
    end

    def push_bin_logs_to_s3
      if bin_logs_exist?
        Dir["#{@config.bin_log}/*"].each do |file|
          name = File.basename file
          key = "#{bin_logs_prefix}/#{name}"
          push_to_s3 file, key
        end
      end
    end

    def delete_bin_logs_on_s3
      bucket.files.all(:prefix => "#{bin_logs_prefix}").each do |file|
        file.destroy
        debug "destroyed #{file.key}"
      end
    end

    private

    def s3
      @s3 ||= begin
        s = Fog::Storage.new(
          :provider              => 'AWS',
          :aws_secret_access_key => @config.secret_access_key,
          :aws_access_key_id     => @config.access_key_id
        )
        debug 'connected to s3'
        s
      end
    end

    def bucket
      @directory ||= begin
        d = s3.directories.get @config.bucket  # assume bucket exists
        debug "opened bucket #{@config.bucket}"
        d
      end
    end

    # returns Fog::Storage::AWS::File if we pushed, nil otherwise.
    def push_to_s3(local_file_name, s3_key)
      unless bucket.files.head(s3_key)
        s3_file = bucket.files.create(
          :key    => s3_key,
          :body   => File.open(local_file_name),
          :public => false
        )
        debug "pushed #{local_file_name} to #{s3_key}"
        s3_file
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
