
ENV["SHARDS_INSTALL_PATH"] = File.join(Dir.current, "/.shards/.install")
ENV["CRYSTAL_PATH"] = "/usr/lib/crystal:#{Dir.current}/.shards/.install"

THIS_DIR = File.dirname(__DIR__)

require "da_process"
require "../src/da_dev"

def error!(s, i : Int32 = 1)
  STDERR.puts "!!! #{s}"
  exit i
end

full_cmd = ARGV.join(" ")
case

when full_cmd == "deps"
  DA_Dev.deps

when full_cmd == "bin compile"
  DA_Dev::Bin.compile

when full_cmd == "cli compile"
  DA_Dev::CLI.compile

when full_cmd == "git status" || full_cmd == "status"
  DA_Dev::Git.status

when full_cmd == "git update" || full_cmd == "update"
  DA_Dev::Git.update

when ARGV.first? == "__"
  args = ARGV.dup
  args.shift
  DA_Process.success! Process.run("crystal", args, output: STDOUT, error: STDERR)

when ARGV.first? == "colorize"
  args = ARGV.dup
  args.shift; args.shift
  text = args.join(" ")
  color = ARGV[1]?

  case color

  when "GREEN"
    puts(DA_Dev::Colorize.green(text))

  when "ORANGE"
    STDERR.puts(DA_Dev::Colorize.orange(text))

  when "RED"
    STDERR.puts(DA_Dev::Colorize.red(text))

  else
    error! "Invalid color: #{color.inspect} for #{ARGV.inspect}"
  end

else
  STDERR.puts "!!! Invalid arguments: #{ARGV.inspect}"
  exit 1
end

