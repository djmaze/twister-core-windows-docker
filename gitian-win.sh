#!/bin/bash
set -e

# Defines
export TZ=UTC
INDIR=$HOME/build
OPTFLAGS='-O2 -static -static-libgcc -static-libstdc++'
TEMPDIR="$HOME/tempdir"
for BITS in 32 64; do # for architectures
  #
  STAGING=$HOME/staging${BITS}
  BUILDDIR=$HOME/build${BITS}
  BINDIR=$OUTDIR/$BITS
  if [ "$BITS" == "32" ]; then
    HOST=i686-w64-mingw32
  else
    HOST=x86_64-w64-mingw32
  fi
  export PATH=$STAGING/host/bin:$PATH
  mkdir -p $STAGING $BUILDDIR $BINDIR
  #
  cd $STAGING
  #unzip $INDIR/boost-win${BITS}-1.55.0-gitian-r6.zip
  #unzip $INDIR/twister-deps-win${BITS}-gitian-r13.zip
  # Build platform-dependent executables from source archive
  cd $BUILDDIR
  rm -rf distsrc
  cp -a $HOME/build/twister-core distsrc
  mkdir -p distsrc
  cd distsrc
  ./autotool.sh
  ./configure --bindir=$BINDIR --prefix=$STAGING --host=$HOST --with-boost=$STAGING --with-openssl=$STAGING CPPFLAGS="-I$STAGING/include ${OPTFLAGS}" LDFLAGS="-L$STAGING/lib ${OPTFLAGS}" CXXFLAGS="${OPTFLAGS}" --without-boost-locale
  #export LD_PRELOAD=/usr/lib/faketime/libfaketime.so.1
  #export FAKETIME=$REFERENCE_DATETIME
  make $MAKEOPTS
  strip twisterd.exe
  cp -f twisterd.exe $BINDIR/
  unset LD_PRELOAD
  unset FAKETIME
done # for BITS in

# sort distribution tar file and normalize user/group/mtime information for deterministic output
mkdir -p $OUTDIR/src
rm -rf $TEMPDIR
mkdir -p $TEMPDIR
cd $TEMPDIR
#tar -xvf $HOME/build/twister/$DISTNAME | sort | tar --no-recursion -cT /dev/stdin --mode='u+rw,go+r-w,a+X' --owner=0 --group=0 mtime="$REFERENCE_DATETIME" | gzip -n > $OUTDIR/src/$DISTNAME
cd $OUTDIR
find $OUTDIR | sort | zip -X@ /home/ubuntu/out/twister-win-gitian.zip
