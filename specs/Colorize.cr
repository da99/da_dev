
describe "Colorize.red" do

  it "uses a bold, red color" do
    actual = DA_Dev::Colorize.red("=== {{RED}} ===")
    assert actual == "=== #{"RED".colorize.fore(:red).mode(:bold)} ==="
  end # === it "uses a bold, red color"

end # === desc "Colorize.red"

describe "Colorize.orange" do

  it "uses a bold, yellow color" do
    actual = DA_Dev::Colorize.orange("=== {{Orange is Yellow}} ===")
    assert actual == "=== #{"Orange is Yellow".colorize.fore(:yellow).mode(:bold)} ==="
  end # === it "uses a bold, red color"

end # === desc "Colorize.red"

describe "Colorize.green" do

  it "uses a bold, green color" do
    actual = DA_Dev::Colorize.orange("=== {{This is Green}} ===")
    assert actual == "=== #{"This is Green".colorize.fore(:green).mode(:bold)} ==="
  end # === it "uses a bold, red color"

end # === desc "Colorize.red"
