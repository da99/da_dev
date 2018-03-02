
module DA_Dev
  module Watch
    extend self

    MTIMES = {} of String => Int64

    def run_file_change(file : String)
      system("clear")
      bold!("=== Changed: {{#{file}}}")
      case file
      when "shard.yml"
        DA_Dev.deps
        green! "=== {{DONE}}: deps ==="
      end
    end # === def run_file_change

    def file_run
      "tmp/out/file_run"
    end

    def file_run_once
      "tmp/out/file_run_once"
    end

    def file_run_prev
      "tmp/out/file_run_prev"
    end # === def file_run_prev

    def file_change
      "tmp/out/file_change"
    end

    def file_change(x : String)
      file_change([x])
    end # === def file_change

    def file_change(files : Array(String))
      file = "tmp/out/file_change"
      return false if !Dir.exists?(File.dirname file)
      File.open(file, "a") { |f|
        files.each { |x|
          f.puts x.strip
        }
      }
    end

    private def bin_path
      File.expand_path File.join(__DIR__, "/../../bin/da_dev")
    end

    def changed?(file : String)
      MTIMES[file]? != File.stat(file).mtime.epoch
    end

    def reload
      File.write(file_run_once, "reload")
    end

    def reload!(args : Array(String) = [] of String)
      orange! "\n\n"
      Process.exec(PROGRAM_NAME, args)
    end

    def run(args : Array(String) = [] of String)
      cmd = args.join(' ')
      case
      when args.empty?
        File.touch(file_run)
      when cmd == "prev"
        prev = File.read(file_run_prev) if File.exists?(file_run_prev)
        if prev
          File.write(file_run_once, prev)
        else
          File.touch(file_run)
        end
      else
        File.write(file_run_once, cmd)
      end
    end # === def run

    def run_prev
      File.touch file_run_prev
    end

    def run_once
      File.touch file_run_once
    end

    def run_if_changed?(file : String)
      now = Time.now.epoch
      file_epoch = File.stat(file).mtime.epoch
      is_changed = (MTIMES[file]? || 0) != file_epoch
      return false if !is_changed

      cmd = (File.exists?(file) ? File.read(file) : "").strip
      cmd = "#{PROGRAM_NAME} specs compile run" if cmd.empty?

      cmd.each_line { |line|
        run_cmd line.split
      }
      File.write(file_run_prev, cmd)
      MTIMES[file] = file_epoch
      true
    end # === def run_if_changed?

    def run_cmd(args : Array(String))
      this_name = File.basename(Dir.current)
      args = args.map { |x|
        (x == "__") ? this_name : x
      }

      orange! "=== {{Running}}: BOLD{{#{args.join " "}}} (#{Time.now.to_s("%r")})"
      cmd = args.shift
      case
      when cmd == "reload" && args.empty?
        reload!(ARGV)

      when cmd == "PING" && args.empty?
        green! "=== PONG ==="

      else
        system(cmd, args)
        stat = $?
        if DA_Process.success?(stat)
          green! "=== {{EXIT}}: BOLD{{#{stat.exit_code}}}"
        else
          red! "=== {{EXIT}}: BOLD{{#{stat.exit_code}}}"
          return false
        end
      end
      true
    end # === def run

    def watch
      keep_running = true
      Signal::INT.trap do
        keep_running = false
        Signal::INT.reset
      end

      Dir.mkdir_p("tmp/out")
      files = {
        bin_path,
        file_run,
        file_run_once,
        file_run_prev
      }

      files.each { |x|
        File.touch(x)
        MTIMES[x] = File.stat(x).mtime.epoch
      }

      orange!("=== {{Watching}}...")
      while keep_running
        sleep 0.8

        files.each { |x|
          if run_if_changed?(file_run) || run_if_changed?(file_run_once)
            reload! ARGV if changed?(bin_path)
          end
        }

      end
    end

  end # === module Watch
end # === module DA_Dev
