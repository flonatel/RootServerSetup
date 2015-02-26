class root_server_setup::powerdns {

  $ipv = [4, 6]
  each($ipv) |$vers| {
    $provider = $vers ? {
      4 => 'iptables',
      6 => 'ip6tables',
    }
    
    firewall { "300 allow incoming dns lookups (UDP/IPv$vers)":
      provider   => $provider,
      chain    => 'INPUT',
      state    => ['NEW'],
      dport    => '53',
      proto    => 'udp',
      action   => 'accept',
    }
    firewall { "300 allow incoming dns lookups (TCP/IPv$vers)":
      provider   => $provider,
      chain    => 'INPUT',
      state    => ['NEW'],
      dport    => '53',
      proto    => 'tcp',
      action   => 'accept',
    }
  }
}

