
module DA_Dev
  module Watch
    extend self

    MTIMES = {} of String => Int64
    PROCESSES = [] of DA_Process

    def file_run
      "tmp/out/watch_run"
    end

    def file_run_once
      "tmp/out/watch_run_once"
    end

    def file_change(args : Array(String) = [] of String)
      File.write(file_run_once, args.join(' '))
    end

    private def bin_path
      File.expand_path File.join(__DIR__, "/../../bin/da_dev")
    end

    def changed?(file : String)
      # Sometimes it takes a few milliseconds for the file to be available
      # between saving and writing to the FS.
      return false if !File.exists?(file)
      MTIMES[file]? != File.stat(file).mtime.epoch
    end

    def reload!(args : Array(String) = [] of String)
      orange!("-=" * 30)
      Process.exec(bin_path, args)
    end

    def run_once(args : Array(String))
      File.write(file_run_once, args.join(" "))
    end

    def run(args : Array(String) = [] of String)
      case
      when args.empty?
        File.touch(file_run)
      else
        File.write(file_run, args.join(' '))
      end
    end # === def run

    def run_if_changed?(file : String)
      return false if !changed?(file)

      orange! "=== {{Running}}: #{file} ==="
      cmd = begin
              str = File.read(file).strip
              if str.empty?
                "#{bin_path} specs compile run"
              else
                str
              end
            end

      run_cmd cmd.split
      MTIMES[file] = File.stat(file).mtime.epoch
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
      when cmd == "#"
        orange! "=== {{Skipping}}: #{cmd} #{args.join " "}"

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
        file_run,
        file_run_once,
      }

      files.each { |x|
        File.touch(x)
        MTIMES[x] = File.stat(x).mtime.epoch
      }

      orange!("=== {{Watching}}...")
      is_watching_this = File.expand_path(Dir.current) == File.expand_path(File.join(Dir.current, "../.."))

      while keep_running
        sleep 0.6

        files.each { |x|
          run_if_changed?(x)
        }
      end
    end

  end # === module Watch
end # === module DA_Dev
