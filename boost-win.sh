#!/bin/bash
set -e

# Defines
export LD_PRELOAD=/usr/lib/faketime/libfaketime.so.1
export FAKETIME=$REFERENCE_DATETIME
export TZ=UTC
INDIR=$HOME/build
TEMPDIR=$HOME/tmp
# Input Integrity Check
echo "fff00023dd79486d444c8e29922f4072e1d451fc5a4d2b6075852ead7f2b7b52  boost_1_55_0.tar.bz2" | shasum -c
echo "d2b7f6a1d7051faef3c9cf41a92fa3671d905ef1e1da920d07651a43299f6268  boost-mingw-gas-cross-compile-2013-03-03.patch" | shasum -c

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
  tar --warning=no-timestamp -xjf $INDIR/boost_1_55_0.tar.bz2
  cd boost_1_55_0
  GCCVERSION=$($HOST-g++ -E -dM $(mktemp --suffix=.h) | grep __VERSION__ | cut -d ' ' -f 3 | cut -d '"' -f 2)
  echo "using gcc : $GCCVERSION : $HOST-g++
      :
      <rc>$HOST-windres
      <archiver>$HOST-ar
      <cxxflags>-frandom-seed=boost1
      <ranlib>$HOST-ranlib
;" > user-config.jam
  ./bootstrap.sh --without-icu

  # Workaround: Upstream boost dev refuses to include patch that would allow Free Software cross-compile toolchain to work
  # This patch was authored by the Fedora package developer and ships in Fedora's mingw32-boost.
  # Please obtain the exact patch that matches the above sha256sum from one of the following mirrors.
  #
  # Read History: https://svn.boost.org/trac/boost/ticket/7262
  # History Mirror: http://rose.makesad.us/~paulproteus/mirrors/7262%20Boost.Context%20fails%20to%20build%20using%20MinGW.html
  #
  # Patch: https://svn.boost.org/trac/boost/raw-attachment/ticket/7262/boost-mingw.patch
  # Patch Mirror: http://wtogami.fedorapeople.org/boost-mingw-gas-cross-compile-2013-03-03.patch
  # Patch Mirror: http://mindstalk.net/host/boost-mingw-gas-cross-compile-2013-03-03.patch
  # Patch Mirror: http://rose.makesad.us/~paulproteus/mirrors/boost-mingw-gas-cross-compile-2013-03-03.patch
  patch -p0 < $INDIR/boost-mingw-gas-cross-compile-2013-03-03.patch

  # Bug Workaround: boost-1.54.0 broke the ability to disable zlib, still broken in 1.55
  # https://svn.boost.org/trac/boost/ticket/9156
  sed -i 's^\[ ac.check-library /zlib//zlib : <library>/zlib//zlib^^' libs/iostreams/build/Jamfile.v2
  sed -i 's^<source>zlib.cpp <source>gzip.cpp \]^^' libs/iostreams/build/Jamfile.v2

  # http://statmt.org/~s0565741/software/boost_1_52_0/libs/context/doc/html/context/requirements.html
  # "For cross-compiling the lib you must specify certain additional properties at bjam command line: target-os, abi, binary-format, architecture and address-model."
  ./bjam --user-config=user-config.jam toolset=gcc binary-format=pe target-os=windows threadapi=win32 address-model=$BITS threading=multi variant=release link=static runtime-link=static --user-config=user-config.jam -sNO_BZIP2=1 -sNO_ZLIB=1 --layout=tagged --build-type=complete --prefix="$INSTALLPREFIX" $MAKEOPTS install
  # post-process all generated libraries to be deterministic
  # extract them to a temporary directory then re-build them deterministically
  for LIB in $(find $INSTALLPREFIX -name \*.a); do
      rm -rf $TEMPDIR && mkdir $TEMPDIR && cd $TEMPDIR
      $HOST-ar xv $LIB | cut -b5- > /tmp/list.txt
      rm $LIB
      $HOST-ar crsD $LIB $(cat /tmp/list.txt)
  done
  #
  cd "$INSTALLPREFIX"
  find | sort | zip -X@ $OUTDIR/boost-win$BITS-1.55.0-gitian-r6.zip
done # for BITS in
