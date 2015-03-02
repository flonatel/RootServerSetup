class root_server_setup::spamfilter {

  $ipv = [4, 6]
  each($ipv) |$vers| {
    $provider = $vers ? {
      4 => 'iptables',
      6 => 'ip6tables',
    }
    
    firewall { "302 allow outgoing razor 2703 (IPv$vers)":
      provider   => $provider,
      chain    => 'OUTPUT',
      state    => ['NEW'],
      dport    => '2703',
      proto    => 'tcp',
      action   => 'accept',
    }

    firewall { "302 allow outgoing razor 7 (IPv$vers)":
      provider   => $provider,
      chain    => 'OUTPUT',
      state    => ['NEW'],
      dport    => '7',
      proto    => 'tcp',
      action   => 'accept',
    }

    firewall { "302 allow outgoing pyzor (IPv$vers)":
      provider   => $provider,
      chain    => 'OUTPUT',
      state    => ['NEW'],
      dport    => '24441',
      proto    => 'udp',
      action   => 'accept',
    }

  }
}
