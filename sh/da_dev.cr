
ENV["SHARDS_INSTALL_PATH"] = File.join(Dir.current, "/.shards/.install")
ENV["CRYSTAL_PATH"] = "/usr/lib/crystal:#{Dir.current}/.shards/.install"

THIS_DIR = File.dirname(__DIR__)

require "da_process"
require "colorize"

module DA_Dev
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

  def compile_cli
    name = File.basename(Dir.current)
    bin  = "bin/#{name}.cli"
    tmp  = "tmp/out/#{name}.cli"
    src  = "sh/#{File.basename name, ".cr"}.cli.cr"
    Dir.mkdir_p "tmp/out"
    DA_Process.success! "crystal build #{src} -o #{tmp}"
    File.rename(tmp, bin)
  end

  def compile_bin
    name = File.basename(Dir.current)
    bin  = "bin/#{name}"
    tmp  = "tmp/out/#{name}"
    src  = "sh/#{File.basename name, ".cr"}.cr"
    Dir.mkdir_p "tmp/out"

    if File.exists?(bin)
      mime = DA_Process.output("file --mime #{bin}").split[1].split("/").first
      if mime != "application"
        STDERR.puts "!!! Non-binary file already exists: #{bin}"
        exit 1
      end
    end

    puts "=== Compiling: #{bin}"
    DA_Process.success! "crystal build #{src} -o #{tmp}"
    File.rename(tmp, bin)
  end

  def deps
    DA_Process.success! "crystal deps update"
    DA_Process.success! "crystal deps prune"
  end # === def deps

end # === module DA_Dev

def error!(s, i : Int32 = 1)
  STDERR.puts "!!! #{s}"
  exit i
end

full_cmd = ARGV.join(" ")
case

when full_cmd == "deps"
  DA_Dev.deps

when full_cmd == "compile bin"
  DA_Dev.compile_bin

when full_cmd == "compile cli"
  DA_Dev.compile_bin

when ARGV.first? == "__"
  args = ARGV.dup
  args.shift
  DA_Process.success! Process.run("crystal", args, output: STDOUT, error: STDERR)

when ARGV.first? == "colorize"
  args = ARGV.dup
  args.shift; args.shift
  text = args.join(" ")
  color = ARGV[1]?
  color_pattern = /\{\{([^\}]+)\}\}/
  bold_pattern = /BOLD{{([^\}]+)}}/
  text = text.gsub(bold_pattern) { |raw, match|
    match.captures.first.colorize.mode(:bold)
  }
  case color

  when "GREEN"
    puts(text.gsub(color_pattern) { |raw, match|
      match.captures.first.colorize.fore(:yellow).mode(:bold)
    })

  when "ORANGE"
    STDERR.puts(text.gsub(color_pattern) { |raw, match|
      match.captures.first.colorize.fore(:yellow).mode(:bold)
    })

  when "RED"
    STDERR.puts(text.gsub(color_pattern) { |raw, match|
      match.captures.first.colorize.fore(:red).mode(:bold)
    })

  else
    error! "Invalid color: #{color.inspect} for #{ARGV.inspect}"
  end

else
  STDERR.puts "!!! Invalid arguments: #{ARGV.inspect}"
  exit 1
end

