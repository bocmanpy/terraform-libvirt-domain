locals {
  # That disk types doesn't have a driver options
  disk_images_type = ["iso", "img"]
  # Define attach volumes do domain
  disks = [
    for value in var.vm.volume : {
      source = {
        volume = {
          pool = value.pool
          volume = "${value.name}.${value.type}"
        }
      }
      # Exclude driver section for images type
      driver = !contains(local.disk_images_type, value.type) ? {
        type = value.type
      } : null
      # Add image type disk as cdrom device
      device = contains(local.disk_images_type, value.type) ? "cdrom" : null
      target = value.dev != null ? {
        dev = value.dev
        # Use SATA bus for image type disk
        bus = contains(local.disk_images_type, value.type) ? "sata" : null
      } : null
    }
    # Exclude volumes from domain attach
    if value.dev != null
  ]
  interfaces = [
    for key, value in var.vm.interfaces : {
      type  = value.type
      model = { type = "virtio" }
      source = {
        network = {
          network = value.network
        }
      }
      wait_for_ip = var.vm.qemu_agent_enable == true ? {
        network = "0.0.0.0/0"
        source = "agent"
        timeout = 300
      } : null
    }
  ]
  qemu_agent_channel = [
  {
    source = {
      unix = {
        mode = "bind"
      }
    }
    target = {
      virt_io = {
        name = "org.qemu.guest_agent.0"
      }
    }
  }]
}
