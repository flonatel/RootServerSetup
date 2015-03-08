class root_server_setup::openssh {
  
  $ipv = [4, 6]
  each($ipv) |$vers| {
    $provider = $vers ? {
      4 => 'iptables',
      6 => 'ip6tables',
    }

    # firewall logic
    firewall { "100 allow openssh (IPv$vers)":
      provider   => $provider,
      chain   => 'INPUT',
      state   => ['NEW'],
      dport   => '22',
      proto   => 'tcp',
      action  => 'accept',
    }
  }
}
