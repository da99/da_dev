
THIS_DIR = File.dirname(__DIR__)

require "da_process"
require "../src/da_dev"

extend DA_Dev

full_cmd = ARGV.join(" ")
args = ARGV.dup
cmd = args.shift
first_two = ARGV[0..1].join(" ")
fin = case

      when "-h --help help".split.includes?(full_cmd)
        # === {{CMD}} -h|--help|help
        DA_Dev::Documentation.print_help([__FILE__])

      when full_cmd == "deps"
        # === {{CMD}} deps
        DA_Dev.deps

      when cmd == "compile"
        # === {{CMD}} compile file1 file2 ...
        args.each { |x|
          DA_Dev::Dev.compile(x)
        }

      when full_cmd == "check"
        # === {{CMD}} check
        DA_Dev::Git.development_checkpoint

      when full_cmd == "backup"
        # === {{CMD}} backup
        DA_Dev::Backup.dir

      when cmd == "print-help"
        # === {{CMD}} print-help file1 file2 ...
        Documentation.print_help(args)

      when full_cmd == "dev compile"
        # === {{CMD}} dev compile
        DA_Dev::Dev.compile

      when first_two == "bin compile"
        # === {{CMD}} bin compile [my optional args]
        args.shift
        DA_Dev::Bin.compile(args)

      when full_cmd == "cli compile"
        DA_Dev::CLI.compile

      when full_cmd == "specs compile run"
        # === {{CMD}} specs compile run
        DA_Dev::Specs.compile
        DA_Dev::Specs.run

      when full_cmd == "specs compile"
        # === {{CMD}} specs compile
        DA_Dev::Specs.compile

      when full_cmd == "specs run"
        # === {{CMD}} specs run
        DA_Dev::Specs.run

      when full_cmd == "status"
        # === {{CMD}} status
        DA_Dev::Git.status

      when full_cmd == "update"
        # === {{CMD}} update
        DA_Dev::Git.update

      when full_cmd == "git zsh_prompt"
        # === {{CMD}} git zsh_prompt
        print(DA_Dev::Git.zsh_prompt || "")

      when full_cmd == "watch"
        # === {{CMD}} watch
        DA_Dev::Watch.watch

      when first_two == "watch run" && ARGV.size > 2
        # === {{CMD}} watch run my cmd with -args
        DA_Dev::Watch.run(ARGV[2..-1])

      when first_two == "watch run-process" && ARGV.size > 2
        # === {{CMD}} watch run-process my cmd with -args
        DA_Dev::Watch.run_process(ARGV[2..-1])

      when first_two == "watch run-file" && ARGV.size == 3
        # === {{CMD}} watch run-file file1
        DA_Dev::Watch.run_file(ARGV[2])

      when full_cmd == "watch reload"
        # === {{CMD}} watch reload
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
