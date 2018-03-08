
module DA_Dev
  module Dev
    extend self
    extend DA_Dev

    def init
      repo_name = File.basename(Dir.current)
      shard_name = File.basename(Dir.current, ".cr")
      init_gitignore
      Dir.mkdir_p("src")
      Dir.mkdir_p("specs")
      init_shard_yml(shard_name, repo_name)
    end

    def init_shard_yml(shard_name, repo_name)
      default_contents = <<-EOF
      name: #{shard_name}
      version: 0.0.0
      dependencies:
        da_dev:
          github: da99/da_dev
      development_dependencies:
        da_spec:
          github: da99/da_spec.cr
        da_process:
          github: da99/da_process.cr
      EOF
      if File.exists?("shard.yml")
        DA_Dev.deps
      else
        File.write("shard.yml", default_contents)
        DA_Dev.green! "=== BOLD{{Wrote}}: {{shard.yml}}"
      end
    end # === def init_shard_yml

    def init_gitignore
      file = ".gitignore"
      contents = if File.exists?(file)
                   File.read(file).strip.split("\n")
                 else
                   [] of String
                 end
      contents = contents.concat(%w[/tmp/ /.js_packages/ /shard.lock /.shards/]).sort.uniq
      contents.push("")
      contents = contents.join('\n')
      is_new = File.exists?(file)
      File.write(file, contents)
      if is_new
        DA_Dev.green! "=== BOLD{{Wrote}}: {{#{file}}}"
      else
        DA_Dev.green! "=== BOLD{{Updated}}: {{#{file}}}"
      end
    end

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
      orange!("=== {{Compiling}}: #{src} -> BOLD{{#{tmp}}}")
      system("crystal build #{src} -o #{tmp}")
      stat = $?
      if DA_Process.success?(stat)
        green!("=== {{DONE}}: #{tmp} ===")
      else
        exit! stat
      end
      stat
    end # === def compile

    def compile(file_name : String)
      unknown_file = true
      case
      when file_name == "shard.yml"
        unknown_file = false
        DA_Dev.deps
      end

      app_name = File.basename(Dir.current)
      dev_bin = "bin/#{app_name}"
      if File.exists?(dev_bin)
        args = ["compile", file_name]
        orange! "=== {{#{dev_bin}}} {{#{args.join(' ')}}}"
        DA_Process.success!(dev_bin, args)
      else
        if unknown_file
          orange! "=== {{Unknown file type}}: BOLD{{#{file_name}}}"
        end
      end
    end # === def compile

  end # === module Dev
end # === module DA_Dev
