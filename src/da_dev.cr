
require "./da_dev/*"

module DA_Dev
  extend self

  module Self
    extend self

    def compile?
      bin = "bin/da_dev"
      current = File.stat(bin).mtime.epoch
      source = File.stat("sh/da_dev.cr").mtime.epoch
      if current < source
        compile
      else
        puts "Binary up-to-date."
      end
    end

  end # === module Self

  def deps
    DA_Process.success! "crystal deps update"
    DA_Process.success! "crystal deps prune"
  end # === def deps

end # === module DA_Dev
