
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

    def key
      "da_dev.run.cmd"
    end

    def key_once
      "da_dev.run-once.cmd"
    end

    def key_prev
      "da_dev.run-prev.cmd"
    end

    def default_cmd
      "#{bin_path} specs compile run".split
    end

    def shift(key : String) : String?
      DA_Redis.connect { |r|
        v = r.send("RPOP", key)
        case v
        when String
          v
        else
          nil
        end
      }
    end # === def shift

    def push(key : String, cmd : String)
      DA_Redis.connect { |r|
        r.send("LPUSH", key, cmd)
      }
    end

    private def bin_path
      File.expand_path File.join(__DIR__, "/../../bin/da_dev")
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

    def set_prev(cmd : String)
      DA_Redis.connect { |r| r.send("SET", key_prev, cmd) }
    end

    def get_prev_cmd : Array(String)?
      DA_Redis.connect { |r|
        v = r.send("GET", key_prev)
        case v
        when String
          return v.split
        else
          return nil
        end
      }
    end

    def run_once(args : Array(String))
      push(key_once, args.join(' '))
    end

    def run(args : Array(String) = [] of String)
      case
      when args.empty?
        run(get_prev_cmd || default_cmd)
      else
        push(key, args.join(' '))
      end
    end # === def run

    def run_process(args : Array(String))
      orange! "=== {{Running proc}}: BOLD{{#{args.join(" ")}}}"
      x = Proc.new(args)
      PROCESSES.push x
      x
    end # === def run_process

    def run_if?(key : String)
      cmd = shift(key)
      return false if !cmd
      if key == self.key
        set_prev(cmd)
      end
      run_cmd(cmd.split)
    end # === def run_if?

    def run_cmd(args : Array(String))
      orange! "=== {{Running}}: #{args.join ' '} ==="
      this_name = File.basename(Dir.current)
      args = args.map { |x|
        (x == "__") ? this_name : x
      }

      cmd = args.shift
      case
      when cmd == "#"
        orange! "=== {{Skipping}}: #{cmd} #{args.join " "}"

      when cmd == "file" && args.size == 1
        content = File.read(args.first) if File.exists?(args.first)
        if content
          content.strip.each_line { |x|
            next if x.strip.empty?
            run_cmd(x.split)
          }
        end

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

      orange!("=== {{Watching}}...")
      is_watching_this = File.expand_path(Dir.current) == File.expand_path(File.join(Dir.current, "../.."))

      while keep_running
        sleep 0.1

        run_if?(key)
        run_if?(key_once)

        PROCESSES.each { |x|
          run_process_status(x)
        }
      end
    end

  end # === module Watch
end # === module DA_Dev
