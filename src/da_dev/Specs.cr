
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

    def do?(name : String)
      do_file = "tmp/out/do_#{name}"
      return false if !File.exists?(do_file)
      File.delete(do_file) if File.exists?(do_file)
      yield
    end

    def watch
      keep_running = true
      Signal::INT.trap do
        keep_running = false
        Signal::INT.reset
      end

      Git::Files.update_log

      Dir.mkdir_p("tmp/out")

      STDERR.puts Colorize.orange("=== {{Watching}}...")
      while keep_running
        Git::Files.changed.each { |f|
          puts "=== Changed: #{f}"
          ::DA_Dev.file_change f
        }

        do?("specs") do
          system("clear")
          run
          STDERR.puts Colorize.orange("=== {{Watching}}...")
        end

        do?("bin") do
          system("clear")
          is_this = File.join(Dir.current, "bin/da_dev") == PROGRAM_NAME
          stat = Process.run(PROGRAM_NAME, %w[bin compile], output: STDOUT, error: STDERR)
          if DA_Process.success?(stat)
            if is_this
              STDERR.puts Colorize.orange("=== {{Reloading}}: BOLD{{#{PROGRAM_NAME}}}...")
              Process.exec(PROGRAM_NAME, %w[specs watch])
            end
          else
            STDERR.puts Colorize.red("=== {{Exit}}: #{stat.exit_code}")
          end
        end

        sleep 0.6
      end
    end

  end # === module Specs
end # === module DA_Dev
