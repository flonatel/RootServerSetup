class root_server_setup::firewall_post {

  $ipv = [4, 6]
  each($ipv) |$vers| {
    $provider = $vers ? {
      4 => 'iptables',
      6 => 'ip6tables',
    }
    
    firewall { "900 IPv$vers log dropped input chain":
      provider   => $provider,
      chain      => 'INPUT',
      jump       => 'LOG',
      log_level  => '6',
      log_prefix => "[IPTABLES INPUT IPv$vers] dropped ",
      proto      => 'all',
      before     => undef,
    }

    firewall { "900 IPv$vers log dropped forward chain":
      provider   => $provider,
      chain      => 'FORWARD',
      jump       => 'LOG',
      log_level  => '6',
      log_prefix => "[IPTABLES FORWARD IPv$vers] dropped ",
      proto      => 'all',
      before     => undef,
    }

    firewall { "900 IPv$vers log dropped output chain":
      provider   => $provider,
      chain      => 'OUTPUT',
      jump       => 'LOG',
      log_level  => '6',
      log_prefix => "[IPTABLES OUTPUT IPv$vers] dropped ",
      proto      => 'all',
      before     => undef,
    }

    firewall { "910 IPv$vers deny all other input requests":
      provider   => $provider,
      chain      => 'INPUT',
      action     => 'drop',
      proto      => 'all',
      before     => undef,
    }

    firewall { "910 IPv$vers deny all other forward requests":
      provider   => $provider,
      chain      => 'FORWARD',
      action     => 'drop',
      proto      => 'all',
      before     => undef,
    }

    firewall { "910 IPv$vers deny all other output requests":
      provider   => $provider,
      chain      => 'OUTPUT',
      action     => 'drop',
      proto      => 'all',
      before     => undef,
    }
  }
}
