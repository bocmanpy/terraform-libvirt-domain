In this example two domains will:
* create volume with ArchLinux CloudImg as backing device
* create and attaching second empty volume
* create and use **cloudinit** volume
* create two network interface, one with DHCP and second with IP address
configured via **cloudinit**
* packages will be installed: `openssh-server` and `qemu-guest-agent`

At the end simple ansible inventory creating, gathering DHCP IP from QEMU guest agent
