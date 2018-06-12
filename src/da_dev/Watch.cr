
module DA_Dev
  module Watch

    extend self
    extend DA_Dev
    CMD_ERRORS = [] of Int32 | String

    MTIMES    = {} of String => Int64
    PROCESSES = {} of Int32 => Process

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
      dir = Dir.current.sub("/tmp/out", "")
      Dir.cd(dir)
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

      when cmd == "specs" && args.first? == "run"
        args.shift
        DA_Dev::Specs.run(args)

      when cmd == "specs" && args.first? == "compile" && args[1]? == "run"
        args.shift
        args.shift
        DA_Dev::Specs.compile
        DA_Dev::Specs.run(args)

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
        kill_procs
        run_process_status
        File.delete(pid_file) if File.exists?(pid_file)
        Process.exec(bin_path, ARGV)

      when cmd == "proc"
        orange! "=== {{Process}}: BOLD{{#{full_cmd args}}}"
        # args = "echo a".split
        x = Process.new(args.shift, args, output: STDOUT, input: STDIN, error: STDERR)
        PROCESSES[x.pid] = x
        STDERR.puts "=== New process: #{x.pid}"
        x

      when cmd == "PING" && args.empty?
        orange! "=== {{Running}}: #{cmd} ==="
        green! "=== PONG ==="

      when cmd == "run" && !args.empty?
        bold! "=== {{#{full_cmd args}}} (#{time})"
        cmd = args.shift
        full_cmd = full_cmd(cmd, args)

        # Only show progress output on error:
        system(cmd, args)
        stat = $?
        if !DA_Process.success?(stat)
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

    def run_process_status
      PROCESSES.each { |pid, x|
        if defunct?(pid)
          STDERR.puts "=== Process defunct: #{pid}"
          PROCESSES.delete pid
        end
        if x.terminated?
          STDERR.puts "=== Process terminated: #{pid}"
          PROCESSES.delete pid
        end
      }
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

      keep_running = true

      Dir.mkdir_p("tmp/out")

      green!("-=-= BOLD{{Watching}}: #{File.basename Dir.current} @ #{time} #{"-=" * 23}")
      is_watching_this = File.expand_path(Dir.current) == File.expand_path(File.join(Dir.current, "../.."))

      files = {} of String => Time?
      3.times { |i|
        x = i + 1
        f = "tmp/out/da_dev_run_#{x}"
        files[f] = File.exists?(f) ? mtime(f) : nil
      }

      spawn {
        while keep_running
          run_process_status
          sleep 1
        end
      }

      spawn {
        while keep_running
          files.each { |file, old_time|
            next if !File.file?(file)
            mtime = mtime(file)
            next if mtime == old_time
            files[file] = mtime
            kill_procs
            File.read(file).each_line { |cmd|
              next if cmd.strip.empty?
              if !CMD_ERRORS.empty?
                STDERR.puts "=== Skipping #{cmd} because of previous errors."
                next
              end
              run_cmd(cmd.split)
            }
            CMD_ERRORS.clear
          } # files.each
          sleep 0.5
        end # while
      }

      sleep
    end # === def watch

    def mtime(file)
      File.stat(file).mtime
    end # === def mtime

    def kill_procs
      PROCESSES.each { |pid, x|
        if process_exists?(pid)
          STDERR.puts "=== Killing: #{pid}"
          x.kill
        else
          STDERR.puts "=== Killed: #{pid}"
        end
      }
      3.times { |x|
        break if !process_still_running?
        sleep 1
      }
      PROCESSES.each { |pid, x|
        if defunct?(pid)
          STDERR.puts "!!! DEFUNCT: #{pid}"
        end
        if process_exists?(pid)
          STDERR.puts "!!! Still running: #{pid}"
        end
        if !Process.exists?(pid)
          STDERR.puts "=== Terminated: #{pid}"
        end
      }
    end

    def process_exists?(pid : Int32)
      return false if !Process.exists?(pid) || defunct?(pid)
      Process.exists?(pid)
    end # === def process_exists?

    def defunct?(pid : Int32)
      data = IO::Memory.new
      Process.new("ps", "--no-headers --pid #{pid}".split, output: data, error: data)
      sleep 0.1
      data.rewind
      line = data.to_s
      line["<defunct>"]?
    end

    def process_still_running?
      return false if PROCESSES.empty?
      PROCESSES.any? { |pid, x| process_exists?(pid) }
    end

  end # === module Watch
end # === module DA_Dev
