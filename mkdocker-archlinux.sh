#!/bin/bash
set -e

export LANG="C.UTF-8"

GITDIR='/root/archlinux/'
DATE=`date +%Y.%m.%d`
ROOTFS=$(mktemp -d ${TMPDIR:-/var/tmp}/rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

# packages to ignore for space savings
PKGIGNORE=(
    cryptsetup
    device-mapper
    dhcpcd
    gcc-go
    iproute2
    jfsutils
    linux
    lvm2
    man-db
    man-pages
    mdadm
    nano
    netctl
    openresolv
    pciutils
    pcmciautils
    reiserfsprogs
    s-nail
    systemd-sysvcompat
    usbutils
    vi
    xfsprogs
)
IFS=','
PKGIGNORE="${PKGIGNORE[*]}"
unset IFS

pacman -Syu --noconfirm

expect <<EOF
	set send_slow {1 .1}
    proc send {ignore arg} {
		sleep .1
	exp_send -s -- \$arg
	}
	set timeout 3600

	spawn pacstrap -c -d -G -i $ROOTFS base haveged $PACMAN_EXTRA_PKGS --ignore $PKGIGNORE
	expect {
		-exact "anyway? \[Y/n\] " { send -- "n\r"; exp_continue }
		-exact "(default=all): " { send -- "\r"; exp_continue }
		-exact "installation? \[Y/n\]" { send -- "y\r"; exp_continue }
	}
EOF

arch-chroot $ROOTFS /bin/sh -c 'rm -r /usr/share/man/*'
arch-chroot $ROOTFS /bin/sh -c 'ls -d /usr/share/locale/* | egrep -v "en_U|alias" | xargs rm -rf'
arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rsu --noconfirm haveged; pacman-key --populate archlinux; pkill gpg-agent"
arch-chroot $ROOTFS /bin/sh -c "ln -s /usr/share/zoneinfo/UTC /etc/localtime"
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen
#arch-chroot $ROOTFS /bin/sh -c 'echo $PACMAN_MIRRORLIST > /etc/pacman.d/mirrorlist'
arch-chroot $ROOTFS /bin/sh -c 'rm -rf /usr/lib/firmware/*

# udev doesn't work in containers, rebuild /dev
DEV=$ROOTFS/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd


## Compress add to git repo
cd $GITDIR
git fetch --depth=1 --tags
git rm $GITDIR/*.xz
XZ_OPTS=-2 tar --numeric-owner -C $ROOTFS -cJf archlinux-$DATE.tar.xz .
chmod -v 644 archlinux-$DATE.tar.xz
sed -i "s|^ADD archlinux-.*$|ADD archlinux-$DATE.tar.xz /|" Dockerfile
git add archlinux-$DATE.tar.xz Dockerfile
git commit -m "Auto Update - $DATE"

## Update Tags - Only run during autorun hour (3am)
if [ `date +%H` -eq 3 ]; then
  git tag -d daily && git push origin :daily; git tag -a daily -m "Daily Update - $DATE"
  [ `date +%u` -eq 1 ] && git tag -d weekly && git push origin :weekly; git tag -a weekly -m "Weekly Update - $DATE"
  [ `date +%d` -eq 1 ] && git tag -d monthly && git push origin :monthly; git tag -a monthly -m "Monthly Update - $DATE"
fi

git push --follow-tags
find $GITDIR -mindepth 1 -delete
git clone --depth=1  git@github.com:finalduty/docker-archlinux.git $GITDIR
git fetch --tags --depth=1

rm -rf $ROOTFS

