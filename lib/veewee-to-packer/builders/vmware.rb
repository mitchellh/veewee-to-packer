module VeeweeToPacker
  module Builders
    class VMware
      def self.convert(input)
        builder = { "type" => "vmware" }

        if input[:boot_cmd_sequence]
          builder["boot_command"] = input.delete(:boot_cmd_sequence).map do |command|
            command.gsub("<Esc>", "<esc>").
              gsub("<Return>", "<return>").
              gsub("<Enter>", "<enter>")
          end
        end

        if input[:boot_wait]
          builder["boot_wait"] = "#{input.delete(:boot_wait)}s"
        end

        builder["iso_md5"] = input.delete(:iso_md5)
        builder["iso_url"] = input.delete(:iso_src)

        builder["ssh_username"] = input.delete(:ssh_user) if input[:ssh_user]
        builder["ssh_password"] = input.delete(:ssh_password) if input[:ssh_password]

        # These are unused, so just ignore them.
        input.delete(:iso_download_timeout)
        input.delete(:iso_file)

        if input.length > 0
          raise Error, "Uknown keys: #{input.keys.sort.inspect}"
        end

        return builder
      end
    end
  end
end
