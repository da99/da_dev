
module DA_Dev
  module Bin
    extend self

    def compile
      name = File.basename(Dir.current)
      bin  = "bin/#{name}"
      tmp  = "tmp/out/#{name}"
      src  = "sh/#{File.basename name, ".cr"}.cr"
      Dir.mkdir_p "tmp/out"

      if File.exists?(bin)
        mime = DA_Process.output("file --mime #{bin}").split[1].split("/").first
        if mime != "application"
          STDERR.puts "!!! Non-binary file already exists: #{bin}"
          exit 1
        end
      end

      puts DA_Dev::Colorize.orange "=== {{Compiling}}: #{bin}"
      DA_Process.success! "crystal build #{src} -o #{tmp}"
      File.rename(tmp, bin)
      puts DA_Dev::Colorize.green "=== {{Done}}: #{bin}"
    end


  end # === module Bin
end # === module DA_Dev
