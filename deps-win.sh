#!/bin/bash
set -e

export LD_PRELOAD=/usr/lib/faketime/libfaketime.so.1
export FAKETIME=$REFERENCE_DATETIME
export TZ=UTC
INDIR=$HOME/build
TEMPDIR=$HOME/tmp
# Input Integrity Check
echo "9d1c8a9836aa63e2c6adb684186cbd4371c9e9dcc01d6e3bb447abf2d4d3d093  openssl-1.0.1h.tar.gz" | sha256sum -c
echo "12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz" | sha256sum -c
echo "36658cb768a54c1d4dec43c3116c27ed893e88b02ecfcb44f2166f9c0b7f2a0d  zlib-1.2.8.tar.gz" | sha256sum -c

for BITS in 32 64; do # for architectures
  #
  INSTALLPREFIX=$HOME/staging${BITS}
  BUILDDIR=$HOME/build${BITS}
  if [ "$BITS" == "32" ]; then
    HOST=i686-w64-mingw32
  else
    HOST=x86_64-w64-mingw32
  fi
  #
  mkdir -p $INSTALLPREFIX $BUILDDIR
  cd $BUILDDIR
  #
  tar xzf $INDIR/openssl-1.0.1h.tar.gz
  cd openssl-1.0.1h
  if [ "$BITS" == "32" ]; then
    OPENSSL_TGT=mingw
  else
    OPENSSL_TGT=mingw64
  fi
  ./Configure --cross-compile-prefix=$HOST- ${OPENSSL_TGT} no-shared no-dso --openssldir=$INSTALLPREFIX
  make
  make install_sw
  cd ..
  #
  tar xzf $INDIR/db-4.8.30.NC.tar.gz
  cd db-4.8.30.NC/build_unix
  ../dist/configure --prefix=$INSTALLPREFIX --enable-mingw --enable-cxx --host=$HOST --disable-shared
  make $MAKEOPTS library_build
  make install_lib install_include
  cd ../..
  #
  tar xzf $INDIR/zlib-1.2.8.tar.gz
  cd zlib-1.2.8
  CROSS_PREFIX=$HOST- ./configure --prefix=$INSTALLPREFIX --static
  make
  make install
  cd ..
  # post-process all generated libraries to be deterministic
  # extract them to a temporary directory then re-build them deterministically
  for LIB in $(find $INSTALLPREFIX -name \*.a); do
      rm -rf $TEMPDIR && mkdir $TEMPDIR && cd $TEMPDIR
      $HOST-ar xv $LIB | cut -b5- > /tmp/list.txt
      rm $LIB
      $HOST-ar crsD $LIB $(cat /tmp/list.txt)
  done
  #
  cd $INSTALLPREFIX
  find include lib | sort | zip -X@ $OUTDIR/twister-deps-win$BITS-gitian-r13.zip
done # for BITS in
