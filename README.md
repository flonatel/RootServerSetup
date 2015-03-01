# RootServerSetup
(Automatic) Setup and Hardening of a Root Server

## Introduction
After some years I'll change my virtual server provider, because I
want an up to date Linux system with support for OpenVPN and
SELinux. I spend some time to find a new provider. My choice was <a
href="www.keyweb.de">KeyWeb</a>. 

The used virtualization product is KVM; therefore it is possible to
use SELinux and OpenVPN. It is even possible to import an own ISO file
(as of this writing, Debian 8 (Jessie) is still in testing and not in
KeyWeb's portfolio). 

Also they support IPv6 and I ask for a block of addresses.

Because until now I used Ubuntu with Plesk, some of the administration
tasks will change dramatically.  Major requirements are security and
IPv6 accessibility. 

Each and every step setting up this new server will be documented. My
aim is to automate as much as possible. Let's see what can be done.

Some of the default operating system settings should not used in a
production environment.  Especially big companies have their own
special requirements when it comes to security and hardening.  The <a
href="http://www.telekom.com">Deutsche Telekom</a> published their
requirements and created <a href="https://github.com/TelekomLabs">a
project on github</a> that includes the rules for automatically
applying these rules with chef or puppet. 

Because IMHO <a href="www.puppetlabs.com">puppet</a> is easier to
handle, this was chosen for applying the rules.

## Security, Security and Security
One of the major requirements for a root server placed in the Internet
is security.
Be sure: your server will be attacked.
Do not think, this will not happen to me: it will.

During setup of the DNS for my new root server there were some tries
to login over ssh from some Chinese IP address.  The server was two
days old, the uptime was maybe an hour.  There was no service running.
There was no domain name registered.  I switched off the server when I
was not configuring it.

## Setup

### SELinux
As of this writing there is no <tt>selinux-policy-default</tt> in Debian 8 (Jessie).  Therefore this packet must be downloaded from sid and separately installed.

```bash
apt-get install selinux-basics auditd
wget http://ftp.de.debian.org/debian/pool/main/r/refpolicy/selinux-policy-default_2.20140421-9_all.deb
dpkg -i selinux-policy-default_2.20140421-9_all.deb
```

Edit <tt>/etc/default/rcS</tt> and set <tt>FSCKFIX=yes</tt>.

Activate SELinux: <tt># selinux-activate</tt> and reboot. It takes some time to relabel the file system. When done anther reboot is initiated.  The system is then in permissive mode.

Run <tt># check-selinux-installation</tt>. If nothing is printed, everything is fine.

As of the time of this writing, there is <a href="https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=756729">a bug in the selinux-default-policy that prevents the network adapter to be configured correctly</a>.  A workaround is to change <tt>allow-howplug eth0</tt> to <tt>auto eth0</tt> in the <tt>/etc/network/interfaces</tt>.

To enable enforcing use <tt># selinux-config-enforcing</tt> and reboot.

To check if everything went well:
```bash
sestatus 
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             default
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      29
```

### Installation of Puppet
To install puppet, use

```bash
apt-get install puppet puppet-module-puppetlabs-stdlib
puppet module install hardening-os_hardening
puppet module install hardening-ssh_hardening
puppet module install puppetlabs-firewall
```

### Using Puppet Manifests

To use this project - which does mostly all of setting up a complete
root server, download this project (either from release or using git).

In the main directory there is a file <tt>rss.pp</tt>. Adapt this to
your needs then call

```bash
puppet apply --parser future --modulepath=/etc/puppet/modules:/usr/share/puppet/modules:${PWD} rss.pp
```

This sets up the server.

For each of the steps that is done, a small description follows.

#### User Setup
A maintenance user is created.  This is the user which will be able to
log in (only) with the provided key (password is diabled).

Parameters:

* username: name of the maintenance user
* uid: user id
* gid: group id of the maintenance user (if the group does not exists,
  it will be created.
* sshkeys: complete contents of the authorized keys files. This can
  hold more than one key.

#### Firewall
An IPv4 and IPv6 firewall - based on iptables is set up.  All three
queues (INPUT, OUTPUT and FORWARD) are enforced.  This means, also
outgoing communication must be explicitly switched on.

The firewall configuration only sets up the basic rules (LOG, DROP)
and some basic system ports (e.g. output DNS port).  The appropriate
ports for the different services are handled during the service
configuration.

For whatever reason the persistent storage of firewall rules does not
work.  Therefore there is the need to execute

```bash
netfilter-persistent save
```

#### OS Hardening
Based on the Deutsche Telekom Labs hardening requirements, OS
parameters are changed.  Example: password policy is set accordingly,
root login is complelety disabled.

All default parameters are used here, except that IPv6 is switched on.

#### SSH Setup and Hardening
Also for SSH hardening the Deutsche Telekom Labs hardening scripts are
used.  This contains a complete re-write of the sshd config file.

Public keys are placed in a file that the appropriate user cannot
change.  Therefore it is impossible that the user itself extends the
list of keys.

### Postgresql Installation
For some applications (Wordpress, PowerDNS, ...) postgresql is used.

```bash
apt-get install postgresql
```

Default installation will do: database will only a small one and
there will be no heavy use.  All access is from localhost only.

To follow the Deutsche Telekom Labs requirements, you might want to
change the paramters 'log_connections' and 'log_disconnections' to
'on' in the file '/etc/postgresql/9.4/main/postgresql.conf'.

Afterwards a restart is needed:

```bash
systemctl restart postgresql
```

(I'll ignore the requirement, to delete the automatically generated
links to the self-signed server certificate: all communication to and
from the database will be local only.)

### PowerDNS
Because I want to automatically update some of my DNS resolutions,
PowerDNS with a postgresql backend is used (bind does not support
database backends).

```bash
apt-get install pdns-server pdns-backend-pgsql
```

If you a querried if you want to install the database scheme, chose
'Yes'.

Either chose a password or let PowerDNS chose a random one.

The password for accessing the database is written into the file
'/etc/powerdns/pdns.d/pdns.local.gpgsql.conf'.

Changes to this file:
```
allow-recursion=127.0.0.1,::1
carbon-interval=60
carbon-server=::1
local-ipv6=::/128
soa-minimum-ttl=60
```

(Graphite / carbon will be installed later on.)

#### Adding Data
There is mostly no documentation about how to insert data into the
PowerDNS database.  There is a Web-Tool that I will not use.

For adding the basics for a new keyweb server.  It is assumed, that
this is the first domain that is entered and therefore gets the id
'1'.  You might to change the id in your environment.
```sql
INSERT INTO domains(name, type) VALUES('km20808-05.keymachine.de', 'NATIVE');

INSERT INTO records(domain_id, name, type, content, ttl, change_date)
   VALUES(1, 'km20808-05.keymachine.de', 'SOA',
   'hostmaster.km20808-05.keymachine.de', 86400, 2015022601);

INSERT INTO records(domain_id, name, type, content, ttl, change_date)
   VALUES (1, 'km20808-05.keymachine.de', 'NS',
           'ns.km20808-05.keymachine.de', 86400, 2015022601);
INSERT INTO records(domain_id, name, type, content, ttl, change_date)
   VALUES (1, 'km20808-05.keymachine.de', 'NS',
           'ns2.km20808-05.keymachine.de', 86400, 2015022601);

INSERT INTO records(domain_id, name, type, content, ttl, change_date)
   VALUES(1, 'ns.km20808-05.keymachine.de', 'A', '[YourIPv4]',
   	     3600, 2015022601);
INSERT INTO records(domain_id, name, type, content, ttl, change_date)
   VALUES(1, 'ns1.km20808-05.keymachine.de', 'A', '[YourIPv4]',
   	     3600, 2015022601);
INSERT INTO records(domain_id, name, type, content, ttl, change_date)
   VALUES(1, 'hostmaster.km20808-05.keymachine.de', 'A', '[YourIPv4]',
   	     3600, 2015022601);

INSERT INTO records(domain_id, name, type, content, ttl, change_date)
   VALUES(1, 'ns.km20808-05.keymachine.de', 'AAAA', '[YourIPv6]',
   	     3600, 2015022601);
INSERT INTO records(domain_id, name, type, content, ttl, change_date)
   VALUES(1, 'ns1.km20808-05.keymachine.de', 'AAAA',
   	     '[YourIPv6]', 3600, 2015022601);
INSERT INTO records(domain_id, name, type, content, ttl, change_date)
   VALUES(1, 'hostmaster.km20808-05.keymachine.de', 'AAAA',
   	     '[YourIPv6]', 3600, 2015022601);
   
```

### fail2ban
This tool analyzes various log files for possible attackers and tries
to adapt the iptables firewall before they manage to capture the
system.
```bash
se_apt-get install python3
se_dpkg -i fail2ban_0.9.1-1_all.deb
se_apt-get install fail2ban
```

There is a problem, that the current SELinux rules do not allow
writing the PID file in the /var/run/fail2ban directory.

To fix this, use:

```bash
audit2allow -M fail2ban-errata
type=AVC msg=audit(1425105614.776:76): avc:  denied  { write } for  pid=837 comm="fail2ban-client" name="fail2ban" dev="tmpfs" ino=13031 scontext=system_u:system_r:fail2ban_client_t:s0 tcontext=system_u:object_r:var_run_t:s0 tclass=dir permissive=0
type=AVC msg=audit(1425105923.020:108): avc:  denied  { create } for  pid=947 comm="fail2ban-server" name="fail2ban.sock" scontext=system_u:system_r:fail2ban_t:s0 tcontext=system_u:object_r:var_run_t:s0 tclass=sock_file permissive=0
type=AVC msg=audit(1425106118.560:418): avc:  denied  { write } for  pid=999 comm="fail2ban-client" name="fail2ban.sock" dev="tmpfs" ino=16759 scontext=system_u:system_r:fail2ban_client_t:s0 tcontext=system_u:object_r:var_run_t:s0 tclass=sock_file permissive=0
type=AVC msg=audit(1425106256.324:425): avc:  denied  { getattr } for  pid=1002 comm="fail2ban-server" path="/run/fail2ban/fail2ban.sock" dev="tmpfs" ino=16759 scontext=system_u:system_r:fail2ban_t:s0 tcontext=system_u:object_r:var_run_t:s0 tclass=sock_file permissive=0
type=AVC msg=audit(1425107499.072:468): avc:  denied  { unlink } for  pid=1105 comm="fail2ban-server" name="fail2ban.sock" dev="tmpfs" ino=17816 scontext=system_u:system_r:fail2ban_t:s0 tcontext=system_u:object_r:var_run_t:s0 tclass=sock_file permissive=0
type=AVC msg=audit(1425207506.772:8156): avc:  denied  { read } for  pid=874 comm="fail2ban-client" name="urandom" dev="devtmpfs" ino=5598 scontext=system_u:system_r:fail2ban_client_t:s0 tcontext=system_u:object_r:urandom_device_t:s0 tclass=chr_file permissive=0
type=AVC msg=audit(1425207694.272:8197): avc:  denied  { open } for  pid=920 comm="fail2ban-client" path="/dev/urandom" dev="devtmpfs" ino=5598 scontext=system_u:system_r:fail2ban_client_t:s0 tcontext=system_u:object_r:urandom_device_t:s0 tclass=chr_file permissive=0
type=AVC msg=audit(1425207805.068:8225): avc:  denied  { getattr } for  pid=955 comm="fail2ban-client" path="/dev/urandom" dev="devtmpfs" ino=5598 scontext=system_u:system_r:fail2ban_client_t:s0 tcontext=system_u:object_r:urandom_device_t:s0 tclass=chr_file permissive=0
[Ctlr-D]

semodule -i fail2ban-errata.pp
```

Afterwards restart and check:

```bash
run_init systemctl restart fail2ban
run_init systemctl status fail2ban
```
Please note that as of this writing 'fail2ban' does not support IPv6.
IPv6 support must be 'patched' in.  There is a <a
href="http://crycode.de/wiki/Fail2Ban">good description</a> available.

After the change, the SELinux contexts must be corrected:

```bash
chcon --reference=/sbin/iptables /usr/bin/ip64tables
chcon --reference=/etc/fail2ban/action.d/apf.conf /etc/fail2ban/action.d/ip64tables-multiport.conf
chcon --reference=/etc/fail2ban/action.d/apf.conf /etc/fail2ban/action.d/ip64tables-allports.conf
```

Configuration will be done in the '/etc/fail2ban/jail.d' directory. Do
not use the deprecated 'jail.local' any more.

My '/etc/fail2ban/jail.d/settings.conf':
```
[DEFAULT]
bantime = 86400
destmail = root@km20808-05.keymachine.de
sender = fail2ban@km20808-05.keymachine.de
mta = unkown
banaction = ip64tables-multiport
```

(Default SELinux works.)

Because I'm paranoid, I change the blocktype from ICMP host
unreachable to DROP in '/etc/fail2ban/action.d/iptables-blocktype.conf'
and '/etc/fail2ban/action.d/iptables-common.conf'

#### Ban IPs (Portscans)
If somebody sends a packet to a port that is not open, directly ban the approriate IP.

Add the file 'portscan.conf' to the dir '/etc/fail2ban/filter.d':

```
# Option: failregex
# Notes: Looks for attempts on ports not open in your firewall. Expects the
# iptables logging utility to be used. Add the following to your iptables
# config, as the last item before you DROP or REJECT:
[Definition]
failregex = ^.*[IPTABLES INPUT IPv4].*SRC=<HOST>.*\[SRC=.*$
	      ^.*[IPTABLES INPUT IPv4].*SRC=<HOST>.*$
	      
ignoreregex = ^.*[IPTABLES INPUT IPv4].*SRC=0.0.0.0.*$
```

And the portscan action that goes to '/etc/fail2ban/jail.d/portscan.conf':
```
[portscan]
enabled = true
filter  = portscan
action  = ip64tables-allports[name=portscan]
logpath = /var/log/messages
maxretry = 1
bantime  = 86400
```

### EMail Server: Postfix
There are a couple of EMail servers out there.  I'll use postfix.

First run 
```bash
postfix-nochroot
```

In my installation the SELinux context was not correctly set for the
installed directories.  The command to do this manually:

```bash
restorecon -vR /var/spool/postfix
```

Create a virtual mail spool with the following properties:

```bash
drwx------. 3 postfix postdrop unconfined_u:object_r:mail_spool_t:SystemLow 4096 Feb 28 18:59 /var/spool/postfix/vhosts/
```

For each mail domain you host, you need to create an appropriate
subdirectrory with the name of the domain.  The subdirectory must have
the same labels and permissions.

Add the following lines to the file '/etc/postfix/main.cf':


```
# Virtual Users
virtual_mailbox_domains = km20808-05.keymachine.de somedomain.net
virtual_mailbox_base = /var/spool/postfix/vhosts
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_minimum_uid = 100
virtual_uid_maps = static:111
virtual_gid_maps = static:117
virtual_alias_maps = hash:/etc/postfix/virtual
```

Create the files vmailbox and virtual (see <a
href="http://www.postfix.org/VIRTUAL_README.html">postfix
documentation</a>. 

fail2ban configuration for postfix is setting 'enable'
to true in the postfix section.  Also I add 'maxretry = 1'
and 'bantime  = 604800' - I really hate SPAM.

In the current fail2ban packet there is a problem:
in the file '/etc/fail2ban/filter.d/postfix.conf' the
command pipelining must be changed to

in the line 'command pipelining after' you need to add a ']' after the *.
```
^%(__prefix_line)simproper command pipelining after \S+ from [^\[\]]*\[<HOST>\]:.*$
```

Also add the line
```
^%(__prefix_line)sNOQUEUE: reject: RCPT from \S+\[<HOST>\]: 454 4\.7\.1 .* Relay access denied;.*$
```
that matches relay delivery.

Also the '__prefix_line' definition in the common.conf does not match
the default syslog output.  Change it to:

```
__prefix_line = [A-Za-z0-9 :]*%(__bsd_syslog_verbose)s?\s*(?:%(__hostname)s )?(?:%(__kernel_prefix)s )?(?:@vserver_\S+ )?%(__daemon_combs_re)s?\s?%(__daemon_extra_re)s?\s*
```

#### SSHD
-# This will be possible with fail2ban 0.9
-#          (?m)^%(__prefix_line)sConnection from <HOST> port \d* on .* port \d*.*$%(__prefix_line)sfatal: Unable to negotiate a key exchange method \[preauth\]$


#### Ban IPs that deliver spam