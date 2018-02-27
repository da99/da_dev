
module DA_Dev
  module Git
    extend self

    def update
      DA_Process.success! "git add --all"
      DA_Process.success! "git status"
      get_url_origin
    end

    def status
      DA_Process.success! "git status"
      get_url_origin
    end

    def get_url_origin
      origin = DA_Process.new("git remote get-url --push --all origin")
      if origin.success?
        origin.output.to_s.each_line { |line|
          puts Colorize.bold("=== BOLD{{#{line}}}")
        }
      else
        STDERR.puts Colorize.red("!!! {{No origin found}}.")
      end
    end

  end # === module Git
end # === module DA_Dev
