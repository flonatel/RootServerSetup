class root_server_setup::dovecot {

  # From internal network only
  firewall { "304 allow incoming IMAP (IPv$vers)":
    provider       => $provider,
    chain          => 'INPUT',
    state          => ['NEW'],
    dport          => '143',
    proto          => 'tcp',
    action         => 'accept',
    source         => '172.28.172.0/24',
    destination    => '172.28.172.1',
  }
}
