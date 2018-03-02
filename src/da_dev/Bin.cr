
module DA_Dev
  module Bin
    extend self

    def compile(args = [] of String)
      name = File.basename(Dir.current)
      bin  = "bin/#{name}"
      tmp  = "tmp/out/#{name}"
      src  = "bin/__.cr"
      Dir.mkdir_p "tmp/out"

      if File.exists?(bin)
        mime = DA_Process.output("file --mime #{bin}").split[1].split("/").first
        if mime != "application"
          STDERR.puts "!!! Non-binary file already exists: #{bin}"
          exit 1
        end
      end

      is_tmp = args.size == 1 && args.first == "tmp" && args.shift
      args = "build #{src} -o #{tmp}".split.concat(args)
      fin_bin = is_tmp ? tmp : bin
      puts DA_Dev::Colorize.orange "=== {{Compiling}}: #{CRYSTAL_BIN} #{args.join " "} --> BOLD{{#{fin_bin}}}"
      system("crystal", args)
      DA_Dev.exit! $?
      File.rename(tmp, bin) unless is_tmp
      puts DA_Dev::Colorize.green "=== {{Done}}: #{bin}"
    end


  end # === module Bin
end # === module DA_Dev
