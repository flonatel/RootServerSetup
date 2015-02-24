class root_server_setup::network {
  augeas{ "eth0" :
    context => "/files/etc/network/interfaces",
    changes => [
                "set auto[child::1 = 'eth1']/1 eth1",
                "set iface[. = 'eth1'] eth1",
                "set iface[. = 'eth1']/family inet",
                "set iface[. = 'eth1']/method static",
                "set iface[. = 'eth1']/address 87.118.84.116",
                "set iface[. = 'eth1']/netmask 255.255.255.0",
                "set iface[. = 'eth1']/network 87.118.84.0",
                "set iface[. = 'eth1']/gateway 87.118.84.1",
                ],
  }
}
