class root_server_setup::firewall_pre {
  
  Firewall {
    require => undef,
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
