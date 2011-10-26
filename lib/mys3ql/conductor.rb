require 'mys3ql/config'
require 'mys3ql/mysql'
require 'mys3ql/s3'

module Mys3ql
  class Conductor

    def self.run(args)
      abort usage unless args.length == 1 && %w[ full inc ].include?(args.first)
      conductor = Conductor.new

      command = args.first
      if command == 'full'
        conductor.full
      else
        conductor.incremental
      end
    end

    def initialize
      @config = Config.new
      @mysql = Mysql.new @config
      @s3 = S3.new @config
    end

    def full
      @mysql.dump 
      @s3.push_dump_to_s3 @mysql.dump_file
      @mysql.clean_up_dump
      @s3.delete_bin_logs_on_s3
    end

    def incremental
      @s3.push_bin_logs_to_s3
    end

    def self.usage
      <<END
usage:
  mys3ql full            - full backup, push to S3
  mys3ql incremental     - push bin logs to S3
END
    end

  end
end
