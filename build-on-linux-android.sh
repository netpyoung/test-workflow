#!/usr/bin/env bash
set -e

# [variable]
VERSION=v4.4.3
ROOT=$(pwd)
DIR_SOURCE=${ROOT}/sqlcipher
DIR_OUTPUT=${ROOT}/output

MINIMUM_ANDROID_SDK_VERSION=16
MINIMUM_ANDROID_64_BIT_SDK_VERSION=21


# [src] openssl
OEPNSSL_VERSION=OpenSSL_1_1_1l
git clone -b ${OEPNSSL_VERSION} --depth 1 https://github.com/openssl/openssl && cd openssl

OPENSSL_CONFIGURE_OPTIONS="-fPIC -fstack-protector-all no-idea no-camellia \
 no-seed no-bf no-cast no-rc2 no-rc4 no-rc5 no-md2 \
 no-md4 no-ecdh no-sock no-ssl3 \
 no-dsa no-dh no-ec no-ecdsa no-tls1 \
 no-rfc3779 no-whirlpool no-srp \
 no-mdc2 no-ecdh no-engine \
 no-srtp \
"

CONFIGURE_ARCH="android-arm -march=armv7-a"
ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
OFFSET_BITS=32

TOOLCHAIN_SYSTEM=linux-x86_64
TOOLCHAIN_BIN_PATH=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${TOOLCHAIN_SYSTEM}/bin
PATH=${TOOLCHAIN_BIN_PATH}:${PATH} ./Configure ${CONFIGURE_ARCH} \
 -D__ANDROID_API__=${ANDROID_API_VERSION} \
 -D_FILE_OFFSET_BITS=${OFFSET_BITS} \
 ${OPENSSL_CONFIGURE_OPTIONS}

make clean
PATH=${TOOLCHAIN_BIN_PATH}:${PATH} make build_libs

mkdir -p ${DIR_OUTPUT}/armv7-a/
mv libcrypto.a ${DIR_OUTPUT}/armv7-a/
cp -R include ${DIR_OUTPUT}/armv7-a/

ls -al ${DIR_OUTPUT}/armv7-a/

cd ..

# sqlcipher ===================================
echo "=========================================================="

otherSqlcipherCFlags="-DLOG_NDEBUG -fstack-protector-all"
sqlcipherCFlags="-DSQLITE_HAS_CODEC \
 -DSQLITE_SOUNDEX \
 -DHAVE_USLEEP=1 \
 -DSQLITE_MAX_VARIABLE_NUMBER=99999 \
 -DSQLITE_TEMP_STORE=3 \
 -DSQLITE_THREADSAFE=1 \
 -DSQLITE_DEFAULT_JOURNAL_SIZE_LIMIT=1048576 \
 -DNDEBUG=1 \
 -DSQLITE_ENABLE_MEMORY_MANAGEMENT=1 \
 -DSQLITE_ENABLE_LOAD_EXTENSION \
 -DSQLITE_ENABLE_COLUMN_METADATA \
 -DSQLITE_ENABLE_UNLOCK_NOTIFY \
 -DSQLITE_ENABLE_RTREE \
 -DSQLITE_ENABLE_STAT3 \
 -DSQLITE_ENABLE_STAT4 \
 -DSQLITE_ENABLE_JSON1 \
 -DSQLITE_ENABLE_FTS3_PARENTHESIS \
 -DSQLITE_ENABLE_FTS4 \
 -DSQLITE_ENABLE_FTS5 \
 -DSQLCIPHER_CRYPTO_OPENSSL \
 -DSQLITE_ENABLE_DBSTAT_VTAB \
"

#ARCH=arm
#ARCH=arm64
#ARCH=x86
#ARCH=x86_64

HOST=armv7a-linux-androideabi
# HOST=aarch64-linux-android
# HOST=i686-linux-android
# HOST=x86_64-linux-android

ANDROID_NDK_SYSROOT=${ANDROID_NDK_TOOLCHAIN}/sysroot
API=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}

export AR=${ANDROID_NDK_TOOLCHAIN}/bin/llvm-ar
export CC=${ANDROID_NDK_TOOLCHAIN}/bin/${HOST}${API}-clang
export AS=$CC
export CXX=${ANDROID_NDK_TOOLCHAIN}/bin/${HOST}${API}-clang++
export LD=${ANDROID_NDK_TOOLCHAIN}/bin/ld
export RANLIB=${ANDROID_NDK_TOOLCHAIN}/bin/llvm-ranlib
export STRIP=${ANDROID_NDK_TOOLCHAIN}/bin/llvm-strip

# [src] sqlcipher
git clone -b ${VERSION} --depth 1 https://github.com/sqlcipher/sqlcipher.git && cd $DIR_SOURCE


# configure
SQLCHIPER_CONFIGURE_OPTIONS="--with-crypto-lib=none \
 -enable-tempstore=no \
 --disable-tcl \
 --host ${HOST} \
"

# CFLAGS="--sysroot=${ANDROID_NDK_SYSROOT} \
# ${sqlcipherCFlags} \
# ${otherSqlcipherCFlags} \
# -I../openssl/include \
# "

CFLAGS="--sysroot=${ANDROID_NDK_SYSROOT} \
${sqlcipherCFlags} \
${otherSqlcipherCFlags} \
-I${DIR_OUTPUT}/armv7-a/include \
"
 

LDFLAGS=" \
${DIR_OUTPUT}/armv7-a/libcrypto.a \
-lm \
"

./configure ${SQLCHIPER_CONFIGURE_OPTIONS} CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"

echo "=========================================================="
# compile
make clean
make sqlite3.c
make

ls -al
ls -al .libs
echo "=========================================================="

# copy
#libsqlcipher_fpath=`readlink -f .libs/libsqlcipher.so`
#libcrypto_fpath=`readlink -f /usr/lib/x86_64-linux-gnu/libcrypto.so`
#
#mkdir -p ${DIR_OUTPUT}
#cp ${libsqlcipher_fpath} ${DIR_OUTPUT}/libsqlcipher.so
#cp ${libcrypto_fpath} ${DIR_OUTPUT}/libcrypto.so
#
## zip -r lib.zip libsodium/.libs/*
#ls -al ${DIR_OUTPUT}