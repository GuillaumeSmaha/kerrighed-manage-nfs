#!/bin/bash


# Constant Default
FILE_CONFIG="./.script-kerrighed-config"
QEMU_DEVICE_NAME="tap0"
QEMU_BRIDGE_NAME="br0"
SCRIPT_QEMU_UP=".qemu-ifup"

DIR_NFSROOT_DEFAULT="kerrighed"
DIR_TFTPROOT_DEFAULT="tftpboot"
IP_BASE_DEFAULT="192.168.10"
IP_SERVER_DEFAULT="${IP_BASE_DEFAULT}.2"
DEVICE_ETH0_DEFAULT="eth0"
DEBIAN_URL="http://debian.med.univ-tours.fr/debian/"
DEBIAN_URL="ftp://ftp.debian.org/debian/"
DEBIAN_DIST="wheezy"
LANGUAGE="en_US.UTF-8"

ECHO=echo
QEMU=qemu-system-x86_64
QEMU_DISPLAY_VNC=:1
QEMU_CONFIG="-boot n -m 1024 -net nic,vlan=0 -net tap,vlan=0,script=$(readlink -f ${SCRIPT_QEMU_UP}),downscript=no,ifname=${QEMU_DEVICE_NAME} -smp 2 -localtime -daemonize -k fr -vnc ${QEMU_DISPLAY_VNC}"
RUBY_CONFIG="-d -P /krgmon"
COMMAND="$0"

COMMAND_PARAM_OPTION="$2"

# --- Check Part ---- 

# Check if root or not
check_if_root() {
	if [ ! "$UID" = "0" ]; then
		$ECHO
		$ECHO "[$LOGNAME] You need to run this script \"`basename $0`\" as root."
		$ECHO
		exit 1
	fi
}


# Check if configured or not
check_if_configured() {
	if [ ! -e "$(get_absolute_path ${FILE_CONFIG})" ]; then
		$ECHO
		$ECHO "You need to configure this script before."
		$ECHO "	   $(get_absolute_path $0) config [dir_nfsroot_image] [dir_tftproot_kerrighed] [ip_base] [ip_server] [device]"
		$ECHO "	   Example : $(get_absolute_path $0) config ${DIR_NFSROOT_DEFAULT} ${DIR_TFTPROOT_DEFAULT} ${IP_BASE_DEFAULT} ${IP_SERVER_DEFAULT} ${DEVICE_ETH0_DEFAULT}"
		$ECHO
		exit 1
	fi
}


# Check if arch is x86_64 or not
check_if_x86_64() {
	archKernel=$(uname -m)
	if [ "${archKernel}" != "x86_64" ]; then
		$ECHO
		$ECHO "You need to have a x86_64 kernel architecture."
		$ECHO "	   Install a amd64 kernel version"
		$ECHO
		exit 1
	fi
}


check_if_nfsroot_created() {
	fileTest="${DIR_NFSROOT}/root/"
	if [ ! -d "${fileTest}" ]; then
		$ECHO
		$ECHO "You need to create the nfs root."
		$ECHO "	   $(get_absolute_path $0) create_nfsroot"
		$ECHO
		exit 1
	fi
}







# --- Getter Part ---- 



get_nb_cpu() {
	echo $(cat /proc/cpuinfo | grep "^processor" | wc -l)
}

# Get the absolute command path
get_file() {
	if [ ! -z "${1}" ]; then
		fileName=$(echo "${1}" | grep -E -o "([a-zA-Z0-9 *+._-]+)$")
		echo ${fileName//\//}
	fi
}

# Get the absolute command path
get_absolute_path() {
	if [ ! -z "${1}" ]; then
		echo $(readlink -f ${1})
	fi
}

# Get the absolute path contening the script
get_absolute_dir() {
	if [ ! -z "${1}" ]; then
		cmdFull=$(get_absolute_path ${1})
		echo "${cmdFull}" | grep -E -o "^([a-zA-Z0-9 /*+._-]+)(/)"
	fi
}

# Check if qemu is launched
is_launched() {
	nb_pid=$(ps -eo pid,command | grep "${QEMU}" | grep -v "grep" | grep -E -o "^([ ]*)([0-9]+)" | wc -l)
	if [ $nb_pid -eq 0 ]; then
		echo ""
		return
	fi
	echo 1
}

# Get pid of the process qemu
get_pid_launched() {
	checkLaunched=$(is_launched)
	if [ -z "${checkLaunched}" ]; then
		echo ""
		return
	fi
	pid=$(ps -eo pid,command | grep "${QEMU}" | grep -v "grep" | grep -E -o "^([ ]*)([0-9]+)")
	echo $pid
}

# Get pid of the process krgmon
get_pid_krgmon_launched() {
	pid=$(ps -eo pid,command | grep "ruby ${DIR_NFSROOT}/root/krgmon/trunk/RailsApp/script/server ${RUBY_CONFIG}" | grep -v "grep" | grep -E -o "^([ ]*)([0-9]+)")
	echo $pid
}






# --- Service Part ---- 



service_dhcp_restart() {
	/etc/init.d/isc-dhcp-server restart
}
service_dhcp_start() {
	/etc/init.d/isc-dhcp-server start
}
service_dhcp_stop() {
	/etc/init.d/isc-dhcp-server stop
}

service_nfs_restart() {
	/etc/init.d/nfs-kernel-server restart
}
service_nfs_start() {
	/etc/init.d/nfs-kernel-server start
}
service_nfs_stop() {
	/etc/init.d/nfs-kernel-server stop
}

service_tftp_restart() {
  restart tftpd-hpa
}
service_tftp_start() {
  start tftpd-hpa
}
service_tftp_stop() {
	stop tftpd-hpa
}

service_snmp_restart() {
	/etc/init.d/snmpd restart
}
service_snmp_start() {
	/etc/init.d/snmpd start
}
service_snmp_stop() {
	/etc/init.d/snmpd start
}


#Restart all service
service_all_restart() {
	check_if_configured
	check_if_x86_64
	check_if_nfsroot_created

	
	$ECHO
	$ECHO "Restart the daemon (DHCP, NFS, TFTP)..."
	service_dhcp_restart
	$ECHO
	service_nfs_restart
	$ECHO
	service_tftp_restart
}

#Start all service
service_all_start() {
	check_if_configured
	check_if_x86_64
	check_if_nfsroot_created

	
	$ECHO
	$ECHO "Start the daemon (DHCP, NFS, TFTP)..."
	service_dhcp_start
	$ECHO
	service_nfs_start
	$ECHO
	service_tftp_start
}

#Stop all service
service_all_stop() {
	check_if_configured
	check_if_x86_64
	check_if_nfsroot_created

	
	$ECHO
	$ECHO "Stop the daemon (DHCP, NFS, TFTP)..."
	service_dhcp_stop
	$ECHO
	service_nfs_stop
	$ECHO
	service_tftp_stop
}





# --- Exec Part ---- 


# Init the file, dir
exec_install_deps() {	
	aptitude -y install debootstrap grub-pc openssh-client dhcp3-server nfs-kernel-server tftpd-hpa syslinux qemu-system qemu-kvm qemu-kvm-extras qemu-user qemu kvm-pxe uml-utilities vncviewer
	$ECHO "The package is installed !"
}


#Create the nfsroot
exec_create_nfsroot() {
	check_if_configured
	check_if_x86_64
	
	
	#rm -fr "${DIR_NFSROOT}"
	#rm -fr "${DIR_TFTPROOT}"
	
	sleep 1

    if [ -d "${DIR_NFSROOT}" ] && [ -d "${DIR_TFTPROOT}" ]; then
        return;
    fi
	
	echo mkdir -p "${DIR_NFSROOT}"
	echo mkdir -p "${DIR_TFTPROOT}"
	mkdir -p "${DIR_NFSROOT}"
	mkdir -p "${DIR_TFTPROOT}"
		
	sleep 1	

  $ECHO "Check for debian repository : ${DEBIAN_URL}"
  FILE_UPDATE=$(echo $DEBIAN_URL | cut -d'/' -f 3)
  wget ${DEBIAN_URL}"Archive-Update-in-Progress-${FILE_UPDATE}" -O /tmp/checkupdatedebian 2> /tmp/checkupdatedebian.log
  testError=$(grep -iE "(ERROR 404|Not Found)|(No such file)" /tmp/checkupdatedebian.log)

  rm -f /tmp/checkupdatedebian
  rm -f /tmp/checkupdatedebian.log

  if [ "$testError" == "" ]; then
    $ECHO "Error : the repository is running an update !"
    $ECHO "Exit"
    exit
  else
    $ECHO "Repository is OK"
  fi
	
	$ECHO "Get an environnement 64 bit :"
	debootstrap --arch amd64 ${DEBIAN_DIST} "${DIR_NFSROOT}" ${DEBIAN_URL}
	$ECHO "Getting finish !"
	$ECHO
}

#Configure the servers (tftp, dhcp and nfs)
exec_configure_servers() {
	check_if_configured
	check_if_x86_64
	check_if_nfsroot_created
	
		
	$ECHO
	$ECHO "Configure the NFS ROOT..."
	echo "# /etc/default/tftpd-hpa

TFTP_USERNAME=\"tftp\"
TFTP_DIRECTORY=\"${DIR_TFTPROOT}\"
TFTP_ADDRESS=\"0.0.0.0:69\"
TFTP_OPTIONS=\"--secure\"

RUN_DAEMON=\"yes\"
OPTIONS=\"-l -s ${DIR_TFTPROOT}\"" > /etc/default/tftpd-hpa

	mkdir -p "${DIR_TFTPROOT}/pxelinux.cfg"
	
	sleep 1
	
	$ECHO
	$ECHO "Configure the DHCP Server..."
	echo "
option grub-menu code 150 = string;

option dhcp-max-message-size 2048;
use-host-decl-names on;

option domain-name \"ker.local\";
option domain-name-servers ${IP_BASE}.10; 
option routers ${IP_SERVER};
option interface-mtu 6144;

subnet ${IP_BASE}.0 netmask 255.255.255.0
{
	option broadcast-address ${IP_BASE}.255;
	authoritative;
	range ${IP_BASE}.11 ${IP_BASE}.253;
	next-server ${IP_SERVER};

	filename \"pxelinux.0\";
	option root-path \"${DIR_NFSROOT}\";
	send host-name = concat(\"krgnode\", binary-to-ascii(10, 8, \".\", substring(leased-address, 3, 1)));
}

" > /etc/dhcp/dhcpd.conf

	if [ -d "/etc/dhcp3/" ]; then
		cp /etc/dhcp/dhcpd.conf /etc/dhcp3/
	fi
	
	sleep 1

	$ECHO
	$ECHO "Configure the mounting table..."
	echo "# /etc/exports: the access control list for filesystems which may be exported
#		to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
# /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
#
# Example for NFSv4:
# /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
# /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
#
${DIR_NFSROOT}/ *(rw,fsid=0,async,no_root_squash,no_subtree_check)
${DIR_NFSROOT}/etc *(rw,async,no_root_squash,no_subtree_check)
${DIR_NFSROOT}/home *(rw,async,no_root_squash,no_subtree_check)
${DIR_NFSROOT}/root *(rw,async,no_root_squash,no_subtree_check)
${DIR_NFSROOT}/tmp *(rw,async,no_root_squash,no_subtree_check)
${DIR_NFSROOT}/var *(rw,async,no_root_squash,no_subtree_check)
#${DIR_NFSROOT}/dev *(rw,async,no_root_squash,no_subtree_check)
" > /etc/exports
	
	
	sleep 1
	
	$ECHO
	$ECHO "Copy the boot loader..."
	cp /usr/lib/syslinux/pxelinux.0 "${DIR_TFTPROOT}"


  if [ "$1" == "1" ]; then
    exec_init_nfsroot_before
    exec_init_nfsroot_after
  else
    service_all_restart
  fi
}

#Init the nfsroot_before
exec_init_nfsroot_before() {
	check_if_configured
	check_if_x86_64
	check_if_nfsroot_created
	
	$ECHO
	$ECHO
	$ECHO "A file init_server_before.sh is created in ${DIR_NFSROOT}/root/."
	
 	echo "#!/bin/bash
	
echo
echo \"Define the hostname...\"
echo \"127.0.0.1	localhost
${IP_SERVER}	srv-krg-nfs

# The following lines are desirable for IPv6 capable hosts
127.0.0.1	localhost
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
${IP_BASE}.10 krgnode10
${IP_BASE}.11 krgnode11
${IP_BASE}.12 krgnode12
${IP_BASE}.13 krgnode13
${IP_BASE}.14 krgnode14
${IP_BASE}.15 krgnode15
${IP_BASE}.16 krgnode16
${IP_BASE}.17 krgnode17
${IP_BASE}.18 krgnode18
${IP_BASE}.18 krgnode19
${IP_BASE}.20 krgnode20
${IP_BASE}.21 krgnode21
${IP_BASE}.22 krgnode22
${IP_BASE}.23 krgnode23
${IP_BASE}.24 krgnode24
${IP_BASE}.25 krgnode25
${IP_BASE}.26 krgnode26
${IP_BASE}.27 krgnode27
${IP_BASE}.28 krgnode28
${IP_BASE}.29 krgnode29
${IP_BASE}.30 krgnode30
${IP_BASE}.31 krgnode31
${IP_BASE}.32 krgnode32
${IP_BASE}.33 krgnode33
${IP_BASE}.34 krgnode34
${IP_BASE}.35 krgnode35
${IP_BASE}.36 krgnode36
${IP_BASE}.37 krgnode37
${IP_BASE}.38 krgnode38
${IP_BASE}.39 krgnode39
${IP_BASE}.40 krgnode40
${IP_BASE}.41 krgnode41
${IP_BASE}.42 krgnode42
${IP_BASE}.43 krgnode43
${IP_BASE}.44 krgnode44
${IP_BASE}.45 krgnode45
${IP_BASE}.46 krgnode46
${IP_BASE}.47 krgnode47
${IP_BASE}.48 krgnode48
${IP_BASE}.49 krgnode49
${IP_BASE}.50 krgnode50
${IP_BASE}.51 krgnode51
${IP_BASE}.52 krgnode52
${IP_BASE}.53 krgnode53
${IP_BASE}.54 krgnode54
${IP_BASE}.55 krgnode55
${IP_BASE}.56 krgnode56
${IP_BASE}.57 krgnode57
${IP_BASE}.58 krgnode58
${IP_BASE}.59 krgnode59
${IP_BASE}.60 krgnode60
${IP_BASE}.61 krgnode61
${IP_BASE}.62 krgnode62
${IP_BASE}.63 krgnode63
${IP_BASE}.64 krgnode64
${IP_BASE}.65 krgnode65
${IP_BASE}.66 krgnode66
${IP_BASE}.67 krgnode67
${IP_BASE}.68 krgnode68
${IP_BASE}.69 krgnode69
${IP_BASE}.70 krgnode70
${IP_BASE}.71 krgnode71
${IP_BASE}.72 krgnode72
${IP_BASE}.73 krgnode73
${IP_BASE}.74 krgnode74
${IP_BASE}.75 krgnode75
${IP_BASE}.76 krgnode76
${IP_BASE}.77 krgnode77
${IP_BASE}.78 krgnode78
${IP_BASE}.79 krgnode79
${IP_BASE}.80 krgnode80
${IP_BASE}.81 krgnode81
${IP_BASE}.82 krgnode82
${IP_BASE}.83 krgnode83
${IP_BASE}.84 krgnode84
${IP_BASE}.85 krgnode85
${IP_BASE}.86 krgnode86
${IP_BASE}.87 krgnode87
${IP_BASE}.88 krgnode88
${IP_BASE}.89 krgnode89
${IP_BASE}.90 krgnode90
${IP_BASE}.91 krgnode91
${IP_BASE}.92 krgnode92
${IP_BASE}.93 krgnode93
${IP_BASE}.94 krgnode94
${IP_BASE}.95 krgnode95
${IP_BASE}.96 krgnode96
${IP_BASE}.97 krgnode97
${IP_BASE}.98 krgnode98
${IP_BASE}.99 krgnode99
${IP_BASE}.100 krgnode100
${IP_BASE}.101 krgnode101
${IP_BASE}.102 krgnode102
${IP_BASE}.103 krgnode103
${IP_BASE}.104 krgnode104
${IP_BASE}.105 krgnode105
${IP_BASE}.106 krgnode106
${IP_BASE}.107 krgnode107
${IP_BASE}.108 krgnode108
${IP_BASE}.109 krgnode109
${IP_BASE}.110 krgnode110
${IP_BASE}.111 krgnode111
${IP_BASE}.112 krgnode112
${IP_BASE}.113 krgnode113
${IP_BASE}.114 krgnode114
${IP_BASE}.115 krgnode115
${IP_BASE}.116 krgnode116
${IP_BASE}.117 krgnode117
${IP_BASE}.118 krgnode118
${IP_BASE}.119 krgnode119
${IP_BASE}.120 krgnode120
${IP_BASE}.121 krgnode121
${IP_BASE}.122 krgnode122
${IP_BASE}.123 krgnode123
${IP_BASE}.124 krgnode124
${IP_BASE}.125 krgnode125
${IP_BASE}.126 krgnode126
${IP_BASE}.127 krgnode127
${IP_BASE}.128 krgnode128
${IP_BASE}.129 krgnode129
${IP_BASE}.130 krgnode130
${IP_BASE}.131 krgnode131
${IP_BASE}.132 krgnode132
${IP_BASE}.133 krgnode133
${IP_BASE}.134 krgnode134
${IP_BASE}.135 krgnode135
${IP_BASE}.136 krgnode136
${IP_BASE}.137 krgnode137
${IP_BASE}.138 krgnode138
${IP_BASE}.139 krgnode139
${IP_BASE}.140 krgnode140
${IP_BASE}.141 krgnode141
${IP_BASE}.142 krgnode142
${IP_BASE}.143 krgnode143
${IP_BASE}.144 krgnode144
${IP_BASE}.145 krgnode145
${IP_BASE}.146 krgnode146
${IP_BASE}.147 krgnode147
${IP_BASE}.148 krgnode148
${IP_BASE}.149 krgnode149
${IP_BASE}.150 krgnode150
${IP_BASE}.151 krgnode151
${IP_BASE}.152 krgnode152
${IP_BASE}.153 krgnode153
${IP_BASE}.154 krgnode154
${IP_BASE}.155 krgnode155
${IP_BASE}.156 krgnode156
${IP_BASE}.157 krgnode157
${IP_BASE}.158 krgnode158
${IP_BASE}.159 krgnode159
${IP_BASE}.160 krgnode160
${IP_BASE}.161 krgnode161
${IP_BASE}.162 krgnode162
${IP_BASE}.163 krgnode163
${IP_BASE}.164 krgnode164
${IP_BASE}.165 krgnode165
${IP_BASE}.166 krgnode166
${IP_BASE}.167 krgnode167
${IP_BASE}.168 krgnode168
${IP_BASE}.169 krgnode169
${IP_BASE}.170 krgnode170
${IP_BASE}.171 krgnode171
${IP_BASE}.172 krgnode172
${IP_BASE}.173 krgnode173
${IP_BASE}.174 krgnode174
${IP_BASE}.175 krgnode175
${IP_BASE}.176 krgnode176
${IP_BASE}.177 krgnode177
${IP_BASE}.178 krgnode178
${IP_BASE}.179 krgnode179
${IP_BASE}.180 krgnode180
${IP_BASE}.181 krgnode181
${IP_BASE}.182 krgnode182
${IP_BASE}.183 krgnode183
${IP_BASE}.184 krgnode184
${IP_BASE}.185 krgnode185
${IP_BASE}.186 krgnode186
${IP_BASE}.187 krgnode187
${IP_BASE}.188 krgnode188
${IP_BASE}.189 krgnode189
${IP_BASE}.190 krgnode190
${IP_BASE}.191 krgnode191
${IP_BASE}.192 krgnode192
${IP_BASE}.193 krgnode193
${IP_BASE}.194 krgnode194
${IP_BASE}.195 krgnode195
${IP_BASE}.196 krgnode196
${IP_BASE}.197 krgnode197
${IP_BASE}.198 krgnode198
${IP_BASE}.199 krgnode199
${IP_BASE}.200 krgnode200
${IP_BASE}.201 krgnode201
${IP_BASE}.202 krgnode202
${IP_BASE}.203 krgnode203
${IP_BASE}.204 krgnode204
${IP_BASE}.205 krgnode205
${IP_BASE}.206 krgnode206
${IP_BASE}.207 krgnode207
${IP_BASE}.208 krgnode208
${IP_BASE}.209 krgnode209
${IP_BASE}.210 krgnode210
${IP_BASE}.211 krgnode211
${IP_BASE}.212 krgnode212
${IP_BASE}.213 krgnode213
${IP_BASE}.214 krgnode214
${IP_BASE}.215 krgnode215
${IP_BASE}.216 krgnode216
${IP_BASE}.217 krgnode217
${IP_BASE}.218 krgnode218
${IP_BASE}.219 krgnode219
${IP_BASE}.220 krgnode220
${IP_BASE}.221 krgnode221
${IP_BASE}.222 krgnode222
${IP_BASE}.223 krgnode223
${IP_BASE}.224 krgnode224
${IP_BASE}.225 krgnode225
${IP_BASE}.226 krgnode226
${IP_BASE}.227 krgnode227
${IP_BASE}.228 krgnode228
${IP_BASE}.229 krgnode229
${IP_BASE}.230 krgnode230
${IP_BASE}.231 krgnode231
${IP_BASE}.232 krgnode232
${IP_BASE}.233 krgnode233
${IP_BASE}.234 krgnode234
${IP_BASE}.235 krgnode235
${IP_BASE}.236 krgnode236
${IP_BASE}.237 krgnode237
${IP_BASE}.238 krgnode238
${IP_BASE}.239 krgnode239
${IP_BASE}.240 krgnode240
${IP_BASE}.241 krgnode241
${IP_BASE}.242 krgnode242
${IP_BASE}.243 krgnode243
${IP_BASE}.244 krgnode244
${IP_BASE}.245 krgnode245
${IP_BASE}.246 krgnode246
${IP_BASE}.247 krgnode247
${IP_BASE}.248 krgnode248
${IP_BASE}.249 krgnode249
${IP_BASE}.250 krgnode250
${IP_BASE}.251 krgnode251
${IP_BASE}.252 krgnode252
${IP_BASE}.253 krgnode253
${IP_BASE}.254 krgnode254\" > /etc/hosts

echo" > "${DIR_NFSROOT}/root/init_server_before.sh"

	chmod u+x "${DIR_NFSROOT}/root/init_server_before.sh"

	$ECHO
	$ECHO "Entering in chroot '${DIR_NFSROOT}'"
	chroot "${DIR_NFSROOT}" bash "/root/init_server_before.sh"
}


#Init the nfsroot
exec_init_nfsroot() {
	check_if_configured
	check_if_x86_64
	check_if_nfsroot_created

	
  exec_init_nfsroot_before

  $ECHO
	$ECHO
	$ECHO "A file init.sh is created in ${DIR_NFSROOT}/root/."
	
	echo "#!/bin/bash
	
# Set the parameter for ccache
exec_configure_ccache() {	
	if [ -e \"/usr/local/bin/gcc\" ]; then
		echo \"Ccache is already configured !\"
	else
		ln -s /usr/bin/ccache /usr/local/bin/c++
		ln -s /usr/bin/ccache /usr/local/bin/c89-gcc
		ln -s /usr/bin/ccache /usr/local/bin/c99-gcc
		ln -s /usr/bin/ccache /usr/local/bin/cc
		ln -s /usr/bin/ccache /usr/local/bin/cpp
		ln -s /usr/bin/ccache /usr/local/bin/g++
		ln -s /usr/bin/ccache /usr/local/bin/gcc 
		
		echo \"Ccache is configured !\"
	fi
}	
		
let \"nb_job=$(get_nb_cpu) + 1\"

echo \"Set the language :\"
export LANGUAGE=\"${LANGUAGE}\"
export LC_ALL=\"${LANGUAGE}\"
export LC_MESSAGES=\"${LANGUAGE}\"
export LC_CTYPES=\"${LANGUAGE}\"
export LANG=\"${LANGUAGE}\"
aptitude -y install locales
dpkg-reconfigure locales

sleep 1

echo
echo \"Mount the device...\"
mount -t proc none /proc

sleep 1

echo
echo \"Install package...\"
aptitude -y install make ccache gcc g++ docbook-xsl xsltproc automake libtool git git-core git-arch git-completion bzip2 python initramfs-tools ncurses-dev grub-pc openssh-server dhcp3-common nfs-common nfsbooted stress psmisc

sleep 1


$ECHO
$ECHO \"Update and upgrade packages...\"
aptitude update
aptitude upgrade
	
sleep 1


sleep 1

echo
echo \"Define the mount table...\"
rm -f /etc/mtab
ln -s /proc/mounts /etc/mtab

sleep 1

echo \"# A swap partition
/dev/hda    none    		swap		sw        0 0
none        /proc			proc		defaults  0 0
none        /sys    		sysfs		defaults  0 0
none        /config 		configfs	defaults  0 0
none        /var/run		tmpfs		defaults  0 0
none		/var/lib/ntp/	tmpfs		defaults,uid=ntp,gid=ntp	0 0
devpts		/dev/pts		devpts		defaults	0 0\" > /etc/fstab

sleep 1

echo
exec_configure_ccache

sleep 1

echo
echo \"Getting kerrighed tools :\"
if [ -d \"/root/kerrighed/.git\" ]; then
	echo \"Update from the repertory\"
	cd /root/kerrighed ; git pull
else
	echo \"Clone the repertory\"
	#git clone git://git-externe.kerlabs.com/kerrighed-tools.git /root/kerrighed
	git clone git://kerrighed.git.sourceforge.net/gitroot/kerrighed/tools /root/kerrighed

	echo \"Apply patch for tools\"
	cd /root/kerrighed
	git apply --stat /root/patch-tools.patch
	git apply /root/patch-tools.patch
	cd -
fi

sleep 1

echo
echo \"Getting kerrighed kernel (take a long time !) :\"
if [ -d \"/root/kerrighed/_kernel/.git\" ]; then
	echo \"Update from the repertory\"
	cd /root/kerrighed/_kernel ; git pull
else
	echo \"Clone the repertory\"
	#git clone git://git-externe.kerlabs.com/kerrighed-kernel.git /root/kerrighed/_kernel
	git clone git://kerrighed.git.sourceforge.net/gitroot/kerrighed/kernel /root/kerrighed/_kernel

        echo \"Apply patch for kernel\"
        cd /root/kerrighed/_kernel
        git apply --stat /root/patch-kernel.patch
        git apply /root/patch-kernel.patch
        cd -
fi

sleep 1

echo
echo \"Launch autogen.sh :\"
cd /root/kerrighed/ ; ./autogen.sh

sleep 1

echo
echo \"Configure kerrighed :\"
cd /root/kerrighed/ ; ./configure --sysconfdir=/etc

sleep 1

echo
echo \"Make menuconfig of the kerrighed kernel :\"
cd /root/kerrighed/_kernel/ ; make menuconfig -j \$nb_job

sleep 1

echo
echo \"Clean of the kerrighed kernel :\"
cd /root/kerrighed/_kernel/ ; make mrproper -j \$nb_job
rm -f /boot/*.old

sleep 1

echo
echo \"Compile kerrighed kernel :\"
cd /root/kerrighed/ ; make -j \$nb_job

sleep 1


echo \"Create module dir :\"
DIRMOD=$(cat /root/kerrighed/kernel/include/config/kernel.release)
mkdir -p $DIRMOD
echo \"    $DIRMOD\"


sleep 1

echo
echo \"Install kerrighed kernel :\"
cd /root/kerrighed/ ; make install DESTDIR=/ INSTALL_PATH=boot INSTALL_MOD_PATH=root -j \$nb_job


sleep 1


echo
echo \"Update initramfs :\"
update-initramfs -v -k all -u

sleep 1


echo
echo \"Configure parameters for schedulers :\"
mkdir -p /config

sleep 1

update-rc.d kerrighed-host defaults 60

sleep 1

echo
echo \"Umount the device...\"
umount /proc

echo" > "${DIR_NFSROOT}/root/init.sh"

	chmod u+x "${DIR_NFSROOT}/root/init.sh"

	$ECHO
	$ECHO "Copy patches"
	cp "./patch-tools.patch" "${DIR_NFSROOT}/root/"
	cp "./patch-kernel.patch" "${DIR_NFSROOT}/root/"

	$ECHO
	$ECHO "Entering in chroot '${DIR_NFSROOT}'"
	chroot "${DIR_NFSROOT}" bash "/root/init.sh"

  exec_init_nfsroot_after
}

#Init the nfsroot_after
exec_init_nfsroot_after() {
	check_if_configured
	check_if_x86_64
	check_if_nfsroot_created
	
	$ECHO
	$ECHO
	$ECHO "A file init_server_after.sh is created in ${DIR_NFSROOT}/root/."
	
 	echo "#!/bin/bash
	
echo
echo \"Configure initramfs...\"
echo \"#
# initramfs.conf
# Configuration file for mkinitramfs(8). See initramfs.conf(5).
#
# Note that configuration options from this file can be overridden
# by config files in the /etc/initramfs-tools/conf.d directory.

#
# MODULES: [ most | netboot | dep | list ]
#
# most - Add most filesystem and all harddrive drivers.
#
# dep - Try and guess which modules to load.
#
# netboot - Add the base modules, network modules, but skip block devices.
#
# list - Only include modules from the 'additional modules' list
#

MODULES=netboot

#
# BUSYBOX: [ y | n ]
#
# Use busybox if available.
#

BUSYBOX=y

#
# COMPCACHE_SIZE: [ \\\"x K\\\" | \\\"x M\\\" | \\\"x G\\\" | \\\"x %\\\" ]
#
# Amount of RAM to use for RAM-based compressed swap space.
#
# An empty value - compcache isn't used, or added to the initramfs at all.
# An integer and K (e.g. 65536 K) - use a number of kilobytes.
# An integer and M (e.g. 256 M) - use a number of megabytes.
# An integer and G (e.g. 1 G) - use a number of gigabytes.
# An integer and % (e.g. 50 %) - use a percentage of the amount of RAM.
#
# You can optionally install the compcache package to configure this setting
# via debconf and have userspace scripts to load and unload compcache.
# 

COMPCACHE_SIZE=\\\"\\\"


#
# KEYMAP: [ y | n ]
#
# Load a keymap during the initramfs stage.
#

KEYMAP=y


#
# COMPRESS: [ gzip | bzip2 | lzma | lzop ]
#

COMPRESS=gzip

#
# NFS Section of the config.
#

#
# BOOT: [ local | nfs ]
#
# local - Boot off of local media (harddrive, USB stick).
#
# nfs - Boot using an NFS drive as the root of the drive.
#

BOOT=nfs

#
# DEVICE: ...
#
# Specify a specific network interface, like eth0
# Overridden by optional ip= bootarg
#

DEVICE=eth0

#
# NFSROOT: [ auto | HOST:MOUNT ]
#

NFSROOT=${IP_SERVER}:/

\" > /etc/initramfs-tools/initramfs.conf

sleep 1

echo
echo \"Generate initrd for the kernels installed :\"
listKernel=\$(ls /lib/modules/)
for i in \$listKernel; do
	mkinitramfs -o /boot/initrd.img-\$i \$i
	echo \"    Kernel : \$i\"
done

echo" > "${DIR_NFSROOT}/root/init_server_after.sh"

	chmod u+x "${DIR_NFSROOT}/root/init_server_after.sh"

	$ECHO
	$ECHO "Entering in chroot '${DIR_NFSROOT}'"
	chroot "${DIR_NFSROOT}" bash "/root/init_server_after.sh"

	$ECHO
	$ECHO "Finishing the installation..."
	exec_finish_init_nfsroot
}

# Finish the init of the nfsroot
exec_finish_init_nfsroot() {
	check_if_configured
	check_if_nfsroot_created
	
	$ECHO
	$ECHO "Configure '${DIR_TFTPROOT}/pxelinux.cfg/default' ..."
	
	rm -fr "${DIR_TFTPROOT}/pxelinux.cfg/default"
	touch "${DIR_TFTPROOT}/pxelinux.cfg/default"
	
	first=1
	listKernel=$(ls "${DIR_NFSROOT}/lib/modules/")
	for i in $listKernel; do
		cp "${DIR_NFSROOT}/boot/initrd.img-$i" "${DIR_TFTPROOT}"
		cp "${DIR_NFSROOT}/boot/vmlinuz-$i" "${DIR_TFTPROOT}"
		
		if [ "$first" == "1" ]; then
				echo "DEFAULT kerrighed-$i
				" >> "${DIR_TFTPROOT}/pxelinux.cfg/default"
				first=0
		fi
				
		$ECHO "   Kernel '$i'..."
		echo "LABEL kerrighed-$i
    kernel vmlinuz-$i
    append initrd=initrd.img-$i root=/dev/nfs rw ip=dhcp nfsroot=${IP_SERVER}:${DIR_NFSROOT}/ session_id=1 autonodeid=1 debug=1 loglevel=7
" >> "${DIR_TFTPROOT}/pxelinux.cfg/default"
	done
	$ECHO "Finish"
	
	service_all_restart
	
	exec_config_set
		
	$ECHO
	$ECHO "Installation is finished ! You can launch the virtual machine with : $(get_absolute_path $0) start"	
}

# Init krgmon
exec_init_krgmon() {
	check_if_x86_64
	check_if_nfsroot_created
		
	MYSQL_DB="krgmigmon"
	MYSQL_USER="krgmon"
	MYSQL_HOST="localhost"
	MYSQL_PWD="krgmonPwd"
		
	echo "
echo \"Install package...\"
aptitude -y install snmp snmpd libnet-snmp-perl


sleep 1

echo
echo \"Getting krgmon :\"
if [ -d \"/root/krgmon/.svn\" ]; then
	echo \"Update from the repertory\"
	cd /root/krgmon/ ; git pull
else
	echo \"Clone the repertory\"
	git clone git://git.cru.fr/krgmon.git /root/krgmon
fi

sleep 1

echo
echo \"Compile and install krgmon ...\"
cd /root/krgmon/trunk/Drivers ; make KSRC=/root/kerrighed/kernel/ -f Makefile.kernel
cd /root/krgmon/trunk/Drivers ; make KSRC=/root/kerrighed/kernel/ -f Makefile.kernel install
cd /root/krgmon/trunk/Drivers ; make install-kerrighed-migmon-odev
cd /root/krgmon/trunk/Drivers ; make install-kerrighed-migmon-driver
cd /root/krgmon/trunk/Drivers ; make install-kerrighed-migmon-client


echo" > "${DIR_NFSROOT}/root/init_krgmon.sh"


	chmod u+x "${DIR_NFSROOT}/root/init_krgmon.sh"

	$ECHO
	$ECHO "Entering in chroot '${DIR_NFSROOT}'"
	chroot "${DIR_NFSROOT}" bash "/root/init_krgmon.sh"
		
	$ECHO
	$ECHO "Install package ..."
	aptitude -y install snmp snmpd libnet-snmp-perl ruby rubygems mysql-server
	
	$ECHO
	$ECHO "Update Ruby on Rails ..."
	gem update --no-rdoc --system 1.5.3
	
	$ECHO
	$ECHO "Install Ruby on Rails ..."
	gem install --no-rdoc -v=2.3.2 rails activerecord actionpack actionmailer activeresource activesupport

	$ECHO
	$ECHO "Install krgmon ..."
	cd "${DIR_NFSROOT}/root/krgmon/trunk/Drivers" ; make install-kerrighed-migmon-mysql
	
	sleep 1
	
	
	$ECHO
	$ECHO "Configure the SNMP Server..."
	echo "###############################################################################
#
# EXAMPLE-trap.conf:
#   An example configuration file for configuring the Net-SNMP snmptrapd agent.
#
###############################################################################
#
# This file is intended to only be an example.  If, however, you want
# to use it, it should be placed in /etc/snmp/snmptrapd.conf.
# When the snmptrapd agent starts up, this is where it will look for it.
#
# All lines beginning with a '#' are comments and are intended for you
# to read.  All other lines are configuration commands for the agent.

#
# PLEASE: read the snmptrapd.conf(5) manual page as well!
#

authCommunity log,execute,net public
traphandle KERRIGHED-MONITORING-MIB::krgMigrationNotif /usr/sbin/kerrighed-migmon-insert-mysql.pl
" > /etc/snmp/snmptrapd.conf
	
	sleep 1
	
	$ECHO
	$ECHO "Restart the SNMP Server ..."
	service_snmp_restart
	
	sleep 1
	
	
	mUser=$(cat /etc/mysql/debian.cnf | grep "user" | head -n 1 | cut -d'=' -f2 | grep -E -o "([a-zA-Z0-9_.-]+)")
	mPwd=$(cat /etc/mysql/debian.cnf | grep "password" | head -n 1 | cut -d'=' -f2 | grep -E -o "([a-zA-Z0-9_.-]+)")
	
	
	
	$ECHO
	$ECHO "Create database '${MYSQL_DB}' ..."
	mysqladmin -u"${mUser}" -p"${mPwd}" create "${MYSQL_DB}"	
	
	
	
	$ECHO
	$ECHO "Create user '${MYSQL_USER}' ..."
	testExist=$(mysql -u"${mUser}" -p"${mPwd}" -s -e "USE mysql;SELECT User FROM user WHERE User='krgmon';" | tail -n 1)
	
	if [ ! -z "${testExist}" ]; then
		$ECHO "   Delete old user ..."
		userDel=$(mysql -u"${mUser}" -p"${mPwd}" -s -e "USE mysql;SELECT User FROM user WHERE User='krgmon';" | tail -n 1)
		hostDel=$(mysql -u"${mUser}" -p"${mPwd}" -s -e "USE mysql;SELECT Host FROM user WHERE User='krgmon';" | tail -n 1)
		mysql -u"${mUser}" -p"${mPwd}" -e "DROP USER '${userDel}'@'${hostDel}';" | tail -n 1
	fi
	
	
	$ECHO "   Create user ..."
	echo "CREATE USER '${MYSQL_USER}'@'${MYSQL_HOST}' IDENTIFIED BY '${MYSQL_PWD}';

GRANT USAGE ON * . * TO '${MYSQL_USER}'@'${MYSQL_HOST}' IDENTIFIED BY '${MYSQL_PWD}';
GRANT Select, Insert, Update, Delete, Create, Drop ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'${MYSQL_HOST}' IDENTIFIED BY '${MYSQL_PWD}';
FLUSH PRIVILEGES;

USE ${MYSQL_DB};

CREATE TABLE IF NOT EXISTS \`migrations\` (
  \`id\` int(11) NOT NULL AUTO_INCREMENT,
  \`process_id\` int(11) NOT NULL DEFAULT '0',
  \`startDate\` datetime DEFAULT NULL,
  \`endDate\` datetime DEFAULT NULL,
  \`startNode\` int(11) DEFAULT NULL,
  \`endNode\` int(11) DEFAULT NULL,
  \`created_at\` datetime DEFAULT NULL,
  \`updated_at\` datetime DEFAULT NULL,
  PRIMARY KEY (\`id\`),
  KEY \`endDate\` (\`endDate\`),
  KEY \`startDate\` (\`startDate\`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

" > /tmp/query.sql

	mysql -u"${mUser}" -p"${mPwd}" < /tmp/query.sql
	
	rm -f /tmp/query.sql
	
	
	sleep 1
	
	$ECHO
	$ECHO "Define MySQL configuration for krgmon ..."
	echo "development:
  adapter: mysql
  host: localhost
  database: ${MYSQL_DB}
  username: ${MYSQL_USER}
  password: ${MYSQL_PWD}
  
test:
  adapter: mysql
  host: localhost
  database: ${MYSQL_DB}
  username: ${MYSQL_USER}
  password: ${MYSQL_PWD}

production:
  adapter: mysql
  host: localhost
  database: ${MYSQL_DB}
  username: ${MYSQL_USER}
  password: ${MYSQL_PWD}
  " > "${DIR_NFSROOT}/root/krgmon/trunk/RailsApp/config/database.yml"
	
	
	
	sleep 1
	
	$ECHO
	exec_start_krgmon
}

# Init all for the installation
exec_init_kerrighed() {
	check_if_x86_64
	
	exec_install_deps
	exec_create_nfsroot
    exec_configure_servers
	exec_init_nfsroot
}


exec_stop_krgmon() {
	$ECHO "Stop Ruby Server ..."
	pid=$(get_pid_krgmon_launched)
	if [ ! -z "$pid" ]; then
		$ECHO "   Kill pid:$pid ..."
		kill -9 $pid
	fi	
}


exec_start_krgmon() {
	$ECHO "Launch Ruby Server on 'localhost:3000/krgmon' ..."
	pid=$(get_pid_krgmon_launched)
	if [ ! -z "$pid" ]; then
		$ECHO "   Kill pid:$pid ..."
		kill -9 $pid
	fi	
	
	sleep 1
	
	pid=$(get_pid_krgmon_launched)
	if [ -z "$pid" ]; then
		$ECHO "   Launch server ..."
		"${DIR_NFSROOT}/root/krgmon/trunk/RailsApp/script/server" ${RUBY_CONFIG}
	fi	
}


# Display the status
exec_status() {
	check_if_configured
	check_if_nfsroot_created
					
	checkLaunched=$(is_launched)
	if [ -z "${checkLaunched}" ]; then
		$ECHO "Virtual machine run        : no"
	else
		pid=$(get_pid_launched)
		if [ -z "${pid}" ]; then
			$ECHO "Virtual machine run        : no"
		else
			$ECHO "Virtual machine run        : yes (pid:${pid})"
		fi
	fi
	
	pid=$(get_pid_krgmon_launched)
	if [ -z "$pid" ]; then
		$ECHO "Ruby server for krgmon     : no"
	else
		$ECHO "Ruby server for krgmon     : yes (pid:${pid})"
	fi	
}


# Start the virtual machine with an external kernel
exec_start() {
	check_if_configured
	check_if_nfsroot_created
	
	checkLaunched=$(is_launched)
	if [ -z "${checkLaunched}" ]; then
			
		$ECHO
		$ECHO "Configure network interface..."
		testHosts=$(ifconfig -a | grep "${QEMU_DEVICE_NAME}")
		if [ -z "${testHosts}" ]; then
		
			
			echo "    Script qemu-ifup..."
			touch $(get_absolute_path ${SCRIPT_QEMU_UP})
			chmod a+x $(get_absolute_path ${SCRIPT_QEMU_UP})
			echo "#!/bin/sh" > $(get_absolute_path ${SCRIPT_QEMU_UP})
			
		
			if [ "${COMMAND_PARAM_OPTION}" == "--no-virtual-device" ]; then
				
				echo "    Configure ${QEMU_DEVICE_NAME} interface..."
				tunctl -u root -t ${QEMU_DEVICE_NAME}
				
				echo "    Activating link for ${QEMU_DEVICE_NAME} ..."
				ip link set ${QEMU_DEVICE_NAME} up
				
				echo "    Set Promisc and IP 0.0.0.0 on ${QEMU_DEVICE_NAME} and ${DEVICE_ETH0}..."
				ifconfig ${QEMU_DEVICE_NAME} 0.0.0.0 promisc up
				ifconfig ${DEVICE_ETH0} 0.0.0.0 promisc up
				 
				echo "    Adding the bridge device ${QEMU_BRIDGE_NAME}..."
				brctl addbr ${QEMU_BRIDGE_NAME}				
				
				echo "    Configure the bridge device ${QEMU_BRIDGE_NAME}..."
				brctl addif ${QEMU_BRIDGE_NAME} ${QEMU_DEVICE_NAME}
				brctl addif ${QEMU_BRIDGE_NAME} ${DEVICE_ETH0}
				
				echo "    IP address ${IP_SERVER} on ${QEMU_BRIDGE_NAME}..."
				ifconfig ${QEMU_BRIDGE_NAME} ${IP_SERVER} broadcast ${IP_BASE}.255 netmask 255.255.255.0 up								
				
			else
				echo "    Configure ${QEMU_DEVICE_NAME} interface..."
				tunctl -u root -t ${QEMU_DEVICE_NAME}
				
				echo "    Activating link for ${QEMU_DEVICE_NAME} ..."
				ip link set ${QEMU_DEVICE_NAME} up
								
				echo "    IP address ${IP_SERVER} on ${QEMU_DEVICE_NAME}..."
				ifconfig ${QEMU_DEVICE_NAME} ${IP_SERVER} broadcast ${IP_BASE}.255 netmask 255.255.255.0 up
				
				
				echo "ifconfig ${QEMU_DEVICE_NAME} ${IP_SERVER} broadcast ${IP_BASE}.255 netmask 255.255.255.0 up" >> $(get_absolute_path ${SCRIPT_QEMU_UP})
			fi
				
		fi

		$ECHO
		$ECHO "Restart the daemon..."
		service_dhcp_restart
		
		if [ "${COMMAND_PARAM_OPTION}" == "--no-virtual-device" ]; then
			$QEMU  ${QEMU_CONFIG}
		else
			$QEMU  ${QEMU_CONFIG}
		fi
    echo "$QEMU $QEMU_CONFIG"
		pid=$(get_pid_launched)	
		
		$ECHO "The virtual machine is started (pid:${pid}) !"
	else
		$ECHO "The virtual machine is Already running !"
	fi
}

# Stop the virtual machine
exec_stop() {
	check_if_configured
	check_if_nfsroot_created
	
	checkLaunched=$(is_launched)
	if [ -z "${checkLaunched}" ]; then
		$ECHO "The virtual machine is Already stopped !"
	else
		
		pid=$(get_pid_launched)
		if [ ! -z "$pid" ]; then
			kill -9 $pid
		fi
		$ECHO "The virtual machine is stopping (pid:${pid}) !"
	fi
	
				
	echo "    Delete script qemu-ifup..."		
	rm -f $(get_absolute_path ${SCRIPT_QEMU_UP})
			
	testHosts=$(ifconfig -a | grep "${QEMU_BRIDGE_NAME}")
	if [ ! -z "${testHosts}" ]; then
		sleep 1
		
		echo "    Delete virtual bridge ${QEMU_BRIDGE_NAME}..."	
		ifconfig ${QEMU_BRIDGE_NAME} down
		brctl delbr ${QEMU_BRIDGE_NAME}
		
		echo "    Set IP default on ${DEVICE_ETH0}..."
		ifconfig ${QEMU_DEVICE_NAME} 0.0.0.0 -promisc down
		ifconfig ${DEVICE_ETH0} ${IP_SERVER} -promisc up
	fi
		
	testHosts=$(ifconfig -a | grep "${QEMU_DEVICE_NAME}")
	if [ ! -z "${testHosts}" ]; then
		sleep 1
		
		echo "    Delete virtual device ${QEMU_DEVICE_NAME}..."	
		tunctl -d ${QEMU_DEVICE_NAME}
	fi
}

# Exec the vncviewer
exec_view() {
	check_if_configured
	check_if_nfsroot_created
	
	checkLaunched=$(is_launched)
	if [ -z "${checkLaunched}" ]; then
		$ECHO "The virtual machine is stopped !"
	else
		vncviewer ${QEMU_DISPLAY_VNC}
	fi
}

# Remove the configuration
exec_config_remove() {
	check_if_configured
	
	rm -f "$(get_absolute_path ${FILE_CONFIG})"
}

# Set the configuration
exec_config_set() {
		echo "DIR_NFSROOT=\"$(get_absolute_path ${DIR_NFSROOT})\"
DIR_TFTPROOT=\"$(get_absolute_path ${DIR_TFTPROOT})\"
IP_BASE=\"${IP_BASE}\"
IP_SERVER=\"${IP_SERVER}\"
DEVICE_ETH0=\"${DEVICE_ETH0}\"" > "$(get_absolute_path ${FILE_CONFIG})"
}

# Display the configuration
exec_config_display() {
	check_if_configured
	
	$ECHO "DIR_NFSROOT=\"${DIR_NFSROOT}\"
DIR_TFTPROOT=\"${DIR_TFTPROOT}\"
IP_BASE=\"${IP_BASE}\"
IP_SERVER=\"${IP_SERVER}\"
DEVICE_ETH0=\"${DEVICE_ETH0}\""
}



check_if_root


if [ -e "$(get_absolute_path ${FILE_CONFIG})" ]; then
	source "$(get_absolute_path ${FILE_CONFIG})"
fi

check=$(is_launched)


$ECHO

case $1 in
install_deps)
	exec_install_deps
	;;
service_all_restart)
	service_all_restart
	;;
service_all_start)
	service_all_start
	;;
service_all_stop)
	service_all_stop
	;;
configure_servers)
	exec_configure_servers 1
	;;
create_nfsroot)
	exec_create_nfsroot
	;;
init_nfsroot)
	exec_init_nfsroot
	;;
finish_init_nfsroot)
	exec_finish_init_nfsroot
	;;
init_krgmon)
	exec_init_krgmon
	;;
init_kerrighed)
	exec_init_kerrighed
	;;
stop_krgmon)
	exec_stop_krgmon
    ;;
start_krgmon)
    exec_start_krgmon
    ;;
restart_krgmon)
    exec_stop_krgmon
    exec_start_krgmon
    ;;
status)
    exec_status
    ;;
stop)
	exec_stop
    ;;
start)
    exec_start
    ;;
restart)
	exec_stop
    exec_start
    ;;
view)
    exec_view
    ;;
config_remove)
	exec_config_remove
    ;;
config_display)
	exec_config_display
    ;;
config)
	# Define the configuration file
	if [ $# -gt 1 ]; then
		case $# in
		2)
			DIR_NFSROOT="${2}"
			DIR_TFTPROOT="${DIR_TFTPROOT_DEFAULT}"
			IP_BASE="${IP_BASE_DEFAULT}"
			IP_SERVER="${IP_SERVER_DEFAULT}"
			DEVICE_ETH0="${DEVICE_ETH0_DEFAULT}"
			;;
		3)
			DIR_NFSROOT="${2}"
			DIR_TFTPROOT="${3}"
			IP_BASE="${IP_BASE_DEFAULT}"
			IP_SERVER="${IP_SERVER_DEFAULT}"
			DEVICE_ETH0="${DEVICE_ETH0_DEFAULT}"
			;;
		4)
			DIR_NFSROOT="${2}"
			DIR_TFTPROOT="${3}"
			IP_BASE="${4}"
			IP_SERVER="${IP_SERVER_DEFAULT}"
			DEVICE_ETH0="${DEVICE_ETH0_DEFAULT}"
			;;
		5)
			DIR_NFSROOT="${2}"
			DIR_TFTPROOT="${3}"
			IP_BASE="${4}"
			IP_SERVER="${5}"
			DEVICE_ETH0="${DEVICE_ETH0_DEFAULT}"
			;;
		*)
			DIR_NFSROOT="${2}"
			DIR_TFTPROOT="${3}"
			IP_BASE="${4}"
			IP_SERVER="${5}"
			DEVICE_ETH0="${6}"
			;;
		esac
		
		exec_config_set
		
		exit 1
	fi
	check_if_configured
	;;
*)
	check_if_configured
	
	
    $ECHO "The script permit to manage a nfs server for Kerrighed and test the installation with a virtual machine with qemu."
    $ECHO "In additionnal, the script manage the installation and execution of krgmon."
    $ECHO " - Global :"
    $ECHO "    status : Display the status"
    $ECHO "    service_all_restart : Restart all service"
    $ECHO "    service_all_start : Start all service"
    $ECHO "    service_all_stop : Stop all service"
    $ECHO ""
    $ECHO " - Kerrighed :"
    $ECHO "    init_kerrighed : Install the dependances and create the NFSROOT (not krgmon)"
    $ECHO ""
    $ECHO " - Virtual Machine :"
    $ECHO "    start : Start the virtual machine connected with the NFSROOT"
    $ECHO "        --no-virtual-device : Use the device in the config file (${DEVICE_ETH0}) instead of a virtual device (${QEMU_DEVICE_NAME})."
    $ECHO "    restart : Restart the virtual machine"
    $ECHO "    stop : Stop the virtual machine"
    $ECHO "    view : Start the vncviewer for the virtual machine"
    $ECHO
    $ECHO ""
    $ECHO " - Krgmon :"
    $ECHO "    start_krgmon : Start krgmon"
    $ECHO "    restart_krgmon : Restart krgmon"
    $ECHO "    stop_krgmon : Stop krgmon"
    $ECHO "    init_krgmon : Install the dependances and install krgmon"
    $ECHO ""
    $ECHO " - Configuration :"
    $ECHO "    config_display : Display the configuration file"
    $ECHO "    config_remove : Remove the configuration file"
    $ECHO ""
    $ECHO " - Kerrighed Advanced (these steps are executed with 'init_kerrighed') :"
    $ECHO "    install_deps : Install the dependances"
    $ECHO "    configure_servers : Overwrite the configurations files for the servers : TFTP, DHCP and NFS"
    $ECHO "    create_nfsroot : Create the nfsroot (Warning : This command erase the data !)"
    $ECHO "    init_nfsroot : Initialize and configure the nfsroot (install package, update repository, compile kernel)"
esac

$ECHO
