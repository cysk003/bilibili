#!/bin/sh
# Define a netboot Alpine VM to run adhole, the adblocker
# domain name you want to use
my_domain="adhole-alpine01"
# your kernel and initramfs downloaded dir name
my_dir="/nfsroot/VMs/alpine/x86_64/netboot"
# Web 端的 apkovl.tar.gz 的路径
# apkovl="http://192.168.7.11/apkovl/adhole.apkovl.tar.gz"
apkovl="https://apkovl:AdH0!e@apkovl.freelamp.com/adhole.apkovl.tar.gz"
cmdline="console=ttyS0 modloop=none ip=dhcp apkovl=$apkovl"
# netboot image url
nb_url="https://mirror.nju.edu.cn/alpine/latest-stable/releases/x86_64/netboot"
#
# use the last autostart network as your network name
my_network="$(virsh -q net-list --autostart --name | tail -1)"
[ -z "$my_network" ] && echo "Error: Please define an autostart network first!" && exit 1
#
virsh domid $my_domain >/dev/null 2>&1
[ $? = 0 ] && echo "Info: $my_domain exist, undefine it first." && virsh undefine $my_domain
# define a 1c/2G VM, 2GB is needed for adhole to process over 1M blocking domains
cat <<EOF >/tmp/$my_domain.xml
<domain type='kvm'>
   <name>$my_domain</name>
   <metadata>
     <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
       <libosinfo:os id="http://alpinelinux.org/alpinelinux/3.17"/>
     </libosinfo:libosinfo>
   </metadata>
   <os>
     <type arch='x86_64' machine='pc-q35-7.2'>hvm</type>
     <kernel></kernel>
     <initrd></initrd>
     <cmdline></cmdline>
   </os>
   <memory unit='KiB'>2048000</memory>
   <currentMemory unit='KiB'>2048000</currentMemory>
   <vcpu placement='static'>1</vcpu>
</domain>
EOF
virsh define /tmp/$my_domain.xml
[ $? != 0 ] && echo "Error: unable to define domain, please check: /tmp/$my_domain.xml" && exit 1
rm /tmp/$my_domain.xml && echo "Info: removed: /tmp/$my_domain.xml"
#
virt-xml $my_domain --edit --metadata description="This VM is auto-generated by $0, a script coined by LeisureLinux."
#
# Old way: virt-xml $my_domain --edit --xml ./os/kernel="$my_dir/vmlinuz-lts"
virt-xml $my_domain --edit --boot kernel="$my_dir/vmlinuz-lts"
[ $? != 0 ] && echo "Error: found error in kernel define" && virsh undefine $my_domain && exit 1
virt-xml $my_domain --edit --boot initrd="$my_dir/initramfs-lts"
[ $? != 0 ] && echo "Error: found error in initrd define" && virsh undefine $my_domain && exit 2
virt-xml $my_domain --edit --boot cmdline="$cmdline"
[ $? != 0 ] && echo "Error: found error in cmdline define" && virsh undefine $my_domain && exit 3
#
virt-xml $my_domain --add-device --network $my_network
[ $? != 0 ] && echo "Error: found error in network device add" && virsh undefine $my_domain && exit 4
virt-xml $my_domain --add-device --controller pci,model=pcie-root-port
virt-xml $my_domain --add-device --serial pty,target_type=isa-serial
virt-xml $my_domain --add-device --console pty,target_type=virtio
[ $? != 0 ] && echo "Error: found error in serial device add" && virsh undefine $my_domain && exit 5
echo
echo "Domain $my_domain defined!"

# 下载最新版本的支持 netboot 的内核和initrd:
[ ! -r $my_dir/vmlinuz-lts ] && axel -o $my_dir $nb_url/vmlinuz-lts
[ ! -r $my_dir/initramfs-lts ] && axel -o $my_dir $nb_url/initramfs-lts