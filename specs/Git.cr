
describe "Files.load_changes" do
  it "works" do
    DA_Dev::Git::Files.load_changes
    assert true == true
  end # === it "works"
end # === desc "DA_Dev::Git::Files.load_changes"

describe "Files.changed?" do
  it "returns a Boolean" do
    actual = DA_Dev::Git::Files.changed?(".gitignore", Time.now.epoch)
    assert actual == true
  end # === it "returns a Boolean"

  it "returns false if file has not been changed" do
    DA_Dev::Git::Files.update_log
    actual = DA_Dev::Git::Files.changed?(".gitignore", File.stat(".gitignore").mtime.epoch)
    assert actual == false
  end # === it "returns false if file has not been changed"
end # === desc "DA_Dev::Git::Files.changed?"

describe "Files.update_log" do
  it "works" do
    DA_Dev::Git::Files.update_log
    assert DA_Dev::Git::Files.changed.empty? == true
  end # === it "works"
end # === desc "DA_Dev::Git::Files.update_log"
