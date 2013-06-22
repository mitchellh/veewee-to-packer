# This file contains mocked out Veewee classes in order to load
# a Veewee definition into a format we like.

module Veewee
  class Definition
    @@captured = nil

    def self.captured
      @@captured
    end

    def self.declare(options)
      @@captured = options
    end
  end

  # Some templates also use "Veewee::Session" so we just alias that
  # to the same thing.
  Session = Definition
end
