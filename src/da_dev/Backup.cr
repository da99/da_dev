
module DA_Dev
  module Backup
    extend self
    extend DA_Dev

    def dir
      config = "config/dev/repos"
      if File.exists?(config)
        contents = File.read(config).strip
        repos = Deque(String).new
        contents.each_line { |l|
          push_to l
        }
      end
      push_to "origin"
    end

    def push_to(repo : String)
      orange! "=== {{#{repo}}} ==="
      system("git", "push #{repo}".split)
      stat = $?
        if !DA_Process.success?(stat)
          exit stat.exit_code
      end
    end

  end # === module Backup
end # === module DA_Dev
