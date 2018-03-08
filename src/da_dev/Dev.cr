
module DA_Dev
  module Dev
    extend self
    extend DA_Dev

    def src
      "dev/__.cr"
    end

    def tmp
      "tmp/out/dev"
    end

    def compile
      if !File.exists?(src)
        STDERR.puts Colorize.red("!!! {{Not found}}: BOLD{{#{src}}}")
        Process.exit 1
      end

      Dir.mkdir_p(File.dirname tmp)
      orange!("=== {{Compiling}}: #{src} -> BOLD{{#{tmp}}}")
      system("crystal build #{src} -o #{tmp}")
      stat = $?
      if DA_Process.success?(stat)
        green!("=== {{DONE}}: #{tmp} ===")
      else
        exit! stat
      end
      stat
    end # === def compile

    def compile(file_name : String)
      unknown_file = true
      case
      when file_name == "shard.yml"
        unknown_file = false
        DA_Dev.deps
      end

      app_name = File.basename(Dir.current)
      dev_bin = "bin/#{app_name}"
      if File.exists?(dev_bin)
        args = ["compile", file_name]
        orange! "=== {{#{dev_bin}}} {{#{args.join(' ')}}}"
        DA_Process.success!(dev_bin, args)
      else
        if unknown_file
          orange! "=== {{Unknown file type}}: BOLD{{#{file_name}}}"
        end
      end
    end # === def compile

  end # === module Dev
end # === module DA_Dev
