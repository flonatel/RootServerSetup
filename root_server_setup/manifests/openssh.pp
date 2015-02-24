class root_server_setup::openssh {

  package { 'openssh-server':
    ensure       => 'installed',
  }
  ->
  # firewall logic
  firewall { '100 allow openssh':
    chain   => 'INPUT',
    state   => ['NEW'],
    dport   => '22',
    proto   => 'tcp',
    action  => 'accept',
  }  
}
