output "vm_name" {
  description = "Name of created domain(s)"
  value       = libvirt_domain.domain.name
}

output "vm_ipaddr" {
  description = "IPv4 addresses of created domain(s)"
  value       = flatten([
    for interface in data.libvirt_domain_interface_addresses.ipaddr.interfaces : [
        for addr in interface.addrs : addr.addr if interface.name != "lo" && addr.type == "ipv4"
      ]
    ]
  )
}