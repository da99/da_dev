
require "colorize"
module DA_Dev
  module Colorize
    extend self

    COLOR_PATTERN = /\{\{([^\}]+)\}\}/
    BOLD_PATTERN = /BOLD{{([^\}]+)}}/

    def bold(raw : String)
      raw.gsub(BOLD_PATTERN) { |raw, match|
        match.captures.first.colorize.mode(:bold)
      }
    end

    def bold_color(raw : String, color : Symbol)
      bold(raw).gsub(COLOR_PATTERN) { |raw, match|
        match.captures.first.colorize.fore(color).mode(:bold)
      }
    end

    def red(raw : String)
      bold_color(raw, :red)
    end

    def orange(raw : String)
      bold_color(raw, :yellow)
    end

    def green(raw : String)
      bold_color(raw, :green)
    end # === def green

  end # === module Colorize
end # === module DA_Dev
