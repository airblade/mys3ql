require 'tempfile'
require 'mys3ql/config'
require 'mys3ql/mysql'
require 'mys3ql/s3'

module Mys3ql
  class Conductor

    def self.run(args)
      conductor = Conductor.new args.fetch(:config, nil)
      conductor.debug = args.fetch(:debug, false)

      command = args.fetch(:command)
      if command == 'restore'
        conductor.restore args.fetch(:after, nil)
      else
        conductor.send command
      end
    end

    def initialize(config_file = nil)
      @config = Config.new(config_file)
      @mysql = Mysql.new @config
      @s3 = S3.new @config
    end

    # Dumps the database and uploads it to S3.
    # Copies the uploaded file to the key :latest.
    # Deletes binary logs from the file system.
    # Deletes binary logs from S3.
    def full
      @mysql.dump
      @s3.store @mysql.dump_file
      @mysql.delete_dump
      @s3.delete_bin_logs
    end

    # Uploads mysql's binary logs to S3.
    # The binary logs are left on the file system.
    # Log files already on S3 are not re-uploaded.
    def incremental
      @mysql.each_bin_log do |log|
        @s3.store log, false
      end
    end

    # When 'after' is nil:
    #
    # - downloads the latest dump from S3 and loads it into the database;
    # - downloads each binary log from S3 and loads it into the database.
    #
    # When 'after' is given:
    #
    # - downloads each binary log following 'after' from S3 and loads it into the database.
    #
    # Downloaded files are removed from the file system.
    def restore(after = nil)
      unless after
        # get latest dump
        with_temp_file do |file|
          @s3.retrieve :latest, file
          @mysql.restore file
        end
      end

      # apply bin logs
      begin
        tmpfiles = []
        @s3.each_bin_log(after) do |log|
          file = Tempfile.new 'mys3ql'
          tmpfiles << file
          @s3.retrieve log, file.path
        end
        @mysql.apply_bin_logs tmpfiles.map(&:path)
      ensure
        tmpfiles.each &:close!
      end

      # NOTE: not sure about this:
      # puts "You might want to flush mysql's logs..."
    end

    def debug=(val)
      @config.debug = val
    end

    private

    def with_temp_file(&block)
      file = Tempfile.new 'mys3ql-sql'
      yield file.path
      nil
    ensure
      file.close!
    end
  end
end
