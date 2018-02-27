
module DA_Dev
  module Git
    extend self

    def update
      DA_Process.success! "git add --all"
      DA_Process.success! "git status"
      puts_url_origin
    end

    def status
      DA_Process.success! "git status"
      puts_url_origin
    end

    def puts_url_origin
      origin = DA_Process.new("git remote get-url --all origin")
      if !origin.success?
        STDERR.puts Colorize.red("!!! {{No origin found}}.")
        return false
      end

      urls = [] of String
      origin.output.to_s.each_line { |line|
        puts Colorize.bold("=== {{#{line}}}")
        urls << line
      }

      # Check if origin fetch/push URLs are the same:
      total = urls.size
      uniqs = urls.sort.uniq.size
      if total != uniqs
        STDERR.puts Colorize.red("!!! {{origin URL mismatch}} !!")
        return false
      end
      true
    end

    def current_ref
      head = DA_Process.new("git symbolic-ref --quiet HEAD")
      val = if head.success?
              head.output
            else
              rev = DA_Process.new("git rev-parse --short HEAD")
              if rev.success?
                rev.output
              else
                nil
              end
            end
      val && val.to_s.strip
    end

    def repo?
      p = DA_Process.new("git rev-parse --is-inside-work-tree")
      p.success?
    end

    def clean?
      p = DA_Process.new("git status --porcelain")
      p.success? && p.output.to_s.empty?
    end

    def ahead_of_remote?
      p = DA_Process.new("git status --branch --porcelain")
      p.success? && p.output.to_s[/\[\w+ [0-9]+\]/]?
    end

    def zsh_prompt
      prompt = ""
      git_ref = current_ref
      return nil if !git_ref
      ref = git_ref.gsub("refs/heads/master", "")
      is_app = Dir.current["/apps/"]? != nil
      return nil if !repo?
      if clean?
        if ahead_of_remote?
          prompt += "%{%k%F{red}%}↟ "
        else
          prompt += "%{%k%F{green}%} "
        end
      else
        prompt += "%{%k%F{red}%} "
      end
      prompt += ref
    end

    module Files

      PATH = "tmp/out/changed.txt"
      PATH_DO_COMPILE = "tmp/out/do_compile"
      RECORDS = {} of String => Int64
      CHANGED = {} of String => Int64

      def self.load_changes
        return if !RECORDS.empty?

        Dir.mkdir_p(File.dirname(PATH))
        File.touch(PATH)
        File.each_line(PATH) { |line|
          pieces = line.split('|')
          RECORDS[pieces.first] = pieces.last.to_i64
        }
      end

      def self.changed?(file_name, epoch)
        !RECORDS[file_name]? || RECORDS[file_name] != epoch
      end

      def self.update_log
        Dir.mkdir_p(File.dirname(PATH))
        ls.each_line { |line|
          RECORDS[line] = File.stat(line).mtime.epoch
        }
        File.open(PATH, "w") { |f|
          RECORDS.each { |k, v| f.puts "#{k}|#{v}" }
        }
      end

      def self.ls
        DA_Process.output!("git ls-files --cached --others --exclude-standard")
      end

      def self.changed
        load_changes
        files = [] of String
        ls.each_line { |line|
          if changed?(line, File.stat(line).mtime.epoch)
            files.push(line)
          end
        }
        files
      end

      def self.compile
        return false if !File.exists?(PATH_DO_COMPILE)
        changed.each { |f| yield f }
        yield "compile!"
        File.delete(PATH_DO_COMPILE)
        update_log

        true
      end # === def self.watch

    end # === module Files

  end # === module Git
end # === module DA_Dev
