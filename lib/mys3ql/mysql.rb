require 'mys3ql/shell'

module Mys3ql
  class Mysql
    include Shell

    def initialize(config)
      @config = config
    end

    def dump
      cmd  = "#{@config.bin_path}mysqldump -u'#{@config.user}'"
      cmd += " -p'#{@config.password}'" if @config.password
      cmd += " --quick --single-transaction --create-options"
      cmd += ' --flush-logs --master-data=2 --delete-master-logs' if binary_logging?
      cmd += " #{@config.database} | gzip > #{dump_file}"
      execute cmd
    end

    def clean_up_dump
      File.delete dump_file
      log "deleted #{dump_file}"
    end

    def dump_file
      @dump_file ||= "#{timestamp}.sql.gz"
    end

    private

    def timestamp
      Time.now.utc.strftime "%Y%m%d%H%M"
    end

    def binary_logging?
      @config.bin_log && @config.bin_log.length > 0
    end

  end
end
