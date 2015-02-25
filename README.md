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
href="www.telekom.com">Deutsche Telekom</a> published their
requirements and created <a href="https://github.com/TelekomLabs">a
project on github</a> that includes the rules for automatically
applying these rules with chef or puppet. 

Because IMHO <a href="www.puppetlabs.com">puppet</a> is easier to
handle, this was chosen for applying the rules. 

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

