#!/usr/bin/env bash
set -e
# keep original env. in all_env, must place ahead. as set and printenv output are different.
all_env=$(set)
VER=1.2.1-20251011
# If you don't like the RPT_DIR name, change it here.
# I will/may add -o or -d parameter to support self-define of output dir.
RPT_DIR=$HOME/.mysosreport
# Collect system info and user behaviour log with non-root permission;
# Learn Linux command, understand OS/Kernel/Desktop.
# 以普通用户权限，收集系统和用户日志；学习 Linux 命令，了解 Linux 系统和桌面；
# Features:
# - support customized int_xxx functions to collect
# - support pipewire commands
# - support gsettings
# - support fonts list
# - support XXX
#
# Todo:
# - NIC Card
! test -d $RPT_DIR && mkdir -p $RPT_DIR
CASE_ID=$RPT_DIR/.caseid
! test -f $CASE_ID && echo 0 >$CASE_ID
caseid=$(($(cat $CASE_ID) + 1))
#
CASE="${RPT_DIR}/$(hostname).${USER}.${caseid}.$(date -I)-$(date +%s).txt"
echo -e "Info: user space view/log will be collected into case file:\n$CASE"

int_fast_fetch() {
  # Use fastfetch to get OS info.
  # Hardware board
  a="datetime:locale:chassis:host:board:cpu:gpu:memory:bios:tpm:battery:loadavg:cpuusage:wifi:"
  # OS,Kernel
  b="os:kernel:initsystem:bootmgr:shell:"
  # Disk
  c="disk:diskio:swap:"
  # Hardware peripheral
  d="display:monitor:bluetooth:brightness:camera:keyboard:mouse:"
  # Network
  e="localip:dns:netio:"
  # Packages and Processes
  f="packages:processes:editor:"
  # Multimedia
  g="sound:media:"
  #terminal
  h="terminal:terminalsize:terminaltheme:font:"
  # Graphic
  i="theme:vulkan:wallpaper:lm:de:wm:icons:opencl:opengl:"
  #
  ! command -v fastfetch >/dev/null && echo "Error: fastfetch not found!" && return
  fastfetch --show-errors -l none -s "$a$b$c$d$e$f$g$h$i"
}

int_printenv() {
  # Avoid to send sensitive ENV
  echo "set_command: $all_env"
  printenv | grep -E "^XDG|PATH=|^DISPLAY"
}

int_gsettings() {
  gsettings list-schemas | xargs -I {} gsettings list-recursively {}
}

int_fonts() {
  fc-cache -fvr
  fc-list
}

int_nic() {
  # wireless NIC name usually starts with letter "w"
  for nic in $(ip -j link show | jq -r '.[] |select(.ifname|startswith("w")|not)|.ifname' | grep -vw "lo"); do
    ethtool $nic
  done
}

int_pkg_history() {
  # pass in: install, or remove
  # test "$1" = "install" && zcat -f $(/usr/bin/ls -1t /var/log/dpkg.log*) | sort -nr | awk '$3 ~/install/ {print $4}' || zcat -f $(/usr/bin/ls -1t /var/log/dpkg.log*) | sort -nr | awk '$3 ~/remove/ {print $4}'
  zgrep -h -E "status installed|status not-installed" /var/log/dpkg.log* | sort -nr
}

int_modinfo() {
  lsmod | awk '{print $1}' | xargs -I {} sh -c 'echo "module:\t\t{}";modinfo {}'
}

# Main Prog.
# we don't export LC_ALL=C, to keep the LC_ALL in original setting.
start=$(date +%s)
echo "Start collect at $(date -Isecond)-${start}" | tee -a $CASE
echo -e "\t-- Collected by $(pinky -bl $USER | fmt -u)" | tee -a $CASE
#

while read cmd; do
  test -z "$cmd" && continue
  test "${cmd:0:1}" = "#" && continue
  echo "CMD: [$cmd]" | tee -a $CASE
  echo "======================" | tee -a $CASE
  test "${cmd:0:4}" = "grep" && cmd="$cmd |grep ."
  (eval $cmd || echo "Error: run $cmd failed!") | tee -a $CASE
  echo "" | tee -a $CASE
done <<<"
locale
cat /proc/cmdline
int_printenv
int_fast_fetch
apt-cache stats
apt-cache policy
dpkg -l
int_pkg_history
pstree
int_nic
ip link show
ip address show
ip route show
systemctl status NetworkManager
int_fonts
int_gsettings
# apparmor_status
ls -alZ /etc/apparmor.d/abstractions
ls -alZ /etc/apparmor.d/libvirt
gdbus call -y -d com.ubuntu.WhoopsiePreferences -o /com/ubuntu/WhoopsiePreferences -m com.ubuntu.WhoopsiePreferences.GetIdentifier
ls -alZR /var/crash
grep -B 50 -m 1 ProcMaps /var/crash/*
# apt-get check
apt-config dump
apt-cache stats
apt-cache policy
apt-mark showhold
# hdparm /dev/sdb
# hdparm /dev/sda
smartctl -a /dev/sdb
smartctl -a /dev/sda
smartctl -a /dev/sdb -j
smartctl -a /dev/sda -j
smartctl -l scterc /dev/sdb
smartctl -l scterc /dev/sda
smartctl -l scterc /dev/sdb -j
smartctl -l scterc /dev/sda -j
ls -alZR /dev
ls -alZR /sys/block
blkid -c /dev/null
lsblk
lsblk -O -P
lsblk -t
lsblk -D
# blockdev --report
losetup -a
# parted -s /dev/sdb unit s print
# parted -s /dev/nvme0n1 unit s print
# parted -s /dev/sda unit s print
udevadm info /dev/sdb
udevadm info /dev/nvme0n1
udevadm info /dev/sda
udevadm info -a /dev/sdb
udevadm info -a /dev/nvme0n1
udevadm info -a /dev/sda
# fdisk -l /dev/sdb
# fdisk -l /dev/nvme0n1
# fdisk -l /dev/sda
ls -alZR /boot
ls -alZR /sys/firmware/
ls -alZ /initrd.img
lsinitrd
# mokutil --sb-state
efibootmgr -v
# lsinitramfs -l /initrd.img
# lsinitramfs -l /boot/initrd.img
# this is for Redhat: grubby --default-kernel
btrfs filesystem show
btrfs version
systemd-cgls
cat /proc/crypto
# crontab -l -u root
# fips-mode-setup --check
# update-crypto-policies --show
# update-crypto-policies --is-applied
systemctl status cups
journalctl --no-pager --unit cups --reverse
systemctl status cups-browsed
journalctl --no-pager --unit cups-browsed --reverse
lpstat -t
lpstat -s
lpstat -d
date
date --utc
# hwclock
busctl list --no-pager
busctl status
busctl tree
modinfo dm_mod
# dmsetup info -c
# dmsetup table
# dmsetup status
# dmsetup ls --tree
# dmsetup udevcookies
# dmstats list
# dmstats print --allregions
udevadm info --export-db
mount -l
df -al -x autofs
df -aliT -x autofs
findmnt --real
findmnt --pseudo
lslocks -u
lsns -uT
# dumpe2fs -h /dev/nvme0n1p5
# dumpe2fs -h /dev/nvme0n1p3
modinfo ip_tables
modinfo nf_tables
modinfo nfnetlink
# ip6tables -t mangle -nvL
# ip6tables -t filter -nvL
# ip6tables -t nat -nvL
# iptables -vnxL
# ip6tables -vnxL
flatpak --version
flatpak --default-arch
flatpak --supported-arches
flatpak --gl-drivers
flatpak --installations
flatpak --print-updated-env
flatpak config
flatpak remote-list --show-details
flatpak list --runtime --show-details
flatpak list --app --show-details
flatpak history --columns=all
systemctl status fwupd
journalctl --no-pager --unit fwupd --reverse
# grub2-mkconfig
# haproxy -f /etc/haproxy/haproxy.cfg -c
# systemctl status haproxy
journalctl --no-pager --unit haproxy --reverse
# dmidecode
lshw
hostname
hostname -f
uptime
find / -maxdepth 2 -type l -ls
# hostid
hostnamectl status
update-alternatives --display java
readlink -f /usr/bin/java
java -version
uname -a
lsmod
ls -alZ /sys/kernel/slab
int_modinfo
find /lib/modules/*/updates -ls
# dmesg
# dmesg -T
# dkms status
sysctl -a
# kvm_stat --once
# ls -alZR /var/lib/libvirt/qemu
systemctl status lightdm
journalctl --no-pager --unit lightdm --reverse
last -F
last -F reboot
last -F shutdown
# lastlog
# lastlog -u 0-999
# lastlog -u 1000-60000
# lastlog -u 60001-65536
# lastlog -u 65537-4294967295
# lastlog2
lslogins
logrotate --debug /etc/logrotate.conf
journalctl --disk-usage
ls -alZRs /var/log
# too much lines
# journalctl --no-pager --reverse
journalctl --no-pager --boot --reverse
journalctl --no-pager --boot -1 --reverse
vgdisplay -vv --config="global{metadata_read_only=1}" --nolocking --foreign
lvs -a -o +lv_tags,devices,lv_kernel_read_ahead,lv_read_ahead,stripes,stripesize --config="global{metadata_read_only=1}" --nolocking --foreign
pvs -a -v -o +pv_mda_free,pv_mda_size,pv_mda_count,pv_mda_used_count,pe_start --config="global{metadata_read_only=1}" --nolocking --foreign
vgs -v -o +vg_mda_count,vg_mda_free,vg_mda_size,vg_mda_used_count,vg_tags,systemid,lock_type --config="global{metadata_read_only=1}" --nolocking --foreign
pvscan -v --config="global{metadata_read_only=1}" --nolocking
vgscan -vvv --config="global{metadata_read_only=1}" --nolocking
mdadm -D /dev/md*
free
free -m
swapon --bytes --show
swapon --summary --verbose
lsmem -a -o RANGE,SIZE,STATE,REMOVABLE,ZONES,NODE,BLOCK
# slabtop -o
# multipath -ll
# multipath -v4 -ll
# multipath -t
# multipathd show config
# du -s /var/lib/mysql/*
# du -s /var/lib/percona-xtradb-cluster/*
ip -o addr
ip route show table all
# plotnetcfg
netstat -W -neopa
nstat -zas
netstat -s
netstat -s -6
netstat -W -agn
# networkctl status -a
ip -6 route show table all
ip -d route show cache
ip -d -6 route show cache
ip -4 rule list
ip -6 rule list
ip vrf show
ip -s -d link
ip -d address
# ifenslave -a
ip mroute show
ip maddr show
ip -s neigh show
ip neigh show nud noarp
# biosdevname -d
tc -s qdisc show
# nmstatectl show
# nmstatectl show --running-config
devlink dev param show
devlink dev info
devlink port show
devlink sb show
devlink sb pool show
devlink sb port pool show
devlink sb tc bind show
devlink -s -v trap show
ss -s
ethtool -g lo
ethtool -g virbr0
ethtool -g wlp0s20f3
ethtool -g br100
ethtool -g enx68da73ae0000
ethtool -g lxcbr0
ethtool -i lo
ethtool -i virbr0
ethtool -i wlp0s20f3
ethtool -i br100
ethtool -i enx68da73ae0000
ethtool -i lxcbr0
ethtool -k lo
ethtool -k virbr0
ethtool -k wlp0s20f3
ethtool -k br100
ethtool -k enx68da73ae0000
ethtool -k lxcbr0
ethtool -P lo
ethtool -P virbr0
ethtool -P wlp0s20f3
ethtool -P br100
ethtool -P enx68da73ae0000
ethtool -P lxcbr0
ethtool -S lo
ethtool -S virbr0
ethtool -S wlp0s20f3
ethtool -S br100
ethtool -S enx68da73ae0000
ethtool -S lxcbr0
ethtool -T lo
ethtool -T virbr0
ethtool -T wlp0s20f3
ethtool -T br100
ethtool -T enx68da73ae0000
ethtool -T lxcbr0
ethtool lo
ethtool virbr0
ethtool wlp0s20f3
ethtool br100
ethtool enx68da73ae0000
ethtool lxcbr0
ethtool --phy-statistics lo
ethtool --show-priv-flags lo
ethtool --show-eee lo
ethtool --show-fec lo
ethtool --show-ntuple lo
tc -s filter show dev lo
tc -s filter show dev enx68da73ae0000 ingress
ip netns
bridge -s -s -d link show
bridge -s -s -d -t fdb show
bridge -s -s -d -t mdb show
bridge -d vlan show
ls -alZ /etc/netplan
node -v
systemctl status nvidia-persistenced
journalctl --no-pager --unit nvidia-persistenced --reverse
nvidia-smi --list-gpus
nvidia-smi -q -d PERFORMANCE
nvidia-smi -q -d SUPPORTED_CLOCKS
nvidia-smi -q -d PAGE_RETIREMENT
nvidia-smi -q
nvidia-smi -q -d ECC
nvidia-smi nvlink -s
nvidia-smi nvlink -e
nvidia-ctk cdi list
nvidia-ctk --version
nvidia-smi --query-gpu=gpu_name,gpu_bus_id,vbios_version,temperature.gpu,utilization.gpu,memory.total,memory.free,memory.used,clocks.applications.graphics,clocks.applications.memory --format=csv
nvidia-smi --query-retired-pages=timestamp,gpu_bus_id,gpu_serial,gpu_uuid,retired_pages.address,retired_pages.cause --format=csv
modinfo nvme
modinfo nvme_core
nvme list
nvme list-subsys
smartctl --all /dev/nvme0n1
smartctl --all /dev/nvme0n1 -j
# # nvme list-ns /dev/nvme0n1
# nvme fw-log /dev/nvme0n1
# nvme list-ctrl /dev/nvme0n1
# nvme id-ctrl -H /dev/nvme0n1
# nvme id-ns -H /dev/nvme0n1
# nvme smart-log /dev/nvme0n1
# nvme error-log /dev/nvme0n1
# nvme show-regs /dev/nvme0n1
clinfo
glxinfo
# pam_tally2
# faillock
ls -alZ /lib/x86_64-linux-gnu/security
lspci -nnvv
lspci -tv
perl -V
# adsl-status
# procenv
ps auxwwwm
pstree -lp
# lsof +M -n -l -c
ps alxwww
ps auxfwww
ps -elfL
ps axo pid,ppid,user,group,lwp,nlwp,start_time,comm,cgroup
ps axo flags,state,uid,pid,ppid,pgid,sid,cls,pri,psr,addr,sz,wchan:20,lstart,tty,time,cmd
# iotop -b -o -d 0.5 -t -n 20
pidstat -p ALL -rudvwsRU --human -h
pidstat -tl
lscpu
lscpu -ae
# cpufreq-info
cpuid -1
# cpuid -r
cpupower frequency-info
cpupower info
cpupower idle-info
turbostat --debug sleep 10
# x86info -a
pactl list sinks
pactl list sources
pactl list cards
pactl info
pactl stat
pactl --version
pulseaudio --dump-conf
pulseaudio --dump-modules
pulseaudio --check
pw-cli i all
pw-metadata -n settings
pw-dump
pw-top -bn1
python3 -V
/usr/bin/pip -v list installed
# redis-cli info
lsb_release -cdr
ruby --version
irb --version
gem --version
gem list
testparm -s
wbinfo --domain=
wbinfo --trusted-domains --verbose
wbinfo --check-secret
wbinfo --online-status
net primarytrust dumpinfo
net ads info
net ads testjoin
net conf list
lsscsi -i
# sg_map -x
# lspath
# lsmap -all
# lsnports
lsscsi -H
lsscsi -d
lsscsi -s
lsscsi -L
lsscsi -iw
lsscsi -t
udevadm info -a /sys/class/scsi_host/host0
# sg_persist --in -k -d /dev/sdb
# sg_persist --in -k -d /dev/sda
# sg_persist --in -r -d /dev/sdb
# sg_persist --in -r -d /dev/sda
# sg_persist --in -s -d /dev/sdb
# sg_persist --in -s -d /dev/sda
# sg_inq /dev/sdb
# sg_inq /dev/sda
/sbin/runlevel
ls -alZ /var/lock/subsys
aplay -l
aplay -L
amixer
cat $HOME/.ssh/config
# sshd -T
ld.so --help
ld.so --list-diagnostics
ld.so --list-tunables
ls -alZR /lib/systemd
journalctl --list-boots
systemctl list-dependencies
systemctl list-jobs
systemctl list-machines
systemctl list-unit-files
systemctl list-units
systemctl list-units --all
systemctl list-units --failed
systemctl list-timers --all
systemctl show --all
# too much lines
# systemctl show *service --all
systemctl show-environment
systemctl status --all
systemd-delta
systemd-analyze
systemd-analyze blame
# too much lines
# systemd-analyze dump
systemd-inhibit --list
timedatectl
timedatectl show-timesync
# systemd-analyze plot
# sysvipc
ipcs
ipcs -u
# tpm2_getcap properties-variable
# tpm2_getcap properties-fixed
# tpm2_nvreadpublic
# tpm2_readclock
udisksctl status
udisksctl dump
lsusb
lsusb -v
lsusb -t
# virsh -r domcapabilities
virsh -r capabilities
virsh -r nodeinfo
virsh -r freecell --all
virsh -r node-memory-tune
virsh -r version
virsh -r pool-capabilities
virsh -r nodecpumap
virsh -r maxvcpus kvm
virsh -r sysinfo
virsh -r nodedev-list --tree
virsh -r list --all
virsh -r net-dumpxml default
virsh -r net-dumpxml host-bridge
virsh -r net-dumpxml lxc
iw list
iw dev
iwconfig
iwlist scanning
xrandr --verbose
# grub need root
# grep -v ^#  /boot/efi/EFI/debian/grub.cfg /boot/efi/EFI/grub/grub.cfg /boot/grub/grub.cfg /etc/default/grub
# kvm
cat /sys/module/kvm/srcversion
cat /sys/module/kvm_intel/srcversion
# ldconfig
ldconfig -p -N -X
# lightdm
# need root: /var/log/lightdm/lightdm.log /var/log/lightdm/x-0.log
grep -v ^# /etc/lightdm/lightdm.conf
grep -v ^# /etc/lightdm/users.conf
# login
grep -v ^# /etc/default/useradd
grep -v "^#" /etc/login.defs
# openssl
grep -v ^# /etc/ssl/openssl.cnf
# sudo
# Need root: /etc/sudoers
grep -v ^# /etc/sudo.conf
# vulkan
vulkaninfo
appstreamcli sysinfo
appstreamcli status
"
#
# Compress
end=$(date +%s)
echo -e "End collect at $(date -Isecond)-${end}.\nTotal $(wc -l <$CASE) lines.\nCost $(($end - $start)) seconds." | tee -a $CASE
echo "Compressing $CASE ..."
xz $CASE
echo $caseid >$CASE_ID
echo -e "Case file:\n $(ls -sh $CASE.xz)"
echo "Use \"xzcat $CASE.xz | less\" to check file."
echo
# ########
# commands list from sosreport: grep "added cmd" sos.log|awk -F"'" '{print $2}'
