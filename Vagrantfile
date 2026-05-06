# ---------------------------------------------------------
# Provider Plugin Dependency Check
# ---------------------------------------------------------
# Detect the intended provider from arguments or environment variables
salt_major_version = "3008"
provider = ENV['VAGRANT_DEFAULT_PROVIDER']
ARGV.each_with_index do |arg, index|
  if arg.start_with?("--provider=")
    provider = arg.split("=")[1]
  elsif arg == "--provider"
    provider = ARGV[index + 1]
  end
end

# Enforce plugin installation for non-native providers
if provider == "libvirt" && !Vagrant.has_plugin?("vagrant-libvirt")
  abort("\n[!] ERROR: The 'vagrant-libvirt' plugin is missing.\n    Please install it by running: vagrant plugin install vagrant-libvirt\n")
elsif provider == "vmware_desktop" && !Vagrant.has_plugin?("vagrant-vmware-desktop")
  abort("\n[!] ERROR: The 'vagrant-vmware-desktop' plugin is missing.\n    Please install it by running: vagrant plugin install vagrant-vmware-desktop\n")
end

# Auto-discover Fedora/RHEL paths for OVMF (Libvirt UEFI)
if ENV['VAGRANT_LIBVIRT_OVMF_CODE'].nil?
  ['/usr/share/edk2/ovmf/OVMF_CODE.fd', '/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd'].each do |ovmf_path|
    if File.exist?(ovmf_path)
      ENV['VAGRANT_LIBVIRT_OVMF_CODE'] = ovmf_path
      break
    end
  end
end

Vagrant.configure("2") do |config|
  # Toggle for Learning Mode vs Automated Testing Mode
  # Usage for vanilla: VAGRANT_VANILLA_MODE=true vagrant up
  is_vanilla = ENV['VAGRANT_VANILLA_MODE'] == 'true'

  # Helper method to configure provider-specific resources
  def configure_providers(node, ram, cpus)
    # VirtualBox
    node.vm.provider "virtualbox" do |vb|
      vb.memory = ram
      vb.cpus = cpus
      vb.gui = false
    end
    
    # VMware Desktop
    node.vm.provider "vmware_desktop" do |vmw|
      vmw.vmx["memsize"] = ram.to_s
      vmw.vmx["numvcpus"] = cpus.to_s
      vmw.gui = false
    end

    # Libvirt (KVM)
    node.vm.provider "libvirt" do |lv|
      lv.memory = ram
      lv.cpus = cpus
      # Libvirt handles synced folders best via rsync or nfs
    end

    # Hyper-V
    node.vm.provider "hyperv" do |hv|
      hv.memory = ram
      hv.cpus = cpus
      hv.vmname = node.vm.hostname
    end
  end

  # ---------------------------------------------------------
  # Rocky Linux 9 - Salt Master
  # ---------------------------------------------------------
  config.vm.define "master" do |master|
    # generic/ boxes from Roboxes usually support all 4 providers
    master.vm.box = "generic/rocky9" 
    master.vm.hostname = "salt-master"
    master.vm.network "private_network", ip: "192.168.56.10"
    
    # Allocate 1GB RAM, 1 CPU
    configure_providers(master, 1024, 1)

    unless is_vanilla
      # Mount the local salt states to the master using modern NFSv4 over TCP
      master.vm.synced_folder "./salt/salt", "/srv/salt", type: "nfs", nfs_udp: false, nfs_version: 4
      master.vm.synced_folder "./salt/pillar", "/srv/pillar", type: "nfs", nfs_udp: false, nfs_version: 4

      master.vm.provision "shell", inline: <<-SHELL
        echo "Configuring Salt Master auto_accept..."
        mkdir -p /etc/salt/master.d
        echo "auto_accept: True" > /etc/salt/master.d/auto_accept.conf

        echo "Configuring local Master Minion..."
        mkdir -p /etc/salt/minion.d
        echo "master: 127.0.0.1" > /etc/salt/minion.d/master.conf
        echo "id: salt-master" > /etc/salt/minion.d/id.conf

        echo "Opening firewall ports for Salt Master..."
        systemctl enable --now firewalld
        firewall-cmd --permanent --add-port=4505-4506/tcp
        firewall-cmd --reload
      SHELL

      master.vm.provision "salt" do |salt|
        salt.install_master = true
        salt.no_minion = false # Run a minion on the master to configure the master
        salt.run_highstate = false
        salt.install_type = "stable"
        salt.version = salt_major_version
      end


      master.vm.provision "shell", inline: <<-SHELL
        systemctl enable --now salt-minion
      SHELL
    end
  end

  # ---------------------------------------------------------
  # Windows Server 2025 - Salt Minions
  # ---------------------------------------------------------
  (1..2).each do |i|
    config.vm.define "win#{i}" do |minion|
      # Ref "gusztavvargadr/windows-server" to create local vagrant box
      minion.vm.box = "local-windows-server"
      minion.vm.hostname = "win#{i}"
      minion.vm.network "private_network", ip: "192.168.56.1#{i}"
      minion.vm.communicator = "winrm"

      # Disable default /vagrant share as Windows guests don't support Libvirt's default NFS
      minion.vm.synced_folder ".", "/vagrant", disabled: true

      # Allocate 2GB RAM, 2 CPUs (Windows needs a bit more power)
      configure_providers(minion, 2048, 2)

      # Enable QEMU agent ONLY for Windows to fix Libvirt WinRM IP detection
      minion.vm.provider "libvirt" do |lv|
        lv.qemu_use_agent = true
      end

      unless is_vanilla
        # Bypass Vagrant's buggy Salt provisioner for Windows
        # and use PowerShell to run the official install script natively
        minion.vm.provision "shell", keep_color: true, inline: <<-SHELL
          Write-Host "Downloading official Salt Bootstrap script..."
          [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
          $bootstrap = "C:\\bootstrap-salt.ps1"
          
          Invoke-WebRequest -Uri "https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.ps1" -OutFile $bootstrap
          
          Write-Host "Running Salt installer for win#{i} and connecting to master..."
          # The script downloads the correct EXE/MSI from Salt Project repos and configures it silently
          & $bootstrap -master "192.168.56.10" -minion "win#{i}" -version #{salt_major_version}
          
          Write-Host "Salt Minion successfully installed and configured."
        SHELL
      end
    end
  end
end
