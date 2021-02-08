module Mys3ql
  ShellCommandError = Class.new RuntimeError

  module Shell
    def run(command)
      log command
      result = `#{command}`
      log "==> #{result}" unless result.empty?
      raise ShellCommandError, "error (exit status #{$?.exitstatus}): #{command} ==> #{result}: #{$?}" unless $?.success?
      result
    end

    def log(message)
      puts message if @config.debugging?
    end

  end
end
