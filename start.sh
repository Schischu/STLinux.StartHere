#!/bin/bash

BOXTYPE="ufs912"
INSTALLDIR=`pwd`

echo "Installing to $INSTALLDIR"

echo "Cloning ptxdist"
if [ ! -d $INSTALLDIR/ptxdist_sh ]; then
  git clone https://github.com/Schischu/ptxdist_sh.git
else
  cd $INSTALLDIR/ptxdist_sh; git pull; cd $INSTALLDIR
fi

echo "Cloning Toolchain"
if [ ! -d $INSTALLDIR/STLinux.Toolchain ]; then
  git clone https://github.com/Schischu/STLinux.Toolchain.git
else
  cd $INSTALLDIR/STLinux.Toolchain; git pull; cd $INSTALLDIR
fi

echo "Cloning BSP"
if [ ! -d $INSTALLDIR/STLinux.BSP-Duckbox ]; then
  git clone https://github.com/Schischu/STLinux.BSP-Duckbox.git
else
  cd $INSTALLDIR/STLinux.BSP-Duckbox; git pull; cd $INSTALLDIR
fi

cd $INSTALLDIR/ptxdist_sh
echo "Configuring ptxdist"
./configure --prefix=$INSTALLDIR/ptxdist
echo "Building ptxdist"
make
echo "Installing ptxdist"
make install

cd $INSTALLDIR

PATH="$PATH:$INSTALLDIR/ptxdist/bin"
echo "Setting PATH to $PATH"
export PATH

cd $INSTALLDIR/STLinux.Toolchain
echo "Configuring Toolchain"
sed -i -e "s\^PTXCONF_PREFIX=.*\PTXCONF_PREFIX=$INSTALLDIR\g" ptxconfig/sh4-linux-gcc-4.7.2-glibc-2.10.2-binutils-2.23-kernel-2.6.32-sanitized.ptxconfig
ptxdist select ptxconfig/sh4-linux-gcc-4.7.2-glibc-2.10.2-binutils-2.23-kernel-2.6.32-sanitized.ptxconfig
echo "Building Toolchain to $INSTALLDIR"
ptxdist go

cd $INSTALLDIR

cd $INSTALLDIR/STLinux.BSP-Duckbox
echo "Configuring BSP"
ptxdist select configs/duckbox-$BOXTYPE-master/ptxconfig
ptxdist platform configs/duckbox-$BOXTYPE-master/platformconfig
ptxdist toolchain $INSTALLDIR/STLinux.Toolchain-2013.03.1/sh4-linux/gcc-4.7.2-glibc-2.10.2-binutils-2.23.1-kernel-2.6.32-sanitized/bin

rm platform-$BOXTYPE/logfile

echo "Building BSP"
ptxdist go
echo "Creating images"
ptxdist images

cd $INSTALLDIR

