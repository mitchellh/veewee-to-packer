require "fileutils"

module VeeweeToPacker
  module Builders
    class VMware
      GUESTOS_MAP ={
        "Windows8_64"=>"windows8-64",
        "Windows8"=>"windows8",
        "Windows7_64"=>"windows7-64",
        "Windows7"=>"windows7",
        "WindowsNT"=>"winNT",
        "Windows2008"=>"longhorn",
        "Windows2008_64"=>"longhorn-64",
        "WindowsVista_64"=>"winvista-64",
        "WindowsVista"=>"winvista",
        "Windows2003"=>"winnetstandard",
        "Windows2003_64"=>"winnetstandard-64",
        "WindowsXP_64"=>"winXPPro-64",
        "WindowsXP"=>"winXP",
        "Other"=>"other",
        "Other_64"=>"other-64",
        "FreeBSD"=>"freeBSD",
        "FreeBSD_64"=>"freebsd-64",
        "Oracle"=>"oraclelinux",
        "Oracle_64"=>"oraclelinux-64",
        "Debian"=>"debian5",
        "Debian_64"=>"debian5-64",
        "Debian6"=>"debian6",
        "Debian6_64"=>"debian6-64",
        "Gentoo"=>"other26xlinux",
        "Gentoo_64"=>"other26xlinux-64",
        "Linux22"=>"linux",
        "Linux24"=>"other24xlinux",
        "Linux24_64"=>"other24xlinux-64",
        "Linux26"=>"other26xlinux",
        "Linux26_64"=>"other26xlinux-64",
        "RedHat"=>"RedHat",
        "RedHat_64"=>"RedHat_64",
        "RedHat5"=>"rhel5",
        "RedHat5_64"=>"rhel5-64",
        "RedHat6"=>"rhel6",
        "RedHat6_64"=>"rhel6-64",
        "Centos"=>"centos",
        "Centos_64"=>"centos-64",
        "ArchLinux"=>"other26xlinux",
        "ArchLinux_64"=>"other26xlinux-64",
        "OpenSUSE"=>"opensuse",
        "OpenSUSE_64"=>"opensuse-64",
        "SUSE"=>"suse",
        "SUSE_64"=>"suse-64",
        "SLES11"=>"sles11",
        "SLES11_64"=>"sles11-64",
        "Fedora"=>"fedora",
        "Fedora_64"=>"fedora-64",
        "Ubuntu"=>"ubuntu",
        "Ubuntu_64"=>"ubuntu-64",
        "Linux"=>"linux",
        "Solaris"=>"solaris10",
        "Solaris_64"=>"solaris10-64",
        "Solaris9"=>"solaris",
        "Solaris7"=>"solaris7",
        "Solaris8"=>"solaris8",
        "OpenSolaris"=>"solaris10",
        "OpenSolaris_64"=>"solaris-64",
        "OpenBSD"=>"other",
        "OpenBSD_64"=>"other-64",
        "NetBSD"=>"other",
        "NetBSD_64"=>"other-64",
        "ESXi5"=>"vmkernel5",
        "Darwin_10_7"=>"darwin11",
        "Darwin_10_7_64"=>"darwin11-64",
        "Darwin_10_8_64"=>"darwin12-64"
      }

      def self.name
        "vmware-iso"
      end

      def self.convert(input, input_dir, output_dir)
        warnings = []
        builder = { "type" => "vmware-iso" }

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

        if input[:iso_sha256]
          builder["iso_checksum"] = input.delete(:iso_sha256)
          builder["iso_checksum_type"] = "sha256"
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

        builder["vmx_data"] = {}

        if input[:memory_size]
          builder["vmx_data"]["memsize"] = input.delete(:memory_size)
        end

        if input[:cpu_count]
          builder["vmx_data"]["numvcpus"] = input.delete(:cpu_count)
          builder["vmx_data"]["cpuid.coresPerSocket"] = "1"
        end

        if guestos.include? "darwin"
          builder["vmx_data"]["firmware"] = "efi"
          builder["vmx_data"]["keyboardAndMouseProfile"] = "macProfile"
          builder["vmx_data"]["smc.present"] = "TRUE"
          builder["vmx_data"]["hpet0.present"] = "TRUE"
          builder["vmx_data"]["ich7m.present"] = "TRUE"
          builder["vmx_data"]["ehci.present"] = "TRUE"
          builder["vmx_data"]["usb.present"] = "TRUE"
        end

        # Handle VMware Fusion specific settings
        # Only relevant setting is enable_hypervisor_support while turns on vhv
        if input[:vmfusion]
          vmfusion = input.delete(:vmfusion).dup

          if vmfusion[:vm_options]
            options = vmfusion.delete(:vm_options)

            if options["enable_hypervisor_support"]
              builder["vmx_data"]["vhv.enable"] = options.delete("enable_hypervisor_support")
            end
          end

          if vmfusion.length > 0
            vmfusion.each do |key, _|
              warnings << "Unsupported vmfusion key: #{key}"
            end
          end
        end

        # These are unused, so just ignore them.
        input.delete(:disk_format)
        input.delete(:hwvirtex)
        input.delete(:ioapic)
        input.delete(:kickstart_port)
        input.delete(:kickstart_timeout)
        input.delete(:hostiocache)
        input.delete(:iso_download_timeout)
        input.delete(:iso_file)
        input.delete(:pae)
        input.delete(:ssh_host_port)
        input.delete(:ssh_key)
        input.delete(:video_memory_size)
        input.delete(:virtualbox)

        if input.length > 0
          raise Error, "Uknown keys for VMware: #{input.keys.sort.inspect}"
        end

        [builder, warnings]
      end
    end
  end
end
