class root_server_setup::network(
  $device     = "eth0",
  $ipaddr1    = "192.168.122.2",
  $netmask1   = "255.255.255.0",
  $network1   = "192.168.122.0",
  $gateway1   = "192.168.122.1",
  $broadcast1 = "192.168.122.255",
  $dns_nameservers => "",
  $dns_search => "",
){
  augeas{ "$device" :
    context => "/files/etc/network/interfaces",
    changes => [
                "set auto[child::1 = '$device']/1 $device",
                "set iface[. = '$device'] $device",
                "set iface[. = '$device']/family inet",
                "set iface[. = '$device']/method static",
                "set iface[. = '$device']/address $ipaddr1",
                "set iface[. = '$device']/netmask $netmask1",
                "set iface[. = '$device']/network $network1",
                "set iface[. = '$device']/gateway $gateway1",
                "set iface[. = '$device']/broadcast $broadcast1",
                "set iface[. = '$device']/dns-nameservers $dns_nameservers",
                "set iface[. = '$device']/dns-search $dns_search",
                ],
  }
}
