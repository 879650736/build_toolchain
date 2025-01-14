#!/bin/sh

mkdir ~/tmp
cd ~/tmp

# See
# Typical ARM triples (see "armv7l-linux-gnueabi")
# https://bgamari.github.io/posts/2019-06-12-arm-terminology.html
# GCC -march options
# https://gcc.gnu.org/onlinedocs/gcc/ARM-Options.html
# # error "Assumed value of MB_LEN_MAX wrong"
# https://www.linuxquestions.org/questions/linux-software-2/tar-cross-compile-error-arm-linux-gnueabi-4175642648/
# GCC Cross Toolchain names
# https://blog.csdn.net/weixin_39832348/article/details/110578256

# Notes
# https://askubuntu.com/questions/1235819/ubuntu-20-04-gcc-version-lower-than-gcc-7
# deb http://dk.archive.ubuntu.com/ubuntu/ xenial main
# deb http://dk.archive.ubuntu.com/ubuntu/ xenial universe
# apt install -y curl git make cmake automake binutils build-essential gcc-4.7-arm-linux-gnueabi
# update-alternatives --install /usr/bin/arm-linux-gnueabi-gcc arm-linux-gnueabi-gcc /usr/bin/arm-linux-gnueabi-gcc-4.7 0
# update-alternatives --install /usr/bin/arm-linux-gnueabi-cpp arm-linux-gnueabi-cpp /usr/bin/arm-linux-gnueabi-cpp-4.7 0
# cross_compile_build_zlib.sh remove -mfpu=

# file /usr/arm-linux-gnueabi/lib/libc.so.6
# arm-linux-gnueabi-gcc -print-file-name=libc.so

# Download binutils, gcc, the linux kernel, glibc
# https://gist.github.com/rikka0w0/612149263721050f69acdc0497bf9fb8
# https://blog.csdn.net/fickyou/article/details/51671006
wget http://ftpmirror.gnu.org/binutils/binutils-2.24.tar.gz
wget http://ftpmirror.gnu.org/gcc/gcc-4.9.2/gcc-4.9.2.tar.gz
wget --no-check-certificate https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.18.31.tar.xz
wget http://ftpmirror.gnu.org/glibc/glibc-2.21.tar.xz
for f in *.tar*; do tar xf $f; done
mv binutils-2.24 binutils
mv linux-3.18.31 linux
mv gcc-4.9.2 gcc
mv glibc-2.21 glibc

# define the prefix
export PREFIX=/opt/armv7l

# change PATH to include the target directory
export PATH=$PREFIX/bin:$PATH

# Build binutils
cd ~/tmp/binutils
./configure --prefix=$PREFIX --target=arm-linux-gnueabi --with-arch=armv7l --with-float=soft --disable-multilib --disable-werror
make -j4 
make install

# Install the Linux kernel headers
cd ~/tmp/linux
make ARCH=arm INSTALL_HDR_PATH=$PREFIX/arm-linux-gnueabi headers_install

# Build gcc (first phase)
cd ~/tmp/gcc
./contrib/download_prerequisites
mkdir build; cd build
../configure --prefix=$PREFIX --target=arm-linux-gnueabi --enable-languages=c,c++ --with-arch=armv7 --with-float=soft --disable-multilib --disable-werror
make -j4 all-gcc
make install-gcc

# Build glibc (first phase)
cd ~/tmp/glibc
mkdir build; cd build
../configure --prefix=$PREFIX/arm-linux-gnueabihf --build=$MACHTYPE --host=arm-linux-gnueabihf --target=arm-linux-gnueabihf --with-arch=armv7l --with-fpu=vfp --with-float=hard --with-headers=$PREFIX/arm-linux-gnueabihf/include --disable-multilib libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j4 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/arm-linux-gnueabihf/lib
arm-linux-gnueabihf-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX/arm-linux-gnueabihf/lib/libc.so
touch $PREFIX/arm-linux-gnueabihf/include/gnu/stubs.h

# Build gcc (second phase, libgcc)
cd ~/tmp/gcc/build
make -j4 all-target-libgcc
make install-target-libgcc

# Build glibc (second phase)
cd ~/tmp/glibc/build
make -j4
make install

# Build libstdc++
cd ~/tmp/gcc/build
make -j4
make install
