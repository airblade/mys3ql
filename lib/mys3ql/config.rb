require 'yaml'

module Mys3ql
  class Config

    def initialize(config_file = nil)
      config_file = config_file || default_config_file
      @config = YAML.load_file File.expand_path(config_file)
    rescue Errno::ENOENT
      $stderr.puts "missing config file #{config_file}"
      exit 1
    end

    #
    # General
    #

    def debug=(val)
      @debug = val
    end

    def debugging?
      @debug
    end

    #
    # MySQL
    #

    def user
      mysql['user']
    end

    def password
      mysql['password']
    end

    def database
      mysql['database']
    end

    def bin_path
     mysql['bin_path']
    end

    def bin_log
      mysql['bin_log']
    end

    #
    # S3
    #

    def access_key_id
      s3['access_key_id']
    end

    def secret_access_key
      s3['secret_access_key']
    end

    def bucket
      s3['bucket']
    end

    def region
      s3['region']
    end

    private

    def mysql
      @config['mysql']
    end

    def s3
      @config['s3']
    end

    def default_config_file
      File.join "#{ENV['HOME']}", '.mys3ql'
    end
  end
end
