require "veewee-to-packer/error"
require "veewee-to-packer/mock_veewee"
require "veewee-to-packer/version"

module VeeweeToPacker
  # Converts the given Veewee template into a Packer template, outputting
  # the JSON to the given output path.
  def self.convert(input, output)
    begin
      load input
    rescue LoadError => e
      raise Error, "Error loading input template: #{e}"
    end
  end
end
