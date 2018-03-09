
THIS_DIR = File.dirname(__DIR__)

require "../src/da_dev"
require "da_process"

begin
  DA_Dev::CLI.run(ARGV)
rescue e : DA_Dev::CLI::Error
  DA_Dev.red! e
  exit 1
end
