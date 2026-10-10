variable "vm" {
  description = "VM variables, related to hardware and settings."
  type = object({
    name   = string
    count  = optional(number, 1)
    vcpu   = optional(number, 1)
    memory = optional(number, 512) # MiB
    autostart = optional(bool, false)
    running   = optional(bool, true)
    qemu_agent_enable = optional(bool, false)
    volume = optional(list(object({
      name = string
      pool = string
      type = string
      dev  = optional(string, null)
      capacity = optional(number, null) # GiB by default
      backing_store_path = optional(string, null)
      create_url = optional(string, null)
      is_cloud_init = optional(bool, false)
    })), [])
    interfaces = optional(list(object({
      type = string
      network = string
    })), [])
    cloud_init_user_data_path = optional(string, null)
    cloud_init_network_config_path = optional(string, null)
    cloud_init = optional(list(object({
      hostname = optional(string, null)
      username = string
      password = string
      ssh_key  = optional(string, null)
      packages = optional(list(string), null)
      timezone = optional(string, "UTC")
      network_config = optional(object({
        interfaces = list(object({
          name = string
          dhcp = optional(bool, false)
          addresses = optional(list(string), null)
          gateway = optional(string, null)
          nameservers = optional(list(string), null)
        }))
      }))
    })), [])
  })
}
