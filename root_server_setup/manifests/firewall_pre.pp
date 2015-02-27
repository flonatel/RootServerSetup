class root_server_setup::firewall_pre {
  
  Firewall {
    require => undef,
  }

  # For IPv6 ICMP must be allowed: many features rely on this.
  firewall { '000 accept all icmp IPv6 INPUT':
    provider   => 'ip6tables',
    chain    => 'INPUT',
    proto   => 'ipv6-icmp',
    action  => 'accept',
  }
  
  firewall { '000 accept all icmp IPv6 OUTPUT':
    provider   => 'ip6tables',
    chain    => 'OUTPUT',
    proto   => 'ipv6-icmp',
    action  => 'accept',
  }

  $ipv = [4, 6]
  each($ipv) |$vers| {
    $provider = $vers ? {
      4 => 'iptables',
      6 => 'ip6tables',
    }

    # basic in/out
    firewall { "001 accept all to lo interface IPv$vers":
      provider   => $provider,
      chain    => 'INPUT',
      proto    => 'all',
      iniface  => 'lo',
      action   => 'accept',
    }
    firewall { "001 accept all from lo interface IPv$vers":
      provider   => $provider,
      chain    => 'OUTPUT',
      proto    => 'all',
      outiface => 'lo',
      action   => 'accept',
    }
    
    firewall { "003 accept related established rules IPv$vers":
      provider   => $provider,
      chain    => 'INPUT',
      proto    => 'all',
      state    => ['RELATED', 'ESTABLISHED'],
      action   => 'accept',
    }
    
    firewall { "004 accept related established rules IPv$vers":
      provider   => $provider,
      chain    => 'OUTPUT',
      proto    => 'all',
      state    => ['RELATED', 'ESTABLISHED'],
      action   => 'accept',
    }
    
    firewall { "200 allow outgoing dns lookups IPv$vers":
      provider   => $provider,
      chain    => 'OUTPUT',
      state    => ['NEW'],
      dport    => '53',
      proto    => 'udp',
      action   => 'accept',
    }  
    
    firewall { "200 allow outgoing https IPv$vers":
      provider   => $provider,
      chain    => 'OUTPUT',
      state    => ['NEW'],
      dport    => '443',
      proto    => 'tcp',
      action   => 'accept',
    }  
    
    firewall { "200 allow outgoing http IPv$vers":
      provider   => $provider,
      chain    => 'OUTPUT',
      state    => ['NEW'],
      dport    => '80',
      proto    => 'tcp',
      action   => 'accept',
    }
  }
}
