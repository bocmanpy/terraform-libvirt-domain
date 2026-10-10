# Cloud-init resource
resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each = { for i in var.vm.cloud_init: i.hostname => i }
  name = each.value.hostname
  meta_data = yamlencode({
    instance-id = each.value.hostname
    local-hostname = each.value.hostname
  })
  user_data = coalesce(
    var.vm.cloud_init_user_data_path != null ? file(each.value.cloud_init_user_data_path) : null,
    templatefile("${path.module}/template/cloud_init_user_data.tftpl",
    { config = each.value }))
  network_config = coalesce(
    var.vm.cloud_init_network_config_path != null ? file(each.value.cloud_init_network_config_path) : null,
    templatefile("${path.module}/template/cloud_init_network_config.tftpl",
    { config = each.value.network_config }))
}

# Volume resource
resource "libvirt_volume" "volume" {
  for_each = { for i in var.vm.volume: i.name => i }

  name = "${each.value.name}.${each.value.type}"
  pool = each.value.pool
  capacity = each.value.capacity != null ? each.value.capacity : null
  capacity_unit = each.value.capacity != null ? "GiB" : null
  target = {
    format = {
      type = each.value.type
    }
  }
  backing_store = each.value.backing_store_path != null ? {
    path   = each.value.backing_store_path
    format = {
      type = each.value.type
    }
  } : null
  create = each.value.create_url != null ? {
    content = {
      url  = each.value.create_url
    }
  } : (each.value.is_cloud_init == true ? {
    content = {
      url  = libvirt_cloudinit_disk.cloudinit[var.vm.cloud_init[0].hostname].path
    }
  } : null)
}

# Domain resource
resource "libvirt_domain" "domain" {
  name         = var.vm.name
  memory       = var.vm.memory
  memory_unit  = "MiB"
  vcpu         = var.vm.vcpu
  autostart    = var.vm.autostart
  running      = var.vm.running
  type         = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

# Mandatory feature for q35 machine type
# https://github.com/dmacvicar/terraform-provider-libvirt/issues/1324
  features = {
    acpi = true
  }

  cpu = {
    mode = "host-passthrough"
  }

  devices = {
    graphics = [
      {
        vnc = {
          auto_port = true
        }
      }
    ],
    serials = [
      {
      target = {
        port = 0
        }
      }
     ],
    consoles = [
      {
      target = {
        port = 0
        type = "serial"
        }
    }],
    channels = var.vm.qemu_agent_enable == true ? local.qemu_agent_channel : null
    disks = local.disks
    interfaces = local.interfaces
  }
}

data "libvirt_domain_interface_addresses" "ipaddr" {
  domain = libvirt_domain.domain.uuid
  source = "agent"
}
