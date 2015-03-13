Kerrighed-Manage-NFS is a tool to install easily Kerrighed on a Debian, Mint or Ubuntu distribution.

This script will install this package on your machine : 
	debootstrap grub-pc openssh-client dhcp3-server
	nfs-kernel-server tftpd-hpa syslinux qemu-system
	qemu-kvm-extras qemu-user qemu kvm-pxe
	
Globally, the script need :
	- debootstrap : to booststrap a debian distribution 
	- openssh-client : to connect to the kerrighed nodes
	- dhcp3-server : to create a DHCP server to boot the nodes
	- tftpd-hpa : to create a TFTP server to share files with the nodes (boot)
	- nfs-kernel-server : to share the file system between the nodes
	- qemu : to test Kerrighed with a virtual machine


Be careful !!!, this script OVERWRITE the configuration files for the DCHP server,
TFTP server, mounting table !!!
The list of files modified is :
	- /etc/dhcp/dhcpd.conf
	- /etc/dhcp3/dhcpd.conf (if exists)
	- /etc/default/tftpd-hpa
	- /etc/exports
 
 
 
------------------------------------------------------------------------
 
 

If you want to install krgmon (https://sourcesup.cru.fr/projects/krgmon/).
The script will install : 
	snmp snmpd libnet-snmp-perl ruby rubygems mysql-server
		
- SNMP server : to get information about migrations from nodes.
- ruby : to	launch the Web Application
- mysql-server : To save the data of migrations 
- libnet-snmp-perl : To run the script getting information from SNMP


The configuration files will be OVERWRITED :
	- /etc/snmp/snmptrapd.conf


You can see an example of results at this address :
	http://www.youtube.com/watch?v=YRO_EcTfUAQ



------------------------------------------------------------------------



The list of commands will be available with the script after have defined
	the configuration file (file ".script-kerrighed-config")
	
	
