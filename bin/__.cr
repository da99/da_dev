
ENV["SHARDS_INSTALL_PATH"] = File.join(Dir.current, "/.shards/.install")
ENV["CRYSTAL_PATH"] = "/usr/lib/crystal:#{Dir.current}/.shards/.install"

THIS_DIR = File.dirname(__DIR__)

require "da_process"
require "../src/da_dev"

extend DA_Dev

full_cmd = ARGV.join(" ")
first_two = ARGV[0..1].join(" ")
fin = case

      when full_cmd == "deps"
        DA_Dev.deps

      when ARGV[0]? == "compile"
        ARGV[1..-1].each { |x|
          DA_Dev::Dev.compile(x)
        }

      when full_cmd == "check"
        DA_Dev::Git.development_checkpoint

      when first_two == "dev compile"
        DA_Dev::Dev.compile

      when first_two == "bin compile"
        args = ARGV[2..-1]
        DA_Dev::Bin.compile(args)

      when full_cmd == "cli compile"
        DA_Dev::CLI.compile

      when full_cmd == "git status" || full_cmd == "status"
        DA_Dev::Git.status

      when full_cmd == "git update" || full_cmd == "update"
        DA_Dev::Git.update

      when full_cmd == "specs compile run"
        DA_Dev::Specs.compile
        DA_Dev::Specs.run

      when full_cmd == "specs compile"
        DA_Dev::Specs.compile

      when full_cmd == "specs run"
        DA_Dev::Specs.run

      when full_cmd == "git zsh_prompt"
        print(DA_Dev::Git.zsh_prompt || "")

      when full_cmd == "watch"
        DA_Dev::Watch.watch

      when first_two == "watch run" && ARGV.size > 2
        DA_Dev::Watch.run(ARGV[2..-1])

      when full_cmd == "watch run-last-file"
        DA_Dev::Watch.run_last_file

      when first_two == "watch run-process" && ARGV.size > 2
        DA_Dev::Watch.run_process(ARGV[2..-1])

      when first_two == "watch run-file" && ARGV.size == 3
        DA_Dev::Watch.run_file(ARGV[2])

      when full_cmd == "watch reload"
        DA_Dev::Watch.reload

      when ARGV.first? == "__"
        system("crystal", ARGV[1..-1])
        $?

      when ARGV.first? == "colorize"
        args = ARGV.dup
        args.shift; args.shift
        text = args.join(" ")
        color = ARGV[1]?

        case color

        when "GREEN"
          green! text

        when "ORANGE"
          orange! text

        when "RED"
          red! text

        else
          red! "Invalid color: #{color.inspect} for #{ARGV.inspect}"
          exit 1
        end

      else
        red! "!!! Invalid arguments: #{ARGV.map(&.inspect).join " "}"
        exit 1
      end

if fin.is_a?(Process::Status) && !DA_Process.success?(fin)
  exit!(fin)
end
