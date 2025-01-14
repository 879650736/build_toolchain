#!/bin/bash

set -e

# install tools
# apt install flex bison gawk rsync 

if [ $# -ne 1 ]; then
        echo "use: $0 [option1]
	可以使用的选项如下：
	  all:          完成所有的工作
	  env：         配置环境，包括配置PATH变量
	  init:         解压缩gz文件，并创建tools目录保存生成的交叉编译工具
          binutils:     配置和安装binutils
	  linux:        配置和安装linux系统头文件，因为第二遍编译GCCs生成C库的时候需要用到）
	  pass1-gcc:    配置和安装与GCC相关的这一套工具（不包括共享库）
	  glibc:        安装标准C库头文件和启动文件
	  libgcc:       安装编译器支持库
	  all-glibc:    安装标准C库
	  final:        配置和安装all GCC，包括所依赖的共享库等
          delete:       删除tools目录与解压缩出来的所有文件,请在每次重新开始配置之前，运行delete
          code:         获取gz文件，包括gcc、glibc、binutils等，在整个环境配置过程中只需要运行一次
        如果想要使用glibc安装交叉编译工具，则推荐安装顺序为：init -> linux -> binutils -> pass1-gcc -> glibc -> libgcc -> all-glibc -> final
	"
        exit 1
fi

TARGET="arm-acoreos-linux-gnueabi"

# all
if [ "$1" == "all" ]; then

	$0 env
        $0 delete
        $0 init
        $0 linux
        $0 binutils
        $0 pass1-gcc
        $0 glibc
        $0 libgcc
        $0 all-glibc
        $0 final
fi

if [ "$1" == "env" ]; then
	if [ ! -d "${HOME}/arm-acoreos-toolchain" ]; then
		echo "不存在${HOME}/arm-acoreos-toolchain，正在创建..."
		mkdir -p ${HOME}/arm-acoreos-toolchain
		cd ${HOME}/arm-acoreos-toolchain
		mkdir tools source
		cd source 
		echo "正在下载源码..."
		$0 code
	fi
	if ! grep -q "${HOME}/arm-acoreos-toolchain/tools/bin" ~/.bashrc; then
		echo ".bashrc文件中不存在该bin目录路径, 正在添加..."
		echo "export PATH=${HOME}/arm-acoreos-toolchain/tools/bin:\$PATH" >> ~/.bashrc
		source ~/.bashrc
	fi
	echo "环境初始化完成，接下来请执行： $0 init"
fi

# init
if [ "$1" == "init" ]; then
	cd ${HOME}/arm-acoreos-toolchain/source
	for f in *.tar.gz; do tar -zxvf $f; done
	tar -xvJf linux-6.1.10.tar.xz
	mkdir ${HOME}/arm-acoreos-toolchain/tools
	echo "解压操作完成，并且完成文件夹的初始化，接下来请执行:  $0 linux"
fi


# step1: linux keneral header file
if [ "$1" == "linux" ]; then
        cd ${HOME}/arm-acoreos-toolchain/source/linux-6.1.10
        make ARCH=arm headers_install INSTALL_HDR_PATH=${HOME}/arm-acoreos-toolchain/tools/${TARGET}/
        echo "linxu内核头文件安装完成，接下来请执行： $0 binutils"
fi

# step2: binutils
if [ "$1" == "binutils" ]; then 
        cd ${HOME}/arm-acoreos-toolchain/source/binutils-2.37        
	if [ -d "build" ]; then
	# 	cd build && make distclean
		rm -rf build
	fi
	mkdir build && cd build
	../configure --target=${TARGET} --prefix="${HOME}/arm-acoreos-toolchain/tools" \
		--disable-multilib \
		--disable-werror \
		--with-pkgversion="aarch64-linux with glibc and binutils-2.37" \
		-v 2>&1 | tee binutils-configure.log
        make -j4 2>&1 | tee binutils-make.log
        make install 2>&1 | tee binutils-make-install.log
	echo "binutils 安装完成, 接下来请执行:  $0 pass1-gcc"
fi


# step3: 安装c/c++编译器
# --disable-libsanitizer参数用于解决final阶段不存在crypt.h文件的错误
if [ "$1" == "pass1-gcc" ]; then
	cd ${HOME}/arm-acoreos-toolchain/source/gcc-13.2.0
	if [ -d "build-pass1" ]; then
		# cd build-pass1 && make distclean
		rm -rf build-pass1
	fi
	mkdir build-pass1 && cd build-pass1
	../configure --target=${TARGET} --prefix="${HOME}/arm-acoreos-toolchain/tools" \
                --disable-multilib \
                --enable-languages=c,c++,go \
		--disable-libsanitizer \
		--disable-decimal-float --disable-lto --disable-libmudflap \
		--disable-libquadmath --disable-libssp --disable-nls \
		# --disable-tls \
                --with-as="${HOME}/arm-acoreos-toolchain/source/binutils-2.37/build/gas/as-new" \
                --with-ld="${HOME}/arm-acoreos-toolchain/source/binutils-2.37/build/ld/ld-new" \
		--with-pkgversion="Self across toolchain with glibc and gcc-13.2.0" \
                --enable-threads=posix 2>&1 | tee pass1-configure.log
	make -j4 all-gcc 2>&1 | tee pass1-make-all-gcc.log
	make install-gcc 2>&1 | tee pass1-make-install-gcc.log
	echo "安装C/C++编译器完成，接下来请执行： $0 glibc"
fi

# step4: 安装标准C库头文件和启动文件
if [ "$1" == "glibc" ]; then
	cd ${HOME}/arm-acoreos-toolchain/source/glibc-2.39
	if [ -d "build" ]; then
		rm -rf build
	fi
	mkdir build && cd build
	# 注意：glibc的configure中没有--target，glibc使用--host指定目标平台（可以通过./configure --help查看system type进行确定）
	../configure --host=${TARGET} \
		--prefix="${HOME}/arm-acoreos-toolchain/tools/${TARGET}" \
		--with-headers="${HOME}/arm-acoreos-toolchain/tools/${TARGET}/include" \
		--disable-multilib \
		--with-headers=${HOME}/arm-acoreos-toolchain/tools/${TARGET}/include \
		--disable-profile \
		--enable-threads=posix \
		--disable-werror \
		libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes libc_cv_ctors_header=yes \
		--with-pkgversion="Self across toolchain with glibc and glibc-2.39" \
		-v 2>&1 | tee glibc-configure.log
	make install-bootstrap-headers=yes install-headers
	# 为了确保所有与目标架构相关的头文件都放在usr/include目录中，这里需要使用mv命令进行移动
	# mkdir -p ${HOME}/arm-acoreos-toolchain/tools/${TARGET}/usr/include
	# mv ${HOME}/arm-acoreos-toolchain/tools/${TARGET}/include/* ${HOME}/arm-acoreos-toolchain/tools/${TARGET}/usr/include/
	make -j4 csu/subdir_lib
	install csu/crt1.o csu/crti.o csu/crtn.o ${HOME}/arm-acoreos-toolchain/tools/${TARGET}/lib
	${TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${HOME}/arm-acoreos-toolchain/tools/${TARGET}/lib/libc.so
	touch ${HOME}/arm-acoreos-toolchain/tools/${TARGET}/include/gnu/stubs.h
	echo "安装标准C库头文件和启动文件成功，接下来请执行： $0 libgcc"
fi

# step5: 安装编译器支持库
if [ "$1" == "libgcc" ]; then
	cd ${HOME}/arm-acoreos-toolchain/source/gcc-13.2.0/build-pass1
	make -j4 all-target-libgcc 2>&1 | tee all-target-libgcc.log
	make install-target-libgcc 2>&1 | tee install-target-libgcc.log 
	echo "安装编译器支持库完成，接下来请执行： $0 all-glibc"
fi

# step6：安装标准C库
if [ "$1" == "all-glibc" ]; then
	cd ${HOME}/arm-acoreos-toolchain/source/glibc-2.39/build
	make -j4 2>&1 | tee all-glibc-make.log
	make install 2>&1 | tee all-glibc-install.log
	echo "安装标准C库完成，接下来请执行： $0 final"
fi

# step7: 完成最后的构建
if [ "$1" == "final" ]; then
        cd ${HOME}/arm-acoreos-toolchain/source/gcc-13.2.0/build-pass1
        make 2>&1 | tee final-make.log
        make install 2>&1 | tee final-install.log
fi


# delete
if [ "$1" == "delete" ]; then
	cd ${HOME}/arm-acoreos-toolchain/source
	rm -rf binutils-2.37 gcc-13.2.0 glibc-2.39 linux-6.1.10
	cd ${HOME}/arm-acoreos-toolchain
	rm -rf tools
	echo "删除无用文件完成，接下来请执行： $0 init"
fi

# get source code
if [ "$1" == "code" ]; then
	cd ${HOME}/arm-acoreos-toolchain/source
	wget https://ftp.gnu.org/gnu/binutils/binutils-2.37.tar.gz
	wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.gz
	wget https://ftp.sjtu.edu.cn/sites/ftp.kernel.org/pub/linux/kernel/v6.x/linux-6.1.10.tar.xz
	wget https://ftp.gnu.org/pub/gnu/glibc/glibc-2.39.tar.gz
	echo "源码下载完成，接下来请执行： $0 init"
fi
