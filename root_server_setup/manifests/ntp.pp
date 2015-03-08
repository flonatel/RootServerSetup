class root_server_setup::ntp {

#  $ipv = [4, 6]
#  each($ipv) |$vers| {
#    $provider = $vers ? {
#      4 => 'iptables',
#      6 => 'ip6tables',
  #    }

  $vers = 4
  $provider = 'iptables'
  # Currently there is only IPv4 connection to NTP
    
#    firewall { "307 allow incoming NTP (IPv$vers)":
#      provider   => $provider,
#      chain    => 'INPUT',
#      state    => ['NEW'],
#      dport    => '123',
#      source   => 'ntp.keyweb.de',
#      proto    => 'udp',
#      action   => 'accept',
#    }

    firewall { "302 allow outgoing NTP (IPv$vers)":
      provider     => $provider,
      chain        => 'OUTPUT',
      state        => ['NEW'],
      dport        => '123',
#      destination  => 'ntp.keyweb.de',
      proto        => 'udp',
      action       => 'accept',
    }
#  }
}
