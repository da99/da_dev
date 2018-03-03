
module DA_Dev
  module Watch
    class Proc

      getter process  : Process
      getter full_cmd : String
      delegate :terminated?, to: @process
      delegate :exit_signal, :exit_code, to: status
      delegate :signal_exit?, to: status

      def initialize(cmd_args : Array(String))
        @full_cmd = cmd_args.join(" ")
        cmd = cmd_args.shift
        args = cmd_args
        @process = Process.new(cmd, args, output: STDOUT, error: STDERR)
        @is_ended = false
      end # === def initialize

      def status
        process.wait
      end

      def kill
        @process.kill unless terminated?
        @process.wait
      end

      def mark_as_ended
        @is_ended = terminated?
      end

      def ended?
        @is_ended
      end

    end # === struct Proc

    extend self

    MTIMES    = {} of String => Int64
    PROCESSES = Deque(Proc).new

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
      PROCESSES.each { |x|
        run_process_status(x)
        next if x.ended?
        orange! "=== {{Killing}}: #{x.full_cmd}"
        x.kill
        run_process_status(x)
      }
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

      cmd.each_line { |x|
        next if x.strip.empty?
        break if !(run_cmd x.split)
      }
      MTIMES[file] = File.stat(file).mtime.epoch
      true
    end # === def run_if_changed?

    def run_process(args : Array(String))
      orange! "=== {{Running proc}}: BOLD{{#{args.join(" ")}}}"
      x = Proc.new(args)
      PROCESSES.push x
      x
    end # === def run_process

    def run_cmd(args : Array(String))
      this_name = File.basename(Dir.current)
      args = args.map { |x|
        (x == "__") ? this_name : x
      }

      cmd = args.shift
      case
      when cmd == "#"
        orange! "=== {{Skipping}}: #{cmd} #{args.join " "}"

      when cmd == "reload" && args.empty?
        reload!(ARGV)

      when cmd == "proc"
        run_process(args)

      when cmd == "PING" && args.empty?
        green! "=== PONG ==="

      else
        orange! "=== {{Running}}: BOLD{{#{cmd} #{args.join " "}}} (#{Time.now.to_s("%r")})"
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

    def run_process_status(x : Proc)
      return false if x.ended? || !x.terminated?

      x.mark_as_ended

      msg = "=== {{Process done}}: BOLD{{exit #{x.exit_code}#{x.signal_exit? ? ", #{x.exit_signal}" : ""}}} (#{x.full_cmd})"
      if DA_Process.success?(x.status)
        green! msg
      else
        red! msg
      end

      true
    end # === def run_process_status

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

        PROCESSES.each { |x|
          run_process_status(x)
        }
      end
    end

  end # === module Watch
end # === module DA_Dev
