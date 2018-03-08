
require "../src/da_dev"
require "inspect_bang"
require "da_spec"

extend DA_SPEC

describe "DA_Dev" do
  it "sets SHARDS_INSTALL_PATH" do
    path = ENV["SHARDS_INSTALL_PATH"]? || ""
    assert path[/\.shards\/\.install/]? == ".shards/.install"
  end # === it "sets SHARDS_INSTALL_PATH"

  it "sets CRYSTAL_PATH" do
    path = ENV["CRYSTAL_PATH"]? || ""
    assert path[/\.shards\/\.install/]? == ".shards/.install"
  end # === it "sets CRYSTAL_PATH"
end # === desc "DA_DEV"
require "./*"
