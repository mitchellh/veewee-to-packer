module VeeweeToPacker
  module Builders
    class VirtualBox
      GUESTOS_MAP ={
        "Windows7_64"=>"Windows7_64",
        "Windows7"=>"Windows7",
        "Windows8"=>"Windows8",
        "Windows8_64"=>"Windows8_64",
        "WindowsNT"=>"WindowsNT",
        "Windows2008"=>"Windows2008",
        "Windows2008_64"=>"Windows2008_64",
        "WindowsVista_64"=>"WindowsVista_64",
        "WindowsVista"=>"WindowsVista",
        "Windows2003"=>"Windows2003",
        "Windows2003_64"=>"Windows2003_64",
        "WindowsXP_64"=>"WindowsXP_64",
        "WindowsXP"=>"WindowsXP",
        "Windows2000"=>"Windows200",
        "WindowsNT4"=>"WindowsNT4",
        "WindowsMe"=>"WindowsMe",
        "Windows98"=>"Windows98",
        "Windows95"=>"Windows95",
        "Windows31"=>"Windows31",
        "Other"=>"Other",
        "Other_64"=>"Other_64",
        "FreeBSD"=>"FreeBSD",
        "FreeBSD_64"=>"FreeBSD_64",
        "Oracle"=>"Oracle",
        "Oracle_64"=>"Oracle_64",
        "Debian"=>"Debian",
        "Debian_64"=>"Debian_64",
        "Debian6"=>"Debian",
        "Debian6_64"=>"Debian_64",
        "Gentoo"=>"Gentoo",
        "Gentoo_64"=>"Gentoo_64",
        "Linux22"=>"Linux22",
        "Linux24"=>"Linux24",
        "Linux24_64"=>"Linux24_64",
        "Linux26"=>"Linux26",
        "Linux26_64"=>"Linux26_64",
        "RedHat"=>"RedHat",
        "RedHat_64"=>"RedHat_64",
        "RedHat5"=>"RedHat",
        "RedHat5_64"=>"RedHat_64",
        "RedHat6"=>"RedHat",
        "RedHat6_64"=>"RedHat_64",
        "Centos"=>"RedHat",
        "Centos_64"=>"RedHat_64",
        "ArchLinux"=>"ArchLinux",
        "ArchLinux_64"=>"ArchLinux_64",
        "OpenSUSE"=>"OpenSUSE",
        "OpenSUSE_64"=>"OpenSUSE_64",
        "SUSE"=>"OpenSUSE",
        "SUSE_64"=>"OpenSUSE_64",
        "Fedora"=>"Fedora",
        "Fedora_64"=>"Fedora_64",
        "Ubuntu"=>"Ubuntu",
        "Ubuntu_64"=>"Ubuntu_64",
        "Linux"=>"Linux",
        "Solaris"=>"Solaris",
        "Solaris_64"=>"Solaris_64",
        "Solaris9"=>"Solaris",
        "Solaris7"=>"Solaris",
        "Solaris8"=>"Solaris",
        "OpenSolaris"=>"OpenSolaris",
        "OpenSolaris_64"=>"OpenSolaris_64",
        "OpenBSD"=>"OpenBSD",
        "OpenBSD_64"=>"OpenBSD_64",
        "NetBSD"=>"NetBSD",
        "NetBSD_64"=>"NetBSD_64"
      }

      def self.name
        "virtualbox"
      end

      def self.convert(input, input_dir, output_dir)
        warnings =[]
        builder = { "type" => "virtualbox" }

        if input[:boot_cmd_sequence]
          builder["boot_command"] = input.delete(:boot_cmd_sequence).map do |command|
            command = command.gsub("<Esc>", "<esc>").
              gsub("<Enter>", "<enter>").
              gsub("<Return>", "<return>").
              gsub("<Spacebar>", " ").
              gsub("<Tab>", "<tab>").
              gsub("<Wait>", "<wait>").
              gsub("<Backspace>", "<bs>").
              gsub("%NAME%", "{{ .Name }}").
              gsub("%IP%", "{{ .HTTPIP }}").
              gsub("%PORT%", "{{ .HTTPPort }}")

            # We insert a wait after every command because that is the behavior
            # of Veewee
            "#{command}<wait>"
          end
        end

        if input[:boot_wait]
          builder["boot_wait"] = "#{input.delete(:boot_wait)}s"
        end

        if input[:disk_size]
          builder["disk_size"] = input.delete(:disk_size).to_i
        end

        if input[:floppy_files]
          builder["floppy_files"] = input.delete(:floppy_files).map do |file|
            files_dir = output_dir.join("floppy")
            files_dir.mkpath

            file_source = Pathname.new(File.expand_path(file, input_dir))
            file_dest = files_dir.join(file_source.basename)

            if !file_source.file?
              raise Error, "Floppy file could not be found: #{file_source}\n" +
                "Please make sure the Veewee definition you're converting\n" +
                "was copied with all of its original accompanying files."
            end

            FileUtils.cp(file_source, file_dest)
            "floppy/#{file_dest.basename}"
          end
        end

        if input[:os_type_id]
          guestos_id = input.delete(:os_type_id)
          guestos = GUESTOS_MAP[guestos_id]
          if !guestos
            guestos = "other"
            warnings << "Unknown guest OS type: '#{guestos_id}'. Using 'other'."
          end

          builder["guest_os_type"] = guestos
        end

        if input[:kickstart_file]
          http_dir = output_dir.join("http")
          http_dir.mkpath

          kickstart_file = input.delete(:kickstart_file)
          kickstart_file = [kickstart_file] if !kickstart_file.is_a?(Array)

          kickstart_file.each do |single_file|
            kickstart_file_src = Pathname.new(File.expand_path(single_file, input_dir))
            kickstart_file_dest = http_dir.join(kickstart_file_src.basename)

            if !kickstart_file_src.file?
              raise Error, "The kickstart file below is specified in the definition but\n" +
                "is a directory and not a file. The kickstart file list should be files.\n\n" +
                kickstart_file_src.to_s
            end

            FileUtils.cp(kickstart_file_src, kickstart_file_dest)
          end

          builder["http_directory"] = "http"
        end

        if input[:iso_download_instructions]
          warnings << "ISO download instructions: #{input.delete(:iso_download_instructions)}"
        end

        if input[:iso_md5]
          builder["iso_checksum"] = input.delete(:iso_md5)
          builder["iso_checksum_type"] = "md5"
        end

        if input[:iso_sha1]
          builder["iso_checksum"] = input.delete(:iso_sha1)
          builder["iso_checksum_type"] = "sha1"
        end

        builder["iso_url"] = input.delete(:iso_src)

        builder["ssh_username"] = input.delete(:ssh_user) if input[:ssh_user]
        builder["ssh_password"] = input.delete(:ssh_password) if input[:ssh_password]
        builder["ssh_port"] = input.delete(:ssh_guest_port).to_i if input[:ssh_guest_port]
        builder["ssh_wait_timeout"] = "#{input.delete(:ssh_login_timeout)}s" if input[:ssh_login_timeout]

        builder["shutdown_command"] = input.delete(:shutdown_cmd) if input[:shutdown_cmd]
        if builder["shutdown_command"] && input[:sudo_cmd]
          sudo_command = input.delete(:sudo_cmd).
            gsub("%p", builder["ssh_password"]).
            gsub("%f", "shutdown.sh")

          builder["shutdown_command"] = "echo '#{builder["shutdown_command"]}' > shutdown.sh; #{sudo_command}"
        end

        builder["guest_additions_path"] = "VBoxGuestAdditions_{{.Version}}.iso"
        builder["virtualbox_version_file"] = ".vbox_version"

        builder["vboxmanage"] = []

        if input[:memory_size]
          builder["vboxmanage"] << [
            "modifyvm", "{{.Name}}", "--memory", input.delete(:memory_size)]
        end

        if input[:cpu_count]
          builder["vboxmanage"] << [
            "modifyvm", "{{.Name}}", "--cpus", input.delete(:cpu_count)]
        end

        if input[:video_memory_size]
          builder["vboxmanage"] << [
            "modifyvm", "{{.Name}}", "--vram", input.delete(:video_memory_size)]
        end

        # Taken directly from Veewee, all the flags that VirtualBox definitions
        # can have.
        vm_flags = %w{pagefusion acpi ioapic pae hpet hwvirtex hwvirtexcl nestedpaging largepages vtxvpid synthxcpu rtcuseutc}
        vm_flags.each do |flag|
          if input[flag.to_sym]
            builder["vboxmanage"] << [
              "modifyvm", "{{.Name}}",
              "--#{flag}",
              input.delete(flag.to_sym)
            ]
          end
        end

        # Handle virtualbox specific options
        # these are all virtualbox flags
        if input[:virtualbox]
          virtualbox = input.delete(:virtualbox).dup

          if virtualbox[:vm_options]
            virtualbox_flags = virtualbox.delete(:vm_options)
            if !virtualbox_flags[0].nil?
              virtualbox_flags[0].each do |key, value|
                builder["vboxmanage"] << [
                  "modifyvm", "{{.Name}}",
                  "--#{key}",
                  "#{value}"
                ]
              end
            end
          end

          if !virtualbox.empty?
            virtualbox.each do |key, _|
              warnings << "Unsupported virtualbox option: #{key}"
            end
          end
        end

        # These are unused, so just ignore them.
        input.delete(:disk_format)
        input.delete(:hostiocache)
        input.delete(:kickstart_port)
        input.delete(:kickstart_timeout)
        input.delete(:iso_download_timeout)
        input.delete(:iso_file)
        input.delete(:ssh_host_port)
        input.delete(:ssh_key)
        input.delete(:vmfusion)

        if input.length > 0
          raise Error, "Unknown keys for VirtualBox: #{input.keys.sort.inspect}"
        end

        [builder, warnings]
      end
    end
  end
end
