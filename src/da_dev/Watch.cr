
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

    def time
      Time.now.to_s("%r")
    end

    def key(name)
      "#{app_name}.da_dev.watch.#{name}"
    end

    def key
      key("run.cmd")
    end

    def tmp_out_da_dev_run
      "tmp/out/da_dev_run"
    end

    def tmp_out_da_dev_run_save
      "tmp/out/da_dev_run_save"
    end

    def default_cmd
      "#{bin_path} specs compile run".split
    end

    def set(key : String, val : String)
      DA_Redis.connect { |r| r.send("SET", key, val) }
    end

    def get(key)
      DA_Redis.connect { |r| r.send("GET", key) }
    end

    def shift
      shift(key)
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

    def push(key : String, cmd : Array(String))
      push(key, cmd.join(' '))
    end

    def push(cmd : String)
      push(key, cmd)
    end

    def push(cmd : Array(String))
      push(key, cmd)
    end

    def push_error(cmd : String)
      red! cmd
      push(key("error"), cmd)
    end

    private def bin_path
      File.expand_path File.join(__DIR__, "/../../bin/da_dev")
    end

    def reload
      push("reload")
    end # === def reload

    def run(args : Array(String))
      if args.empty?
        push_error("!!! No arguments for: run")
        exit 1
      end
      push(["run"].concat args)
    end

    def run_last_file
      last_file = (get(key("last.file")) || "tmp/out/da_dev_run_1").to_s
      if File.exists?(last_file)
        run_file last_file
      else
        push_error("!!! {{File not found}}: #{last_file.inspect} !!!")
        exit 1
      end
    end # === def run_last_file

    def run_file(file_name : String)
      content = begin
                  File.read(file_name).strip
                rescue e : Errno
                  ""
                end

      if content.empty?
        push_error "=== {{File not found}}: BOLD{{#{file_name}}}"
        exit
      end

      set(key("last.file"), file_name)
      content.each_line { |x|
        args = x.strip.split
        next if args.empty?
        push(["run"].concat args)
      }
    end

    def run_process(args : Array(String))
      push(["proc"].concat args)
    end

    def app_name
      File.basename(Dir.current)
    end

    def run_cmd(args : Array(String))
      args = args.map { |x|
        (x == "__") ? app_name : x
      }

      cmd = args.shift
      case
      when cmd == "clear" && args.empty?
        system("clear")

      when cmd == "reset" && args.empty?
        system("reset")

      when cmd == "#"
        orange! "=== {{Skipping}}: #{cmd} #{args.join " "}"

      when cmd == "reload" && args.empty?
        PROCESSES.each { |x|
          run_process_status(x)
          next if x.ended?
          orange! "=== {{Killing}}: #{x.full_cmd}"
          x.kill
          run_process_status(x)
        }
        Process.exec(bin_path, ARGV)

      when cmd == "proc"
        orange! "=== {{Running proc}}: BOLD{{#{args.join(" ")}}}"
        x = Proc.new(args)
        PROCESSES.push x
        x

      when cmd == "PING" && args.empty?
        orange! "=== {{Running}}: #{cmd} ==="
        green! "=== PONG ==="

      when cmd == "run" && !args.empty?
        orange! "=== {{Running}}: BOLD{{#{args.join " "}}} (#{time})"
        cmd = args.shift
        system(cmd, args)
        stat = $?
          if DA_Process.success?(stat)
            green! "=== {{EXIT}}: BOLD{{#{stat.exit_code}}}"
        else
          red! "=== {{EXIT}}: BOLD{{#{stat.exit_code}}}"
          return false
        end

      else
        red! "=== {{Unknown command}}: BOLD{{#{cmd} #{args.join(' ')}}} ==="

      end # case
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
      system("reset")
      DA_Redis.connect { |r|
        r.send("DEL", key)
        r.send("DEL", key("error"))
      }

      keep_running = true
      Signal::INT.trap do
        keep_running = false
        Signal::INT.reset
      end

      Dir.mkdir_p("tmp/out")

      green!("-=-= BOLD{{Watching}} @ #{time} #{"-=" * 23}")
      is_watching_this = File.expand_path(Dir.current) == File.expand_path(File.join(Dir.current, "../.."))

      while keep_running
        sleep 0.1

        e = shift(key("error"))
        while e
          red! e
          e = shift(key("error"))
        end

        cmd = shift
        if cmd
          run_cmd(cmd.split)
        end

        PROCESSES.each { |x|
          run_process_status(x)
        }
      end
    end

  end # === module Watch
end # === module DA_Dev
