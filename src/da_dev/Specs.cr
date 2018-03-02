
module DA_Dev
  module Specs
    extend self
    extend DA_Dev

    def src
      "specs/__.cr"
    end

    def tmp
      "tmp/out/specs"
    end

    def compile
      Dir.mkdir_p(File.dirname tmp)
      STDERR.puts Colorize.orange "=== {{Compiling}}: specs ==="
      system("crystal", "build #{src} -o tmp/out/specs".split)
      stat = $?
      if DA_Process.success?(stat)
        puts Colorize.green "=== {{DONE}}: compiling specs ==="
      end
      stat
    end

    def run(args = [] of String)
      if !File.exists?(tmp)
        compile
      end

      system(tmp, args)
      stat = $?
      if DA_Process.success?(stat)
        green! "=== {{DONE}}: specs run ==="
      end
      stat
    end # === def run

  end # === module Specs
end # === module DA_Dev
