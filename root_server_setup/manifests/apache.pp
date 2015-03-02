class root_server_setup::apache {

  # From internal network 
  firewall { "306 allow incoming HTTP (IPv4)":
    provider       => $provider,
    chain          => 'INPUT',
    state          => ['NEW'],
    dport          => '80',
    proto          => 'tcp',
    action         => 'accept',
    source         => '172.28.172.0/24',
    destination    => '172.28.172.1',
  }
}
