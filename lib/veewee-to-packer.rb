require "fileutils"

require "veewee-to-packer/builders/vmware"
require "veewee-to-packer/error"
require "veewee-to-packer/mock_veewee"
require "veewee-to-packer/version"

module VeeweeToPacker
  BUILDERS = {
    "vmware" => Builders::VMware
  }

  # Converts the given Veewee template into a Packer template, outputting
  # the JSON to the given output path. The builders that the template will
  # contain is specified by `builders`.
  def self.convert(input, output, builders)
    builders = builders.map do |builder|
      klass = BUILDERS[builder.downcase]
      raise Error, "No such builder: #{builder}" if !klass
      klass
    end

    begin
      load input
    rescue LoadError => e
      raise Error, "Error loading input template: #{e}"
    end

    definition = Veewee::Definition.captured

    # This will be the packer template contents that we'll turn to JSON
    template = {}

    # First, convert the postinstall_files into a shell provisioning step
    if definition[:postinstall_files]
      scripts = definition.delete(:postinstall_files)
      provisioner = {
        "type" => "shell",
        "scripts" => scripts
      }

      template["provisioners"] = [provisioner]

      # Unused fields
      definition.delete(:postinstall_timeout)
    end

    template["builders"] = builders.map do |builder|
      builder.convert(definition.dup)
    end

    p template
  end
end
