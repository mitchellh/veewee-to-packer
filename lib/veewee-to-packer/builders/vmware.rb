require "fileutils"

module VeeweeToPacker
  module Builders
    class VMware
      GUESTOS_MAP ={
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
        "vmware"
      end

      def self.convert(input, input_dir, output_dir)
        warnings = []
        builder = { "type" => "vmware" }

        if input[:boot_cmd_sequence]
          builder["boot_command"] = input.delete(:boot_cmd_sequence).map do |command|
            command = command.gsub("<Esc>", "<esc>").
              gsub("<Enter>", "<enter>").
              gsub("<Return>", "<return>").
              gsub("<Tab>", "<tab>").
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
            FileUtils.cp(kickstart_file_src, kickstart_file_dest)
          end

          builder["http_directory"] = "http"
        end

        if input[:iso_download_instructions]
          warnings << "ISO download instructions: #{input.delete(:iso_download_instructions)}"
        end

        builder["iso_md5"] = input.delete(:iso_md5)
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

        # These are unused, so just ignore them.
        input.delete(:disk_format)
        input.delete(:ioapic)
        input.delete(:kickstart_port)
        input.delete(:kickstart_timeout)
        input.delete(:hostiocache)
        input.delete(:iso_download_timeout)
        input.delete(:iso_file)
        input.delete(:pae)
        input.delete(:ssh_host_port)
        input.delete(:ssh_key)

        if input.length > 0
          raise Error, "Uknown keys: #{input.keys.sort.inspect}"
        end

        [builder, warnings]
      end
    end
  end
end
