class root_server_setup::firewall_post {
  
  firewall { '900 log dropped input chain':
    chain      => 'INPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => '[IPTABLES INPUT] dropped ',
    proto      => 'all',
    before     => undef,
  }

  firewall { '900 log dropped forward chain':
    chain      => 'FORWARD',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => '[IPTABLES FORWARD] dropped ',
    proto      => 'all',
    before     => undef,
  }

  firewall { '900 log dropped output chain':
    chain      => 'OUTPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => '[IPTABLES OUTPUT] dropped ',
    proto      => 'all',
    before     => undef,
  }

  firewall { "910 deny all other input requests":
    chain      => 'INPUT',
    action     => 'drop',
    proto      => 'all',
    before     => undef,
  }

  firewall { "910 deny all other forward requests":
    chain      => 'FORWARD',
    action     => 'drop',
    proto      => 'all',
    before     => undef,
  }

  firewall { "910 deny all other output requests":
    chain      => 'OUTPUT',
    action     => 'drop',
    proto      => 'all',
    before     => undef,
  }
}
