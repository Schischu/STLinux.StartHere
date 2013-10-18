#!/bin/bash

#Usage:
#BOXTYPE=ufs912 FORK=Schischu ./start.sh
#BOXTYPE=ufs913 REPO=https://github.com/Schischu ./start.sh

if [ "x$BOXTYPE" == "x" ]; then
  BOXTYPE="ufs912"
fi
if [ "x$SW" == "x" ]; then
  SW="enigma2"
fi
if [ "x$MEDIAFW" == "x" ]; then
  MEDIAFW="gstreamer"
fi
if [ "x$FORK" == "x" ]; then
  FORK="Schischu"
fi
if [ "x$REPO" == "x" ]; then
  REPO="https://github.com/$FORK"
fi
if [ "x$BSPNAME" == "x" ]; then
  BSPNAME=STLinux.BSP-Duckbox
fi

if [ "x$SW" == "xenigma2" ]; then
  SSW="e2"
  LSW=""
  GRAPHICFW=""
elif [ "x$SW" == "xxbmc" ]; then
  SSW="xbmc"
  LSW="_$SSW"
  GRAPHICFW="_directfb"
fi

PTXCONFIG="configs/ptxconfig_${SSW}_${MEDIAFW}"
COLLECTIONCONFIG="configs/duckbox-$BOXTYPE-master/collectionconfig$LSW"
PLATFORMCONFIG="configs/duckbox-$BOXTYPE-master/platformconfig$GRAPHICFW"


BSPMAINLINENAME=$BSPNAME
BSPNEXTNAME=$BSPNAME-Next

if [ ! "x$NEXT" == "x" ]; then
  BSPNAME=$BSPNEXTNAME
fi

INSTALLDIR=`pwd`

cd $INSTALLDIR
echo "Installing to $INSTALLDIR"

if [ "$#" -eq 0 ]; then
  echo "Cloning/Pulling STLinux.StartHere ($REPO/STLinux.StartHere.git)"
  if [ ! -d $INSTALLDIR/STLinux.StartHere ]; then
    git clone $REPO/STLinux.StartHere.git
  else
    cd $INSTALLDIR/STLinux.StartHere; git pull; cd $INSTALLDIR
  fi
  rm $INSTALLDIR/start.sh
  ln -s $INSTALLDIR/STLinux.StartHere/start.sh $INSTALLDIR/start.sh
  $INSTALLDIR/start.sh forked
  exit $?;
fi

echo "Configuration"
echo "------------------------------------------------------------------------"
echo "Boxtype:    $BOXTYPE"
echo "Software:   $SW"
echo "MediaFW:    $MEDIAFW"
echo "GraphicFW:  $GRAPHICFW"
echo "Fork:       $FORK"
echo "Repo:       $REPO"
echo "BSPName:    $BSPNAME"
echo "Next:       $NEXT"
echo "InstallDir: $INSTALLDIR"
echo "-------------------------------------------------------------------------"

sleep 1

echo "Cloning/Pulling ptxdist ($REPO/ptxdist_sh.git)"
if [ ! -d $INSTALLDIR/ptxdist_sh ]; then
  git clone $REPO/ptxdist_sh.git
else
  cd $INSTALLDIR/ptxdist_sh; git pull; cd $INSTALLDIR
fi

echo "Cloning/Pulling Toolchain ($REPO/STLinux.Toolchain.git)"
if [ ! -d $INSTALLDIR/STLinux.Toolchain ]; then
  git clone $REPO/STLinux.Toolchain.git
else
  cd $INSTALLDIR/STLinux.Toolchain; git pull; cd $INSTALLDIR
fi

echo "Cloning BSP ($REPO/$BSPNAME.git)"
if [ ! -d $INSTALLDIR/$BSPNAME ]; then
  git clone $REPO/$BSPNAME.git
  cd $INSTALLDIR/$BSPNAME
  if [ "x$NEXT" == "x" ]; then
    git remote add next $REPO/$BSPNEXTNAME.git
  else
    git remote add mainline $REPO/$BSPMAINLINENAME.git
  fi
  
else
  cd $INSTALLDIR/$BSPNAME; git pull; cd $INSTALLDIR
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

mkdir -p ~/STLinux.Archive
mkdir -p ~/STLinux.Archive/boot
touch ~/STLinux.Archive/boot/audio_7100.elf
touch ~/STLinux.Archive/boot/audio_7109.elf
touch ~/STLinux.Archive/boot/audio_7105.elf
touch ~/STLinux.Archive/boot/video_7100.elf
touch ~/STLinux.Archive/boot/video_7109.elf
touch ~/STLinux.Archive/boot/video_7105.elf

cd $INSTALLDIR/STLinux.Toolchain
echo "Configuring Toolchain"
sed -i -e "s\^PTXCONF_PREFIX=.*\PTXCONF_PREFIX=$INSTALLDIR\g" ptxconfig/sh4-linux-gcc-4.7.2-glibc-2.10.2-binutils-2.23-kernel-2.6.32-sanitized.ptxconfig
ptxdist select ptxconfig/sh4-linux-gcc-4.7.2-glibc-2.10.2-binutils-2.23-kernel-2.6.32-sanitized.ptxconfig
rm -rf src; ln -s ~/STLinux.Archive src
echo "Building Toolchain to $INSTALLDIR"
ptxdist go

cd $INSTALLDIR

cd $INSTALLDIR/$BSPNAME
echo "Configuring BSP ($BSPNAME)"
ptxdist select $PTXCONFIG
ptxdist collection $COLLECTIONCONFIG
ptxdist platform $PLATFORMCONFIG
ptxdist toolchain $INSTALLDIR/STLinux.Toolchain-2013.03.1/sh4-linux/gcc-4.7.2-glibc-2.10.2-binutils-2.23.1-kernel-2.6.32-sanitized/bin
rm -rf src; ln -s ~/STLinux.Archive src

rm platform-$BOXTYPE/logfile

echo "Building BSP"
ptxdist go

echo "Building BSP - Optional packages"
# Currently we have to temporarly remove the collectionconfig to build optional packages
rm selected_collectionconfig
ptxdist go
ptxdist collection $COLLECTIONCONFIG

echo "Creating images"
ptxdist images

cd $INSTALLDIR

