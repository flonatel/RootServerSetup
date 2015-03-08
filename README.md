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
type=AVC msg=audit(1425311892.064:33561): avc:  denied  { read write } for  pid=6428 comm="iptables" path=2F746D702F6661693262616E5F30793865307977302E737464657272202864656C6574656429 dev="dm-0" ino=9699391 scontext=system_u:system_r:iptables_t:s0 tcontext=system_u:object_r:fail2ban_tmp_t:s0 tclass=file permissive=0
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

(Default SELinux contexts works.)

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

#### SSH Brakin Attempts
Shortly after setting up the server, I got some messages like:
```
Mar 01 14:15:01 rs3 sshd[18388]: Connection from 115.239.228.15 port 40421 on 87.118.84.116 port 22
Mar 01 14:15:02 rs3 sshd[18388]: fatal: Unable to negotiate a key exchange method [preauth]
```

These are break-in attemts from some Chinese location.  To be able to
check multiline regular expressions, fail2ban >0.9 is needed.

To catch these, add the following line to the section failregex in
'/etc/fail2ban/filter.d/sshd.conf':

```
^%(__prefix_line)sConnection from <HOST> port \d* on .* port \d*.*$%(__prefix_line)sfatal: Unable to negotiate a key exchange method \[preauth\]$
```

Afterwards restart fail2ban.

### OpenVPN
OpenVPN will be the central access way from all clients.  This means,
that, e.g. mail reading and delivery will be only accepted by clients
connected via OpenVPN.

This is only a very rough overview.  Please consult the OpenVPN
documentation setting up a CA, generating the requests and
certificates and setting up the clients.

Set up a CA (you might want to use EaysRSA from OpenSSL).

```bash
se_apt-get install openvpn openvpn-blacklist
```

Config of OpenVPN on server '/etc/openvpn/home.conf':
```
local 87.118.84.116
port 23455
proto tcp
dev tun
ca /etc/certs/certs/FlorathCA.crt
cert /etc/certs/certs/RS3OpenVPN01.crt
key /etc/certs/private/RS3OpenVPN01.key
dh /etc/certs/dh2048.pem
server 172.32.171.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "route 172.32.171.0 255.255.255.0"
keepalive 10 120
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
verb 3
```

```bash
run_init systemctl enable openvpn@home
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

Here the uid and gid should map to postfix.

Create the files vmailbox and virtual (see <a
href="http://www.postfix.org/VIRTUAL_README.html">postfix
documentation</a>. )

For TLS setup add:

```
smtpd_tls_cert_file=/etc/certs/certs/RS3Mail01CA.pem
smtpd_tls_key_file=/etc/certs/private/RS3Mail01.key
smtpd_use_tls=yes
smtpd_tls_security_level = encrypt
smtpd_tls_session_cache_database =
btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
smtpd_tls_protocols = !SSLv2, !SSLv3
```

For the certificates you can (re)use the CA created for OpenVPN.

Also comment out the lines 'smtps' (including the following -o lines)
in the master.cf file.

#### dovecot
This is the IMAP service for accessing mails.

```bash
se_apt-get install dovecot-core dovecot-imapd dovecot-sieve dovecot-managesieved
```

restorecon -R /var/lib/dovecot

#### fail2ban for Postfix
fail2ban configuration for postfix is setting 'enable'
to true in the postfix section.  Also I add 'maxretry = 1'
and 'bantime  = 604800' - I really hate SPAM.

In the current fail2ban packet there is a problem:
in the file '/etc/fail2ban/filter.d/postfix.conf' the
command pipelining must be changed to:

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

#### Anti-Spam
This is a classical installation of Postfix + Amavis-new + Spamassassin + Clamav. 

See: https://help.ubuntu.com/community/PostfixAmavisNew

Some packages on Debian Jessie have a slightly other name.  To insall things, use:

```bash
se_apt-get install amavisd-new spamassassin clamav-daemon libnet-dns-perl libmail-spf-perl pyzor razor arj bzip2 cabextract cpio file gzip lhasa nomarch pax unrar-free unzip zip zoo lrzip lzop liblz4-tool p7zip p7zip-full rpm2cpio
restorecon -R -v /var/lib/amavis
restorecon -v -R /var/lib/spamassassin
setsebool -P clamav_read_all_non_security_files_clamscan on
```

```bash
audit2allow -M spamfilter-errata
type=AVC msg=audit(1425298292.808:24406): avc:  denied  { execmem } for  pid=14774 comm="clamscan" scontext=system_u:system_r:clamscan_t:s0 tcontext=system_u:system_r:clamscan_t:s0 tclass=process permissive=0
type=AVC msg=audit(1425301453.848:26839): avc:  denied  { search } for  pid=29515 comm="/usr/sbin/spamd" name="razor" dev="dm-0" ino=6031044 scontext=system_u:system_r:spamd_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=dir permissive=0
type=AVC msg=audit(1425301700.532:26867): avc:  denied  { getattr } for  pid=29676 comm="/usr/sbin/spamd" path="/etc/razor/razor-agent.conf" dev="dm-0" ino=6031045 scontext=system_u:system_r:spamd_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425301787.424:26889): avc:  denied  { read } for  pid=29729 comm="/usr/sbin/spamd" name="razor-agent.conf" dev="dm-0" ino=6031045 scontext=system_u:system_r:spamd_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425302079.300:26901): avc:  denied  { search } for  pid=29740 comm="/usr/sbin/amavi" name="razor" dev="dm-0" ino=6031044 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=dir permissive=0
type=AVC msg=audit(1425302178.056:26942): avc:  denied  { open } for  pid=29866 comm="/usr/sbin/spamd" path="/etc/razor/razor-agent.conf" dev="dm-0" ino=6031045 scontext=system_u:system_r:spamd_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425302269.700:26970): avc:  denied  { ioctl } for  pid=29921 comm="/usr/sbin/spamd" path="/etc/razor/razor-agent.conf" dev="dm-0" ino=6031045 scontext=system_u:system_r:spamd_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425302343.248:26991): avc:  denied  { getattr } for  pid=29973 comm="/usr/sbin/spamd" path="/etc/razor" dev="dm-0" ino=6031044 scontext=system_u:system_r:spamd_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=dir permissive=0
type=AVC msg=audit(1425302433.368:27012): avc:  denied  { search } for  pid=30036 comm="/usr/sbin/amavi" name="compiled" dev="dm-0" ino=8259117 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:spamd_compiled_t:s0 tclass=dir permissive=0
type=AVC msg=audit(1425302512.968:27029): avc:  denied  { read } for  pid=30089 comm="pyzor" path="/usr/bin/python2.7" dev="dm-0" ino=12065325 scontext=system_u:system_r:pyzor_t:s0 tcontext=system_u:object_r:bin_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425302608.660:27046): avc:  denied  { getattr } for  pid=30144 comm="/usr/sbin/amavi" path="/var/lib/spamassassin/compiled/Mail/SpamAssassin/CompiledRegexps/body_0.pm" dev="dm-0" ino=8259129 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:spamd_compiled_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425302717.464:27080): avc:  denied  { read } for  pid=30202 comm="/usr/sbin/amavi" name="body_0.pm" dev="dm-0" ino=8259129 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:spamd_compiled_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425302827.080:27118): avc:  denied  { open } for  pid=30263 comm="/usr/sbin/amavi" path="/var/lib/spamassassin/compiled/Mail/SpamAssassin/CompiledRegexps/body_0.pm" dev="dm-0" ino=8259129 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:spamd_compiled_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425302960.912:27146): avc:  denied  { ioctl } for  pid=30324 comm="/usr/sbin/amavi" path="/var/lib/spamassassin/compiled/Mail/SpamAssassin/CompiledRegexps/body_0.pm" dev="dm-0" ino=8259129 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:spamd_compiled_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425303037.168:27174): avc:  denied  { read } for  pid=30376 comm="pyzor" name="python" dev="dm-0" ino=12065336 scontext=system_u:system_r:pyzor_t:s0 tcontext=system_u:object_r:bin_t:s0 tclass=lnk_file permissive=0
type=AVC msg=audit(1425303038.132:27179): avc:  denied  { getattr } for  pid=30375 comm="/usr/sbin/amavi" path="/etc/razor/razor-agent.conf" dev="dm-0" ino=6031045 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425303138.324:27201): avc:  denied  { read } for  pid=30427 comm="/usr/sbin/amavi" name="razor-agent.conf" dev="dm-0" ino=6031045 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425303138.520:27203): avc:  denied  { getattr } for  pid=30428 comm="pyzor" path="/usr/bin/python" dev="dm-0" ino=12065336 scontext=system_u:system_r:pyzor_t:s0 tcontext=system_u:object_r:bin_t:s0 tclass=lnk_file permissive=0
type=AVC msg=audit(1425303215.604:27226): avc:  denied  { open } for  pid=30478 comm="/usr/sbin/amavi" path="/etc/razor/razor-agent.conf" dev="dm-0" ino=6031045 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425303215.812:27228): avc:  denied  { getattr } for  pid=30479 comm="pyzor" path="/usr/share/pyshared/pyzor/__init__.py" dev="dm-0" ino=12849152 scontext=system_u:system_r:pyzor_t:s0 tcontext=system_u:object_r:usr_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425303337.592:27257): avc:  denied  { read } for  pid=30547 comm="pyzor" name="__init__.py" dev="dm-0" ino=12849152 scontext=system_u:system_r:pyzor_t:s0 tcontext=system_u:object_r:usr_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425303338.504:27259): avc:  denied  { ioctl } for  pid=30546 comm="/usr/sbin/amavi" path="/etc/razor/razor-agent.conf" dev="dm-0" ino=6031045 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425303419.276:27278): avc:  denied  { getattr } for  pid=30597 comm="/usr/sbin/amavi" path="/etc/razor" dev="dm-0" ino=6031044 scontext=system_u:system_r:amavis_t:s0 tcontext=system_u:object_r:razor_etc_t:s0 tclass=dir permissive=0
type=AVC msg=audit(1425303419.512:27280): avc:  denied  { open } for  pid=30598 comm="pyzor" path="/usr/share/pyshared/pyzor/client.py" dev="dm-0" ino=12849153 scontext=system_u:system_r:pyzor_t:s0 tcontext=system_u:object_r:usr_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425303579.632:27298): avc:  denied  { create } for  pid=30661 comm="pyzor" name=".pyzor" scontext=system_u:system_r:pyzor_t:s0 tcontext=system_u:object_r:amavis_var_lib_t:s0 tclass=dir permissive=0
type=AVC msg=audit(1425381483.220:41038): avc:  denied  { getattr } for  pid=29034 comm="postdrop" path="/var/spool/postfix/public/pickup" dev="dm-0" ino=8258419 scontext=system_u:system_r:postfix_postdrop_t:s0-s0:c0.c1023 tcontext=system_u:object_r:postfix_public_t:s0 tclass=sock_file permissive=0
type=AVC msg=audit(1425381483.044:41037): avc:  denied  { use } for  pid=29033 comm="sendmail" path="socket:[12302]" dev="sockfs" ino=12302 scontext=system_u:system_r:system_mail_t:s0-s0:c0.c1023 tcontext=system_u:system_r:init_t:s0 tclass=fd permissive=0
type=AVC msg=audit(1425381482.176:41031): avc:  denied  { read } for  pid=29031 comm="pyzor" name="servers" dev="dm-0" ino=8259161 scontext=system_u:system_r:system_cronjob_t:s0-s0:c0.c1023 tcontext=system_u:object_r:amavis_var_lib_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425381482.228:41032): avc:  denied  { ioctl } for  pid=29032 comm="sa-learn" path=2F746D702F746D706639656C653731202864656C6574656429 dev="dm-0" ino=9699390 scontext=system_u:system_r:system_cronjob_t:s0-s0:c0.c1023 tcontext=system_u:object_r:crond_tmp_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425381483.008:41033): avc:  denied  { read } for  pid=29032 comm="sa-learn" name="body_0.pm" dev="dm-0" ino=8259129 scontext=system_u:system_r:system_cronjob_t:s0-s0:c0.c1023 tcontext=system_u:object_r:spamd_compiled_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425381483.032:41034): avc:  denied  { read } for  pid=29032 comm="sa-learn" name="bayes_toks" dev="dm-0" ino=8259157 scontext=system_u:system_r:system_cronjob_t:s0-s0:c0.c1023 tcontext=system_u:object_r:amavis_var_lib_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425381483.032:41035): avc:  denied  { node_bind } for  pid=29032 comm="sa-learn" scontext=system_u:system_r:system_cronjob_t:s0-s0:c0.c1023 tcontext=system_u:object_r:node_t:s0 tclass=udp_socket permissive=0
type=AVC msg=audit(1425381482.140:41020): avc:  denied  { append } for  pid=29029 comm="perl" name="razor-agent.log" dev="dm-0" ino=8259144 scontext=system_u:system_r:system_cronjob_t:s0-s0:c0.c1023 tcontext=system_u:object_r:amavis_var_lib_t:s0 tclass=file permissive=0
[CTRL-D]
```

#### Check /var/log/clamav/freshclam.log
??? setsebool -P clamd_use_jit on


#### Ban IPs that deliver spam

### Apache

```bash
se_apt-get install apache2
```

### Graphite

```bash
se_apt-get install graphite-web graphite-carbon python-memcache libapache2-mod-wsgi python-psycopg2
```

Use:
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-graphite-on-an-ubuntu-14-04-server

```bash
audit2allow -M graphite-errata
type=AVC msg=audit(1425310574.588:33385): avc:  denied  { search } for  pid=4715 comm="apache2" name="vm" dev="proc" ino=12969 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:sysctl_vm_t:s0 tclass=dir permissive=0
type=AVC msg=audit(1425310574.716:33386): avc:  denied  { execute } for  pid=4715 comm="apache2" path=2F746D702F6666696A5978366E65202864656C6574656429 dev="dm-0" ino=9699337 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:httpd_tmp_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425310677.792:33404): avc:  denied  { execute } for  pid=4978 comm="ldconfig" name="ldconfig.real" dev="dm-0" ino=18350182 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:ldconfig_exec_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425310677.936:33410): avc:  denied  { name_connect } for  pid=4915 comm="apache2" dest=5432 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:postgresql_port_t:s0 tclass=tcp_socket permissive=0
type=AVC msg=audit(1425310703.328:33415): avc:  denied  { read } for  pid=5017 comm="apache2" name="overcommit_memory" dev="proc" ino=12970 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:sysctl_vm_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425310910.664:33440): avc:  denied  { read open } for  pid=5286 comm="ldconfig" path="/sbin/ldconfig.real" dev="dm-0" ino=18350182 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:ldconfig_exec_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425310911.188:33442): avc:  denied  { getattr } for  pid=5214 comm="apache2" path="/var/lib/graphite/search_index" dev="dm-0" ino=9699385 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:system_cronjob_tmp_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425310911.188:33443): avc:  denied  { write } for  pid=5214 comm="apache2" name="search_index" dev="dm-0" ino=9699385 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:system_cronjob_tmp_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425311179.796:33482): avc:  denied  { open } for  pid=5590 comm="apache2" path="/proc/sys/vm/overcommit_memory" dev="proc" ino=12970 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:sysctl_vm_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425311179.916:33483): avc:  denied  { execute_no_trans } for  pid=5693 comm="ldconfig" path="/sbin/ldconfig.real" dev="dm-0" ino=18350182 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:ldconfig_exec_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425311179.980:33484): avc:  denied  { read } for  pid=5590 comm="apache2" name="search_index" dev="dm-0" ino=9699385 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:system_cronjob_tmp_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425311258.816:33491): avc:  denied  { open } for  pid=5768 comm="apache2" path="/var/lib/graphite/search_index" dev="dm-0" ino=9699385 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:system_cronjob_tmp_t:s0 tclass=file permissive=0
[CTRL-D]
setsebool -P httpd_can_network_connect on
```

#### Collectd

Not get all all X dependencies, that are not needed, use:

```bash
se_apt-get install --no-install-recommends collectd liboping0
setsebool -P collectd_tcp_network_connect on
```

```bash
audit2allow -M collectd-errata
type=AVC msg=audit(1425322360.160:35562): avc:  denied  { read } for  pid=13129 comm="collectd" name="utmp" dev="tmpfs" ino=10571 scontext=system_u:system_r:collectd_t:s0 tcontext=system_u:object_r:initrc_var_run_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425322417.008:35570): avc:  denied  { open } for  pid=13316 comm="collectd" path="/run/utmp" dev="tmpfs" ino=10571 scontext=system_u:system_r:collectd_t:s0 tcontext=system_u:object_r:initrc_var_run_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425322493.008:35582): avc:  denied  { lock } for  pid=13366 comm="collectd" path="/run/utmp" dev="tmpfs" ino=10571 scontext=system_u:system_r:collectd_t:s0 tcontext=system_u:object_r:initrc_var_run_t:s0 tclass=file permissive=0
type=AVC msg=audit(1425363226.312:38515): avc:  denied  { net_admin } for  pid=5449 comm="collectd" capability=12  scontext=system_u:system_r:collectd_t:s0 tcontext=system_u:system_r:collectd_t:s0 tclass=capability permissive=0
type=AVC msg=audit(1425559539.160:51634): avc:  denied  { create } for  pid=28249 comm="collectd" scontext=system_u:system_r:collectd_t:s0 tcontext=system_u:system_r:collectd_t:s0 tclass=rawip_socket permissive=0
type=AVC msg=audit(1425559699.980:51649): avc:  denied  { net_raw } for  pid=28457 comm="collectd" capability=13  scontext=system_u:system_r:collectd_t:s0 tcontext=system_u:system_r:collectd_t:s0 tclass=capability permissive=0
type=AVC msg=audit(1425559902.216:51668): avc:  denied  { setopt } for  pid=28630 comm="collectd" lport=58 scontext=system_u:system_r:collectd_t:s0 tcontext=system_u:system_r:collectd_t:s0 tclass=rawip_socket permissive=0
type=AVC msg=audit(1425559997.228:51721): avc:  denied  { write } for  pid=28707 comm="collectd" lport=58 scontext=system_u:system_r:collectd_t:s0 tcontext=system_u:system_r:collectd_t:s0 tclass=rawip_socket permissive=0
type=AVC msg=audit(1425562059.680:595567): avc:  denied  { read } for  pid=28707 comm="collectd" lport=58 scontext=system_u:system_r:collectd_t:s0 tcontext=system_u:system_r:collectd_t:s0 tclass=rawip_socket permissive=0
[CTRL-D]
```

### NTP
Because there any many discussions on the internet whether to
use NTPd in the VM or not: before activating an ntpd in the VM, I'll
check for some time if this is needed.  A ntpd is installed in the VM
- but configured in the way that it does not set the clock.  collectd
will pick up the timedifference and sends it to graphite.

```bash
se_apt-get install ntp
```

In the ntp.conf file use the 'noselect' option to the server(s):
this enables collectd to get the time statistics without really
setting the time.

```
server ntp.keyweb.de iburst noselect
```

#### AIDE

