
require "da_process"

module DA_Dev
  CRYSTAL_BIN = "crystal"

  extend self

  module Self
    extend self

    def compile?
      bin = "bin/da_dev"
      current = File.stat(bin).mtime.epoch
      source = File.stat("sh/da_dev.cr").mtime.epoch
      if current < source
        compile
      else
        puts "Binary up-to-date."
      end
    end

  end # === module Self

  def deps
    DA_Process.success! "crystal deps update"
    DA_Process.success! "crystal deps prune"
  end # === def deps

  def file_change(file_name : String)
    case
    when file_name == "shard.yml"
      deps
    end
  end # === def file_change

  def green!(str : String)
    puts Colorize.green(str)
  end

  def red!(str : String)
    STDERR.puts Colorize.orange(str)
  end

  def orange!(str : String)
    STDERR.puts Colorize.orange(str)
  end

  def exit!(stat : Process::Status)
    return false if DA_Process.success?(stat)
    red! "!!! {{Exit}}: BOLD{{#{stat.exit_code}}}"
    true
  end

end # === module DA_Dev

require "./da_dev/*"

