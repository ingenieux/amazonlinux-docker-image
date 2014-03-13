#!/bin/bash

set -ex

SERIES=3.x
VERSION=3.12.14
BRANCH=3.12

if [ "x" != "x$1" ]; then
  VERSION="$1"
fi

if [ "x" != "x$2" ]; then
  VERSION="$2"
fi

cd /media/ephemeral0

rm -rf kernel aufs a b aufs-util

if [ ! -f linux-$VERSION.tar.xz ]; then
  wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-$VERSION.tar.xz
fi

mkdir kernel
cd kernel
tar xf ../linux-$VERSION.tar.xz --strip-components=1
cat /boot/config-* > .config
mkdir patches
echo CONFIG_AUFS_FS=y >> .config

(cd .. ; 
 git clone git://git.code.sf.net/p/aufs/aufs3-standalone aufs ; 
 cd aufs ; 
 git checkout origin/aufs$BRANCH ; 

 mkdir ../a ../b ;
 cp -r Documentation ../b ;
 cp -r fs ../b ;
 cp -r include ../b ;
 rm ../b/include/linux/Kbuild ;
 cd .. ;
 diff -rupN a/ b/ > kernel/patches/aufs.patch ;
 cp aufs/*.patch >> kernel/patches/aufs.patch
) || true

(cat patches/*.patch | patch -p1 -t) || true

make olddefconfig
make -j3 bzImage
make -j3 modules
make
make modules_install
make install

(cd .. ; 
 git clone git://git.code.sf.net/p/aufs/aufs-util ;
 cd aufs-util
 git checkout origin/aufs3.9 ;
 cd aufs-util ;
 make all install
)

grubby --add-kernel=/boot/vmlinuz-$VERSION --make-default --title="Custom Docker Kernel" --initrd=/boot/initramfs-$VERSION.img --args="root=LABEL=/ console=hvc0"

return 0