class root_server_setup::firewall_post {

  # Duplicate entries for IPv4 and IPv6
  firewall { '900 IPv4 log dropped input chain':
    provider   => 'iptables',
    chain      => 'INPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => '[IPTABLES INPUT] dropped ',
    proto      => 'all',
    before     => undef,
  }

  firewall { '900 IPv6 log dropped input chain':
    provider   => 'ip6tables',
    chain      => 'INPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => '[IPTABLES INPUT] dropped ',
    proto      => 'all',
    before     => undef,
  }

  # Duplicate entries for IPv4 and IPv6
  firewall { '900 IPv4 log dropped forward chain':
    provider   => 'iptables',
    chain      => 'FORWARD',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => '[IPTABLES FORWARD] dropped ',
    proto      => 'all',
    before     => undef,
  }

  firewall { '900 IPv6 log dropped forward chain':
    provider   => 'ip6tables',
    chain      => 'FORWARD',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => '[IPTABLES FORWARD] dropped ',
    proto      => 'all',
    before     => undef,
  }

  # Duplicate entries for IPv4 and IPv6
  firewall { '900 IPv4 log dropped output chain':
    provider   => 'iptables',
    chain      => 'OUTPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => '[IPTABLES OUTPUT] dropped ',
    proto      => 'all',
    before     => undef,
  }

  firewall { '900 IPv6 log dropped output chain':
    provider   => 'ip6tables',
    chain      => 'OUTPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => '[IPTABLES OUTPUT] dropped ',
    proto      => 'all',
    before     => undef,
  }

  # Duplicate entries for IPv4 and IPv6
  firewall { "910 IPv4 deny all other input requests":
    provider   => 'iptables',
    chain      => 'INPUT',
    action     => 'drop',
    proto      => 'all',
    before     => undef,
  }

  firewall { "910 IPv6 deny all other input requests":
    provider   => 'ip6tables',
    chain      => 'INPUT',
    action     => 'drop',
    proto      => 'all',
    before     => undef,
  }

  # Duplicate entries for IPv4 and IPv6
  firewall { "910 IPv4 deny all other forward requests":
    provider   => 'iptables',
    chain      => 'FORWARD',
    action     => 'drop',
    proto      => 'all',
    before     => undef,
  }

  firewall { "910 IPv6 deny all other forward requests":
    provider   => 'ip6tables',
    chain      => 'FORWARD',
    action     => 'drop',
    proto      => 'all',
    before     => undef,
  }

  # Duplicate entries for IPv4 and IPv6
  firewall { "910 IPv4 deny all other output requests":
    provider   => 'iptables',
    chain      => 'OUTPUT',
    action     => 'drop',
    proto      => 'all',
    before     => undef,
  }

  firewall { "910 IPv6 deny all other output requests":
    provider   => 'ip6tables',
    chain      => 'OUTPUT',
    action     => 'drop',
    proto      => 'all',
    before     => undef,
  }
}
