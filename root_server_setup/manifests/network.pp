class root_server_setup::network(
  $device     = "eth0",
  $ipaddr1    = "192.168.122.2",
  $netmask1   = "255.255.255.0",
  $network1   = "192.168.122.0",
  $gateway1   = "192.168.122.1",
){
  augeas{ "$device" :
    context => "/files/etc/network/interfaces",
    changes => [
                "set auto[child::1 = '$device']/1 $device",
                "set iface[. = '$device'] $device",
                "set iface[. = '$device']/family inet",
                "set iface[. = '$device']/method static",
                "set iface[. = '$device']/address 87.118.84.116",
                "set iface[. = '$device']/netmask 255.255.255.0",
                "set iface[. = '$device']/network 87.118.84.0",
                "set iface[. = '$device']/gateway 87.118.84.1",
                ],
  }
}
