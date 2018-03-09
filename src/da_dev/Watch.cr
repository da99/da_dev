
module DA_Dev
  module Watch

    extend self
    extend DA_Dev

    MTIMES    = {} of String => Int64
    PROCESSES = Deque(Proc).new

    def time
      Time.now.to_s("%r")
    end

    def pid_file
      "tmp/out/watch_pid"
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
      push(["run-file", file_name])
    end

    def run_process(args : Array(String))
      push(["proc"].concat args)
    end

    def app_name
      File.basename(Dir.current)
    end

    def run_cmd(args : Array(String))
      if args.first? == "__"
        args[0] == app_name
      end

      full_cmd = args.join(' ')
      if full_cmd[" compile"]?
        system("clear")
      end

      cmd = args.shift
      case

      when cmd == "bin" && args.first? == "compile"
        args.shift
        DA_Dev::Bin.compile(args)

      when cmd == "run-file" && args.size == 1
        file = args.shift
        begin
          last_result = true
          File.read(file).strip.each_line { |l|
            next if l.strip.empty?
            args = l.split
            case

            when args.first? == "#"
              orange! "=== {{#{args.join " "}}}"
              next

            when last_result != true
              red! "!!! {{Skipping}}: #{args.join ' '}"

            when %w[run-file reload].includes?(args.first?)
              red! "!!! {{Not allowed in a run-file}}: #{args.inspect}"
              last_result = false

            else
              last_result = run_cmd(args)

            end # === case
          }
          last_result
        rescue e : Errno
          red! "!!! {{File not found}}: BOLD{{#{file}}}"
          return false
        end

      when cmd == "clear" && args.empty?
        system("clear")

      when cmd == "reset" && args.empty?
        system("reset")

      when cmd == "#"
        orange! "=== {{Skipping}}: #{full_cmd cmd, args}"

      when cmd == "reload" && args.empty?
        PROCESSES.each { |x|
          run_process_status(x)
          next if x.ended?
          orange! "=== {{Killing}}: #{x.full_cmd}"
          x.kill
          run_process_status(x)
        }
        File.delete(pid_file) if File.exists?(pid_file)
        Process.exec(bin_path, ARGV)

      when cmd == "proc"
        orange! "=== {{Process}}: BOLD{{#{full_cmd args}}}"
        x = Proc.new(args)
        PROCESSES.push x
        x

      when cmd == "PING" && args.empty?
        orange! "=== {{Running}}: #{cmd} ==="
        green! "=== PONG ==="


      when cmd == "run" && args.first? == DA_Dev.bin_name
        args.shift
        DA_Dev::CLI.run(args)
        # No other message to user needed here,
        # because CLI.run (most likely) already
        # printed something

      when cmd == "run" && !args.empty?
        bold! "=== {{#{full_cmd args}}} (#{time})"
        cmd = args.shift
        system(cmd, args)
        stat = $?
        full_cmd = full_cmd(cmd, args)
        if DA_Process.success?(stat)
          green! "=== {{EXIT}}: BOLD{{#{stat.exit_code}}} (#{full_cmd})"
        else
          red! "!!! {{EXIT}}: BOLD{{#{stat.exit_code}}} (#{full_cmd})"
          return false
        end

      else
        red! "=== {{Unknown command}}: BOLD{{#{full_cmd(cmd, args)}}} ==="
        return false

      end # case
      true
    rescue e
      if e.is_a?(DA_Dev::Error)
        red! e
      else
        red! "{{#{e.class}}}: BOLD{{#{e.message}}}"
      end
      return false
    end # === def run

    def run_process_status(x : Proc)
      return false if x.ended? || !x.terminated?

      x.mark_as_ended

      msg = "=== {{Process}}: BOLD{{exit #{x.exit_code}#{x.signal_exit? ? ", #{x.exit_signal}" : ""}}} (#{x.full_cmd})"
      if DA_Process.success?(x.status)
        green! msg
      else
        red! msg
      end

      true
    end # === def run_process_status

    def watch
      Dir.mkdir_p(File.dirname(pid_file))
      this_pid = Process.pid

      begin
        old = File.read(pid_file).strip
        if !old.empty? && Process.exists?(old.to_i)
          red! "!!! {{Already running}}: pid BOLD{{#{old}}}"
          exit 1
        end
      rescue e : Errno
      end

      File.write(pid_file, this_pid)

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

        while e = shift(key("error"))
          red! e
        end

        cmd = shift
        run_cmd(cmd.split) if cmd

        PROCESSES.each { |x|
          run_process_status(x)
        }
      end
    end # === def watch

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

  end # === module Watch
end # === module DA_Dev
