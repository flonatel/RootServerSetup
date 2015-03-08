class root_server_setup::backup {
  # to internal network only
  firewall { "307 allow outgoing rsync (IPv4)":
    chain          => 'OUTPUT',
    state          => ['NEW'],
    dport          => '873',
    proto          => 'tcp',
    action         => 'accept',
    destination    => '172.28.172.0/24',
    source         => '172.28.172.1',
  }
}
