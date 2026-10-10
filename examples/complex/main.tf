terraform {
  required_version = ">= 1.16.5"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = ">= 0.9.9"
    }
    local = {
      source = "hashicorp/local"
      version = ">= 2.9.1"
    }
  }
}

# Configure the Libvirt Provider
provider "libvirt" {
  uri = "qemu+sshcmd://homepc/system"
}

locals {
  count_start = 1
  name = "virtualmachine"
  ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMytAwKx33nx09V5QoT+jOEHwd5W3zaJTS7nefbEupK6 bob@example.com"
  # Use mkpasswd --method=SHA-512 --rounds=4096
  password = "$6$rounds=4096$Zj9lleF.CkXHr9xE$W1ZrvlCukN1zfRd2iA.eUyo6QcvCKTW.NZ.H7eKOHCq15Wx9qRdlrlJQnNbNkq6XTSy1wr3ZM3GoYZeDGfKqN/"
  images_path = "/var/lib/libvirt/images"
  bridge_name = "int-bridge"
  qemu_agent = true
}

resource "libvirt_network" "bridge" {
  name = local.bridge_name
  autostart = true
  bridge = {
    name = local.bridge_name
  }
}

module "virtualmachine" {
  source = "../../"
  count = 2
  vm = {
    name   = "${local.name}-${count.index + local.count_start}"
    autostart = true
    qemu_agent_enable = local.qemu_agent
    volume = [
    {
      capacity = 10
      dev = "vda"
      name = "system-for-${local.name}-${count.index + local.count_start}"
      pool = "default"
      type = "qcow2"
      backing_store_path = "${local.images_path}/Arch-Linux-x86_64-cloudimg.qcow2"
    },
    {
      capacity = 20
      dev = "vdb"
      name = "data-for-${local.name}-${count.index + local.count_start}"
      pool = "default"
      type = "qcow2"
    },
    {
      name = "cloudinit-for-${local.name}-${count.index + local.count_start}"
      pool = "default"
      dev = "sda"
      type = "iso"
      is_cloud_init = true
    }
    ]
    interfaces = [
    {
      type = "bridge"
      network = "bridge"
    },
    {
      type = "bridge"
      network = libvirt_network.bridge.name
    },
    ]
    cloud_init = [{
      hostname = "${local.name}-${count.index + local.count_start}"
      username = "bocman"
      password = local.password
      ssh_key  = local.ssh_key
      packages = ["openssh-server", "qemu-guest-agent"]
      network_config = {
        interfaces = [
        {
          name = "eth0"
          dhcp = true
        },
        {
          name = "eth1"
          addresses = ["192.168.20.1${count.index + local.count_start}/24"]
          gateway = "192.168.20.1"
        }
        ]
      }
    }]
  }
}

# Create Ansible inventory
resource "local_file" "ansible_inventory" {
  count = local.qemu_agent == true ? 1 : 0
  filename = "inventory.yml"

  content = yamlencode({
    all = {
      children = {
        "virtualmachine_group" = {
          hosts = {
            for vm in module.virtualmachine : vm.vm_name => {
              ansible_host    = vm.vm_ipaddr[0]
            }
          }
        }
      }
    }
  })
  file_permission = "0644"
}
