# Dns Project


- [Introduction](#introduction)
- [Bind9 Domain Name Server ](#bind9-domainnameerver)
  - [Bind Installation](#installation-bind9)
  - [Bind custom commands](#bind-custom-commands)
  - [Bind How to use schematics](#bind-how-to-use-schematics)
- [DNSControl](#dnsontroler)


## Bind9 - Domain Name Server
 <p> Configuration contain 3 options: </p>


- Configuration of Bind9 as Authoritative server.
- Configration of Bind9 as Split-View server for enterprise, homelabs, specific usage for private and public domains managers.
- Configuration of Bind9 as recursive server with extender to block bad websites using RPZ.

<p> In future I will enable SSL options on all of them, since bind9 nativly does not support the DNS over TLS or DNS over http, we need to use proxy for incoming traffic.</p>


## Installtion Bind9

<p> I am using only rhel base Linux system to work with Bind9, because of the SELinux show in the below.

<p> Update system, setup hostname </p>

```
sudo dnf update -y
sudo hostnamectl set-hostname [your-dns-hostname]

sudo reboot 
```

<p> Check SELinux mode: Should return enforcing</p>

```
sudo sestatus | grep "Current mode:" 
#:> Current mode: enforcing 
```

<p> If disabled Please install selinux </p>

```
sudo dnf install -y selinux-policy selinux-policy-targeted selinux-policy-devel \
policycoreutils policycoreutils-python-utils \
libselinux libselinux-utils \
setools setroubleshoot checkpolicy mcstrans

```

<p> Create dns user who will have access only do bind9 (named) process </p>

```
sudo groupadd bind9admin
sudo add user bind9admin -g bind9admin
sudo usermod -aG bind9admin bind9admin
sudo usermod -aG bind9admin named
```
<details>
    <summary>Optional for custom directory for bind9 configuration --- more secure</summary>
<p>Add files structure and mount to named-chroot (optional) </p>

```
#create directory
mkdir /opt/bind9
chown bind9:bind9 /opt/bind9/
chown bind9admin:bind9admin /opt/bind9/
#as security user 
sudo mkdir -p /var/named/chroot/opt/bind9
/usr/sbin/semanage fcontext -a -t named_conf_t /opt/bind9/*

#for testing only
mount --bind /opt/bind9 /var/named/chroot/opt/bind9
```

<p> Add mount systemd and crate systemd service. </p>

```
sudo vi /etc/systemd/system/var-named-chroot-opt-bind9.mount

# Copy content below to the file 

[Unit]
Description=Bind mount for BIND9 zones
After=local-fs.target
Before=named.service

[Mount]
What=/opt/bind9
Where=/var/named/chroot/opt/bind9
Type=none
Options=bind

[Install]
WantedBy=multi-user.target
```

```
sudo systemctl enable --now var-named-chroot-opt-bind9.mount

vi /etc/systemd/system/named-chroot.service.d/override.conf
```

```
#Add those lines
[Unit]
Requires=var-named-chroot-opt-bind9.mount
After=var-named-chroot-opt-bind9.mount
```

<p> Adapt security access level Linux permissions rights - Run as root </p>

```
sudo bash -c 'cat > /etc/sudoers.d/bind9admin' << 'EOF'
%bind9admin ALL=(ALL) NOPASSWD:  /etc/bind/, sudoedit  /etc/bind/named.conf, sudoedit /etc/bind/zones/, sudoedit /var/lib/bind/, sudoedit  /var/cache/bind/, sudoedit /etc/bind/.zone

bind9admin ALL=(ALL) NOPASSWD: sudoedit /etc/named.conf
bind9admin ALL=(ALL) NOPASSWD: /sbin/named-checkconf
bind9admin ALL=(ALL) NOPASSWD: /usr/bin/cat /etc/named.conf

bind9admin ALL=(ALL) NOPASSWD: /usr/bin/firewall-cmd --permanent --add-service=dns
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl enable --now named-chroot
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl enable named-chroot
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl restart named-chroot
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl stop named-chroot
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl start named-chroot
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl status named-chroot

bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl enable --now var-named-chroot-opt-bind9.mount
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl enable var-named-chroot-opt-bind9.mount
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl restart var-named-chroot-opt-bind9.mount
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl stop var-named-chroot-opt-bind9.mount
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl start var-named-chroot-opt-bind9.mount
bind9admin ALL=(ALL) NOPASSWD: /bin/systemctl status var-named-chroot-opt-bind9.mount

bind9admin ALL=(ALL) NOPASSWD: /usr/local/bin/update-zones

Defaults    env_keep += "BIND_ZONES_PATH"

EOF


# apply correct rights - there is no need to do it 
sudo chmod 0440 /etc/sudoers.d/bind9admin
# verify and check file
sudo visudo -cf /etc/sudoers.d/bind9admin
```

</details>

<p> Install bind9 with chroot mode.</p>

```
sudo dnf install bind-chroot

#add this config to /etc/named.conf (optional depends on of the config)
sudoedit /etc/named.conf

include "/opt/bind9/includes.conf";
```

<p> Enable and start named in chroot mode </p>

```
sudo systemctl enable named-chroot
sudo systemctl start named-chroot
```


## Bind Custom Commands

<p> This commands you can use to on specific files if there is any problems. </p>

```
# Checks the syntax of a BIND configuration file
# Usage: named-checkconf configuration-file.conf
named-checkconf /etc/named.conf

# Verifies the correctness of a DNS zone
# Usage: named-checkzone zone_name zone_file
named-checkzone example.com /var/named/example.com.zone

# Compiles a DNS zone from text format to binary format for faster processing by BIND
# Usage: named-compilezone -f text -F raw -o output_file zone_name input_file
named-compilezone -f text -F raw -o /var/named/example.com.db example.com /var/named/example.com.zone

# Prints the content of a dynamic zone journal file in a readable format
# Usage: named-journalprint journal_file
named-journalprint /var/named/example.com.jnl

# Converts a zone journal file (.nzd) to a zone file format (.nzf)
# Usage: named-nzd2nzf input.nzd output.nzf
named-nzd2nzf /var/named/example.com.nzd /var/named/example.com.nzf

# Checks the correctness of resource records (RR) in a DNS zone
# Usage: named-rrchecker zone_file
named-rrchecker /var/named/example.com.zone
```




## Bind How to use schematics
<p> If you clone or copy paste files make sure that: </p>

<p> File named.conf includes or have configuration before starting named-chroot, aslo verify configurations. </p>
<p> Zones should be verify what schematics you are using: </p>

- Bind Authorative configuration - requires right permsision for master and slave server, please follow installation -- more secure option
- Bind Split View configuration - require right permsision for master and slave server, please follow installation -- more secure option
- Bind Recursie configuration - require right permsision for master and slave server, please follow installation without --more secure option


<p> Every file needs to be copy where your /var/named server contains configurations. </p>
<p> Standard zones location for master/primary dns server is /etc/bind/zones but anything else will work. Please check my option --more secure installation.
<p> 



&nbsp;  &nbsp;  
&nbsp;  &nbsp;  

&nbsp;  &nbsp;  
&nbsp;  &nbsp;  


&nbsp;  &nbsp;  
&nbsp;  &nbsp;  


# DNSControler 
<p> Tool which helps build zones for specific dns, provider. </p>

<p> In director dnscontrol is setup fully configuration which can be pulled, dnscontrol should be installed and base on the configuration you can build your config.</p>
<p> Step to do: </p>

1. Pull repository : git clone https://github.com/Splunner/dns.git
2. Install dnscontrol https://github.com/StackExchange/dnscontrol/releases using binary option download and deply on your machine,  I am using v4.26 (oct 2025).
3. Go to directory repo-dnscontrol and run this command : dnscontrol preview
```
[bind9admin@ns1 dnscontrol]$ dnscontrol preview
INFO: In dnsconfig.js NewRegistrar("none", "NONE") can be simplified to NewRegistrar("none") (See https://docs.dnscontrol.org/commands/creds-json#cleanup)
INFO: In dnsconfig.js NewDnsProvider("bind", "BIND") can be simplified to NewDnsProvider("bind") (See https://docs.dnscontrol.org/commands/creds-json#cleanup)
******************** Domain: corpo.com
1 correction (bind)
#1: Ensuring zone "corpo.com" exists in "bind"
CONCURRENTLY gathering 1 zone(s)
SERIALLY gathering 0 zone(s)
Waiting for concurrent gathering(s) to complete...File does not yet exist: "output/zones/corpo.com.zone" (will create)
DONE
******************** Domain: corpo.com
10 corrections (bind)
#1: + CREATE corpo.com SOA ns1.corpo.com. spamtrap.corpo.com. 3600 600 604800 1440 ttl=300
+ CREATE corpo.com A 192.0.2.30 ttl=300
+ CREATE admin.corpo.com A 172.10.0.150 ttl=300
+ CREATE automate.corpo.com A 172.10.0.11 ttl=300
+ CREATE ns1.corpo.com A 172.10.60.10 ttl=300
+ CREATE ns2.corpo.com A 172.10.60.20 ttl=300
+ CREATE wwwserver.corpo.com A 172.10.51.20 ttl=300
+ CREATE corpo.com NS ns1.corpo.com. ttl=300
+ CREATE corpo.com NS ns2.corpo.com. ttl=300
+ CREATE www.corpo.com CNAME corpo.com. ttl=300
Done. 11 corrections.
```
4. Run this command : dns push
```
[bind9admin@ns1 dnscontrol]$ dnscontrol push
INFO: In dnsconfig.js NewRegistrar("none", "NONE") can be simplified to NewRegistrar("none") (See https://docs.dnscontrol.org/commands/creds-json#cleanup)
INFO: In dnsconfig.js NewDnsProvider("bind", "BIND") can be simplified to NewDnsProvider("bind") (See https://docs.dnscontrol.org/commands/creds-json#cleanup)
******************** Domain: corpo.com
1 correction (bind)
#1: Ensuring zone "corpo.com" exists in "bind"
SUCCESS!
CONCURRENTLY gathering 1 zone(s)
SERIALLY gathering 0 zone(s)
Waiting for concurrent gathering(s) to complete...File does not yet exist: "output/zones/corpo.com.zone" (will create)
DONE
******************** Domain: corpo.com
10 corrections (bind)
#1: + CREATE corpo.com SOA ns1.corpo.com. spamtrap.corpo.com. 3600 600 604800 1440 ttl=300
+ CREATE corpo.com A 192.0.2.30 ttl=300
+ CREATE admin.corpo.com A 172.10.0.150 ttl=300
+ CREATE automate.corpo.com A 172.10.0.11 ttl=300
+ CREATE ns1.corpo.com A 172.10.60.10 ttl=300
+ CREATE ns2.corpo.com A 172.10.60.20 ttl=300
+ CREATE wwwserver.corpo.com A 172.10.51.20 ttl=300
+ CREATE corpo.com NS ns1.corpo.com. ttl=300
+ CREATE corpo.com NS ns2.corpo.com. ttl=300
+ CREATE www.corpo.com CNAME corpo.com. ttl=300
WRITING ZONEFILE: output/zones/corpo.com.zone
SUCCESS!
Done. 11 corrections.
```