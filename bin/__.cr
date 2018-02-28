
ENV["SHARDS_INSTALL_PATH"] = File.join(Dir.current, "/.shards/.install")
ENV["CRYSTAL_PATH"] = "/usr/lib/crystal:#{Dir.current}/.shards/.install"

THIS_DIR = File.dirname(__DIR__)

require "da_process"
require "../src/da_dev"


full_cmd = ARGV.join(" ")
first_two = ARGV[0..1].join(" ")
fin = case

      when full_cmd == "deps"
        DA_Dev.deps

      when full_cmd == "check"
        DA_Dev::Git.development_checkpoint

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

      when full_cmd == "specs watch"
        DA_Dev::Specs.watch

      when full_cmd == "git zsh_prompt"
        print(DA_Dev::Git.zsh_prompt || "")

      when ARGV.first? == "watch" && ARGV[1]? == "tell" && ARGV[2]?
        DA_Dev::Watch.tell ARGV[2..-1].join(" ")

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
          DA_Dev.green! text

        when "ORANGE"
          DA_Dev.orange! text

        when "RED"
          DA_Dev.red! text

        else
          DA_Dev.red! "Invalid color: #{color.inspect} for #{ARGV.inspect}"
          exit 1
        end

      else
        DA_Dev.red! "!!! Invalid arguments: #{ARGV.inspect}"
        exit 1
      end

if fin.is_a?(Process::Status) && !DA_Process.success?(fin)
  DA_Dev.exit!(fin)
end
