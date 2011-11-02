require 'mys3ql/shell'

module Mys3ql
  class Mysql
    include Shell

    def initialize(config)
      @config = config
    end

    def dump
      cmd  = "#{@config.bin_path}mysqldump"
      cmd += " --quick --single-transaction --create-options"
      cmd += ' --flush-logs --master-data=2 --delete-master-logs' if binary_logging?
      cmd += cli_options
      cmd += " | gzip > #{dump_file}"
      run cmd
    end

    # flushes logs, loops over each one yielding it to the block
    def each_bin_log
      execute "flush logs"
      logs = Dir.glob("#{@config.bin_log}.[0-9]*").sort
      logs_to_backup = logs #logs[0..-2]  # all logs except the last
      logs_to_backup.each do |log|
        yield log
      end
      #execute "purge master logs to '#{File.basename(logs[-1])}'"
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

    def cli_options
      cmd  = " -u'#{@config.user}'"
      cmd += " -p'#{@config.password}'" if @config.password
      cmd += " #{@config.database}"
    end

    def execute(sql)
      run %Q(#{@config.bin_path}mysql -e "#{sql}" #{cli_options})
    end

  end
end
