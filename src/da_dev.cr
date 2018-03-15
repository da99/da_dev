
ENV["SHARDS_INSTALL_PATH"] = File.join(Dir.current, "/.shards/.install")
ENV["CRYSTAL_PATH"] = "/usr/lib/crystal:#{Dir.current}/.shards/.install"

require "da_process"
require "da_redis"
require "inspect_bang"

DA_Redis.port ENV["DEV_REDIS_PORT"].to_i32

module DA_Dev

  THIS_DIR = File.expand_path("#{__DIR__}/..")

  # =============================================================================
  # Exceptions:
  # =============================================================================

  class Error < Exception

    @stat : Process::Status? = nil

    def initialize(@message)
    end

    def initialize(@stat, @message)
    end

    def exit_code?
      stat = @stat
      !stat.nil?
    end

    def exit_code
      stat = @stat
      if !stat.nil?
        return stat.exit_code
      end
      1
    end

  end # === class Error

  # =============================================================================
  # Module:
  # =============================================================================

  CRYSTAL_BIN = "crystal"

  extend self

  def self.bin_name
    "da_dev"
  end

  def self.deps
    DA_Process.success! "#{CRYSTAL_BIN} deps update"
    DA_Process.success! "#{CRYSTAL_BIN} deps prune"
  end # === def deps

  # =============================================================================
  # Instance:
  # =============================================================================

  def bold!(str : String)
    puts Colorize.bold(str)
  end

  def green!(str : String)
    puts Colorize.green(str)
  end

  def red!(str : String)
    STDERR.puts Colorize.red(str)
  end

  def orange!(str : String)
    STDERR.puts Colorize.orange(str)
  end

  {% for x in %w[bold green red orange].map(&.id) %}
    def {{x}}!(e : Exception)
      {{x}}! DA_Dev::Colorize.highlight_exception(e)
    end
  {% end %}

  def exit!(stat : Process::Status)
    return false if DA_Process.success?(stat)
    red! "!!! {{Exit}}: BOLD{{#{stat.exit_code}}}"
    red! "!!! {{Exit Signal}}: BOLD{{#{stat.exit_signal}}}" if stat.signal_exit?
    Process.exit stat.exit_code
    true
  end

  def full_cmd(*args)
    args.map { |x|
      case x
      when String
        x
      when Array
        x.map { |x|
          case x
          when String
            x
          else
            x.inspect
          end
        }.join(' ')
      else
        x.inspect
      end
    }.join(' ')
  end

end # === module DA_Dev

require "./da_dev/*"

