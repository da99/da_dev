
module DA_Dev
  module Specs
    extend self

    def run
      DA_Process.success!("crystal run specs/specs.cr")
    end # === def run

  end # === module Specs
end # === module DA_Dev
