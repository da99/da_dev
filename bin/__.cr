
THIS_DIR = File.dirname(__DIR__)

require "../src/da_dev"
require "da_process"

begin
  DA_Dev::CLI.run(ARGV)
rescue e : DA_Dev::Error
  DA_Dev.red! e
  if e.exit_code?
    exit e.exit_code
  end
  exit 1
end
