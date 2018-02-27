
module DA_Dev
  module CLI
    extend self

    def compile
      name = File.basename(Dir.current)
      bin  = "bin/#{name}.cli"
      tmp  = "tmp/out/#{name}.cli"
      src  = "sh/#{File.basename name, ".cr"}.cli.cr"
      Dir.mkdir_p "tmp/out"
      DA_Process.success! "crystal build #{src} -o #{tmp}"
      File.rename(tmp, bin)
    end

  end # === module CLI
end # === module DA_Dev
