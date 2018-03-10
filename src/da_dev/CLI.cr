
module DA_Dev
  module CLI
    extend self
    extend DA_Dev

    def compile
      name = File.basename(Dir.current)
      bin  = "bin/#{name}.cli"
      tmp  = "tmp/out/#{name}.cli"
      src  = "sh/#{File.basename name, ".cr"}.cli.cr"
      Dir.mkdir_p "tmp/out"
      DA_Process.success! "crystal build #{src} -o #{tmp}"
      File.rename(tmp, bin)
    end

    def run(origin : Array(String))
      full_cmd  = origin.join(" ")
      args      = origin.dup
      cmd       = args.shift
      first_two = origin[0..1].join(" ")
      case

      when "-h --help help".split.includes?(full_cmd)
        # === {{CMD}} -h|--help|help
        DA_Dev::Documentation.print_help([__FILE__])

      when full_cmd == "init"
        # === {{CMD}} init
        DA_Dev::Dev.init

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

      when first_two == "watch run" && origin.size > 2
        # === {{CMD}} watch run my cmd with -args
        DA_Dev::Watch.run(origin[2..-1])

      when first_two == "watch proc" && origin.size > 2
        # === {{CMD}} watch proc my cmd with -args
        DA_Dev::Watch.run_process(origin[2..-1])

      when first_two == "watch run-file" && origin.size == 3
        # === {{CMD}} watch run-file file1
        DA_Dev::Watch.run_file(origin[2])

      when full_cmd == "watch reload"
        # === {{CMD}} watch reload
        DA_Dev::Watch.reload

      when origin.first? == "colorize"
        args  = origin.dup
        args.shift; args.shift
        text  = args.join(" ")
        color = origin[1]?

        case color

        when "GREEN"
          green! text

        when "ORANGE"
          orange! text

        when "RED"
          red! text

        else
          raise Error.new("Invalid color: #{color.inspect} for #{origin.inspect}")
        end

      else
        raise Error.new("Invalid arguments: #{full_cmd origin}")
      end
      true
    end # === def run

  end # === module CLI
end # === module DA_Dev
