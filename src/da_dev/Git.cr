
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

  end # === module Git
end # === module DA_Dev
