class root_server_setup::openvpn {

  firewall { "303 allow incoming OpenVPN":
    provider   => $provider,
    chain    => 'INPUT',
    state    => ['NEW'],
    dport    => '1194',
    proto    => 'tcp',
    action   => 'accept',
  }
}
