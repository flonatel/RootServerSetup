class root_server_setup::postfix {

  $ipv = [4, 6]
  each($ipv) |$vers| {
    $provider = $vers ? {
      4 => 'iptables',
      6 => 'ip6tables',
    }
    
    firewall { "301 allow incoming SMTP (IPv$vers)":
      provider   => $provider,
      chain    => 'INPUT',
      state    => ['NEW'],
      dport    => '25',
      proto    => 'tcp',
      action   => 'accept',
    }
    firewall { "302 allow outgoing SMTP (IPv$vers)":
      provider   => $provider,
      chain    => 'OUTPUT',
      state    => ['NEW'],
      dport    => '25',
      proto    => 'tcp',
      action   => 'accept',
    }
  }
}
