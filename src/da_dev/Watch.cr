
module DA_Dev
  module Watch
    extend self

    def tell(cmd : String)
      file     = "tmp/out/watch_tell"
      bin_name = File.basename(Dir.current)
      lines    = cmd.split(',').map(&.strip).map { |l|
        l = l.gsub(/^__ /, "#{bin_name} ")
        if bin_name != "d"
          l = l.gsub(/^d /, "#{File.basename(PROGRAM_NAME)} ")
        end
        l
      }
      Dir.mkdir_p File.dirname(file)
      File.write(file, lines.join('\n'))
    end # === def tell

  end # === module Watch
end # === module DA_Dev
