
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
          raise Error.new " Non-binary file already exists: #{bin}"
        end
      end

      if args.size == 1 && args.first == "release"
        args[0] = "--release"
      end
      is_tmp = args.size == 1 && args.first == "tmp" && args.shift
      args = "build #{src} -o #{tmp}".split.concat(args)
      fin_bin = is_tmp ? tmp : bin
      puts DA_Dev::Colorize.orange "=== {{Compiling}}: #{CRYSTAL_BIN} #{args.join " "} --> BOLD{{#{fin_bin}}}"
      system(CRYSTAL_BIN, args)

      DA_Process.success!($?)

      File.rename(tmp, bin) unless is_tmp
      puts DA_Dev::Colorize.green "=== {{Done}}: #{bin}"
    end


  end # === module Bin
end # === module DA_Dev
