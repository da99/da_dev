
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
      orange!("=== {{Compiling}}: #{src}")
      system("crystal build #{src} -o #{tmp}")
      stat = $?
      if DA_Process.success?(stat)
        green!("=== {{DONE}}: #{tmp} ===")
      end
      stat
    end # === def compile

  end # === module Dev
end # === module DA_Dev
