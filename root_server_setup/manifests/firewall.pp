class root_server_setup::firewall {

  package { 'iptables-persistent':
    ensure => 'installed',
  }
  ->
  # iptables purge
  resources { "firewall":
    purge   => true
  }
  Firewall {
    before  => Class['root_server_setup::firewall_post'],
    require => Class['root_server_setup::firewall_pre'],
  }
  class { ['root_server_setup::firewall_pre',
   	   'root_server_setup::firewall_post']: }
}
