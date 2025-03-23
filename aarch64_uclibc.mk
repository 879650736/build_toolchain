# 定义变量
SHELL := /bin/bash
TARGET := aarch64-unknown-linux-uclibc
TOOLCHAIN_HOME := $(HOME)/aarch-gcc-build_a
WORK_DIR := $(HOME)/build_toolchain
SOURCE_DIR := $(TOOLCHAIN_HOME)/source
TOOLS_DIR := $(TOOLCHAIN_HOME)/tools
OBJ_DIR := $(TOOLCHAIN_HOME)/obj
GCC_VERSION ?= 4.9.4
BINUTILS_VERSION ?= 2.27
LINUX_VERSION ?= 4.1.49
UCLIBC_VERSION ?= 1.0.30
LIBUNWIND_VERSION ?= 1.8.1
BINUTILS_DIR := $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION)
GCC_DIR := $(SOURCE_DIR)/gcc-$(GCC_VERSION)
UCLIBC_DIR := $(SOURCE_DIR)/uClibc-ng-$(UCLIBC_VERSION)
LINUX_DIR := $(SOURCE_DIR)/linux-$(LINUX_VERSION)
LIBUNWIND_DIR := $(SOURCE_DIR)/libunwind-$(LIBUNWIND_VERSION)
BINUTILS_BUILD_DIR := $(OBJ_DIR)/binutils_build
GCC1_BUILD_DIR := $(OBJ_DIR)/gcc_build-pass1
GCC2_BUILD_DIR := $(OBJ_DIR)/gcc_build-pass2
GCC3_BUILD_DIR := $(OBJ_DIR)/gcc_build-pass3
LINUX_BUILD_DIR := $(OBJ_DIR)/linux-$(LINUX_VERSION)
LIBUNWIND_BUILD_DIR := $(OBJ_DIR)/libunwind-$(LIBUNWIND_VERSION)
UCLIBC_BUILD_DIR := $(OBJ_DIR)/uclibc_build
UCLIBC_HEADER_BUILD_DIR := $(OBJ_DIR)/uclibc_header_build
GCC_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.gz
BINUTILS_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.gz
LINUX_URL := https://www.kernel.org/pub/linux/kernel/v4.x/linux-$(LINUX_VERSION).tar.gz
UCLIBC_URL := https://downloads.uclibc-ng.org/releases/$(UCLIBC_VERSION)/uClibc-ng-$(UCLIBC_VERSION).tar.gz
LIBUNWIND_URL := https://github.com/libunwind/libunwind/releases/download/v$(LIBUNWIND_VERSION)/libunwind-$(LIBUNWIND_VERSION).tar.gz
BUILD_LIB_DIR := $(TOOLCHAIN_HOME)/build_lib
SYSROOT_DIR := $(TOOLCHAIN_HOME)/sysroot
LOG_DIR := $(HOME)/build_toolchain/logs
TEST_DIR := $(TOOLCHAIN_HOME)/test
TEST_CODE := aarch64_test
LINUX_ARCH := arm64
JOBS ?= 
DATE := $(shell date +%Y%m%d)


export PATH
export PATH := $(TOOLS_DIR)/bin:$(PATH)

check: 
	@echo "请修改注册表将windows设为大小写敏感"
	@echo "注册表路径：HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\
	\Session Manager\kernel\obcaseinsensitive，将1改为0"
	@echo "请执行："
	@echo "export PATH MSYS=winsymlinks:nativestrict >> ~/.bashrc"
	@echo "请安装依赖："
	@echo "pacman -Syu"
	@echo "pacman -S make gcc flex texinfo unzip  \
	help2man patch libtool bison autoconf automake \
	base-devel mingw-w64-x86_64-toolchain \
	mingw-w64-x86_64-ncurses ncurses-devel\
	tar gzip xz p7zip coreutils moreutils\
	rsync autoconf diffutils gawk \
	git gperf mingw-w64-x86_64-libunwind"
	@echo "检查完执行 make all"
	@echo -e "\e[31m如果是执行其他的target跳到这，请检查代码\e[0m"

test: init_env download copy init_tar patch binutils
#all: init_env code init binutils pass1-gcc linux uclibc pass2-gcc uclibc_full gcc_full install_env compile_test run_test
aa: init_env download copy init_tar
test_code: install_env compile_test run_test

init_env:
	mkdir -p $(LOG_DIR)
	mkdir -p $(TOOLCHAIN_HOME) $(SOURCE_DIR) $(TOOLS_DIR) \
	$(SYSROOT_DIR) $(SYSROOT_DIR)/usr/include  $(OBJ_DIR) \
	$(BUILD_LIB_DIR) $(TEST_DIR)
	@echo "环境初始化完成，接下来请执行: make init"

code:
	echo "下载源码..."
	@mkdir -p $(SOURCE_DIR)
	@cd $(SOURCE_DIR); 
	@if [ ! -f $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION).tar.gz ]; then \
		wget -nc  $(BINUTILS_URL) -P $(SOURCE_DIR) || { echo "下载 binutils 失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/gcc-$(GCC_VERSION).tar.gz ]; then \
		wget -nc  $(GCC_URL) -P $(SOURCE_DIR) || { echo "下载 gcc 失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/linux-$(LINUX_VERSION).tar.xz ] ; then \
		wget -nc  $(LINUX_URL) -P $(SOURCE_DIR) || { echo "下载 linux 内核源码失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/uclibc-$(UCLIBC_VERSION).tar.gz ]; then \
		wget -nc  $(UCLIBC_URL) -P $(SOURCE_DIR) || { echo "下载 uclibc 失败！"; exit 1; }; \
	fi
	@echo "源码下载完成，接下来请执行: make init"
init_tar: 
	echo "解压源码..."
	@if [ ! -d $(BINUTILS_DIR) ]; then \
		echo "解压 binutils..."; \
		tar -zxvf $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION).tar.gz -C $(SOURCE_DIR) || { echo "解压 binutils 失败！"; exit 1; }; \
	fi
	@if [ ! -d $(GCC_DIR) ]; then \
		echo "解压 gcc..."; \
		tar -zxvf $(SOURCE_DIR)/gcc-$(GCC_VERSION).tar.gz -C $(SOURCE_DIR) || { echo "解压 gcc 失败！"; exit 1; }; \
		cd $(GCC_DIR); \
		contrib/download_prerequisites; \
	fi
	@if [ ! -d $(UCLIBC_DIR) ]; then \
		echo "解压 uclibc..."; \
		tar -zxvf $(SOURCE_DIR)/uClibc-ng-$(UCLIBC_VERSION).tar.gz -C $(SOURCE_DIR) || { echo "解压 uclibc 失败！"; exit 1; }; \
	fi
	@if [ ! -d $(LINUX_DIR) ]; then \
		echo "解压 linux..."; \
		tar -xvvf $(SOURCE_DIR)/linux-$(LINUX_VERSION).tar.gz -C $(SOURCE_DIR) || { echo "解压 linux 失败！"; exit 1; }; \
	fi
	mkdir -p $(TOOLS_DIR); 
	@echo "解压操作完成，并且完成文件夹的初始化，接下来请执行: make binutils"

init: 
	# 检查并解压 binutils
	@if [ ! -d $(BINUTILS_DIR) ]; then \
    echo "解压 binutils..."; \
    7z x -y $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 binutils 失败！"; rm -rf $(BINUTILS_DIR); exit 1; }; \
	fi

	# 检查并解压 gcc
	@if [ ! -d $(GCC_DIR) ]; then \
    echo "解压 gcc..."; \
    7z x -y $(SOURCE_DIR)/gcc-$(GCC_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 gcc 失败！"; rm -rf $(GCC_DIR); exit 1; }; \
	cd $(GCC_DIR); \
	contrib/download_prerequisites; \
	fi

	# 检查并解压 uclibc
	@if [ ! -d $(UCLIBC_DIR) ]; then \
    echo "解压 uclibc..."; \
    7z x -y $(SOURCE_DIR)/uClibc-ng-$(UCLIBC_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 uclibc 失败！"; rm -rf $(UCLIBC_DIR); exit 1; }; \
	fi

	# 检查并解压 linux 内核
	@if [ ! -d $(LINUX_DIR) ]; then \
    echo "解压 linux..."; \
    7z x -y $(SOURCE_DIR)/linux-$(LINUX_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 linux 失败！"; rm -rf $(LINUX_DIR); exit 1; }; \
	fi
	mkdir -p $(TOOLS_DIR); 
	@echo "解压操作完成，并且完成文件夹的初始化，接下来请执行: make binutils"

patch:
	cd $(GCC_DIR) && \
	find "$(WORK_DIR)/gcc/$(GCC_VERSION)/" -name "*.patch" -type f | sort -n | while read -r patch; do \
		echo "应用补丁: $$(basename "$$patch")"; \
		if ! /usr/bin/patch --no-backup-if-mismatch -g0 -F1 -p1 -f -i "$$patch"; then \
			echo "错误：补丁应用失败 - $$patch"; \
			exit 1; \
		fi; \
	done
	cd $(BINUTILS_DIR) && \
	find "$(WORK_DIR)/binutils/$(BINUTILS_VERSION)/" -name "*.patch" -type f | sort -n | while read -r patch; do \
		echo "应用补丁: $$(basename "$$patch")"; \
		if ! /usr/bin/patch --no-backup-if-mismatch -g0 -F1 -p1 -f -i "$$patch"; then \
			echo "错误：补丁应用失败 - $$patch"; \
			exit 1; \
		fi; \
	done
	@echo "所有补丁已成功应用！"


binutils: init
	echo "配置和安装 binutils..."
	if [ -d $(BINUTILS_BUILD_DIR) ]; then \
		rm -rf $(BINUTILS_BUILD_DIR); \
	fi; \
	mkdir -p $(BINUTILS_BUILD_DIR) && cd $(BINUTILS_BUILD_DIR); \
	export LDFLAGS="-L$(BUILD_LIB_DIR)" ;\
	export LDFLAGS_FOR_BUILD="-L$(BUILD_LIB_DIR)" ;\
	export LDFLAGS_FOR_TARGET= "-static";\
	cd $(BINUTILS_BUILD_DIR); \
	$(BINUTILS_DIR)/configure --target=$(TARGET) --prefix=$(TOOLS_DIR) \
		--with-sysroot=$(SYSROOT_DIR) \
		--disable-multilib \
		--enable-ld=yes \
		--enable-gold=no \
		--disable-sim \
		--disable-gdb \
		--disable-nls \
		--without-zstd \
		--disable-werror \
		-v 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-configure-$(DATE).log || { echo "配置 binutils 失败！"; exit 1; }; \
	make $(JOBS) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-make-$(DATE).log || { echo "构建 binutils 失败！"; exit 1; }; \
	make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-make-install-$(DATE).log || { echo "安装 binutils 失败！"; exit 1; }; \
	echo "binutils 安装完成，接下来请执行: make linux"

linux: init
	echo "安装 Linux 内核头文件..."
	if [ -d $(LINUX_BUILD_DIR) ]; then \
		rm -rf $(LINUX_BUILD_DIR); \
	fi; 
	cp -r $(LINUX_DIR) $(OBJ_DIR); \
	mkdir -p $(SYSROOT_DIR)/usr; \
	cd $(LINUX_BUILD_DIR); \
	make clean; \
	make ARCH=$(LINUX_ARCH) INSTALL_HDR_PATH=$(SYSROOT_DIR)/usr \
	CROSS_COMPILE=$(TARGET) CROSS_COMPILE=$(TARGET)- headers_install \
	2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/headers_install-$(DATE).log || \
	(echo "安装 Linux 内核头文件失败！" && exit 1)
	echo "Linux 内核头文件安装完成，接下来请执行: make pass1-gcc"

pass1-gcc: init
	echo "配置和安装 pass1-gcc..."
	if [ -d $(GCC1_BUILD_DIR) ]; then \
		rm -rf $(GCC1_BUILD_DIR); \
	fi; 
	mkdir -p $(GCC1_BUILD_DIR) && cd $(GCC1_BUILD_DIR); \
	export LDFLAGS="-L$(BUILD_LIB_DIR)" ;\
	export LDFLAGS_FOR_TARGET= "-static";\
	cd $(GCC1_BUILD_DIR); \
	$(GCC_DIR)/configure --target=$(TARGET) --prefix=$(TOOLS_DIR) \
				--disable-multilib \
				--disable-libmudflap \
				--disable-libstdcxx \
				--with-newlib \
				--disable-nls \
				--disable-shared \
				--disable-libgomp \
				--disable-libmudflap \
				--disable-libquadmath \
				--disable-__cxa_atexit \
				--disable-tm-clone-registry\
				--with-cloog=no\
				--with-isl=no\
				--with-system-zlib\
				--disable-lto\
				--disable-plugin\
				--disable-nls\
				--disable-libquadmath-support \
				--enable-threads=no\
				--enable-languages=c \
				--disable-werror \
				2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-configure-$(DATE).log || { echo "配置 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC1_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make configure-gcc configure-libcpp configure-build-libiberty 2>&1 | ts '[%Y-%m-%d %H:%M:%S]'  | tee -a $(LOG_DIR)/pass1-configure-gcc-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC1_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make all-libcpp all-build-libcpp all-build-libiberty 2>&1 | ts '[%Y-%m-%d %H:%M:%S]'  | tee -a $(LOG_DIR)/pass1-all-libcpp-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC1_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make configure-libdecnumber 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-libdecnumber-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC1_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make -C libdecnumber libdecnumber.a 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-libdecnumber.a-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC1_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make configure-libbacktrace 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-configure-libbacktrace-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC1_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make -C libbacktrace 2>&1 | ts '[%Y-%m-%d %H:%M:%S]'  | tee -a $(LOG_DIR)/pass1-libbacktrace-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC1_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make -C gcc libgcc.mvars 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-libgcc.mvars-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC1_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make all-gcc all-target-libgcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-make-all-gcc-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC1_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make install-gcc install-target-libgcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-make-install-gcc-$(DATE).log || { echo "安装 pass1-gcc 失败！"; exit 1; }; \
	

	echo "安装 C/C++ 编译器完成，接下来请执行: make uclibc"

#cp -r $(TOOLS_DIR)/lib $(SYSROOT_DIR)/ 
uclibc: init
	echo "配置和安装 uclibc 头文件和启动文件..." 
	if [ -d $(UCLIBC_HEADER_BUILD_DIR) ]; then \
		rm -rf $(UCLIBC_HEADER_BUILD_DIR); \
	fi; 
	mkdir -p $(UCLIBC_HEADER_BUILD_DIR) && cd $(UCLIBC_HEADER_BUILD_DIR); \
	LD_LIBRARY_PATH_old="$$LD_LIBRARY_PATH" ;\
	unset LD_LIBRARY_PATH ;\
	cd $(UCLIBC_HEADER_BUILD_DIR); \
	cp -av $(UCLIBC_DIR)/* $(UCLIBC_HEADER_BUILD_DIR) ;\
	cp $(WORK_DIR)/.config $(UCLIBC_HEADER_BUILD_DIR);\
	cp $(UCLIBC_HEADER_BUILD_DIR)/.config $(UCLIBC_HEADER_BUILD_DIR)/.config.copy;\
	cd $(UCLIBC_HEADER_BUILD_DIR) ;\
	make CROSS_COMPILE=$(TARGET)- PREFIX=$(SYSROOT_DIR) \
	STRIPTOOL=true UCLIBC_EXTRA_CFLAGS=-pipe olddefconfig \
	-v 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/uclibc-configure-$(DATE).log || { echo "配置 uclibc 失败！"; exit 1; }; \

	cd $(UCLIBC_HEADER_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make CROSS_COMPILE=$(TARGET)- PREFIX=$(SYSROOT_DIR) \
	STRIPTOOL=true \
	pregen 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/uclibc-install-headers-$(DATE).log || { echo "安装 uclibc headers 失败！" ; exit 1;}; \

	cd $(UCLIBC_HEADER_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make CROSS_COMPILE=$(TARGET)- PREFIX=$(SYSROOT_DIR) \
	STRIPTOOL=true UCLIBC_EXTRA_CFLAGS=-pipe all  2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/uclibc-all-$(DATE).log || { echo "安装 uclibc all 失败！" ; exit 1;}; \

	cd $(UCLIBC_HEADER_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make CROSS_COMPILE=$(TARGET)- PREFIX=$(SYSROOT_DIR) \
	STRIPTOOL=true UCLIBC_EXTRA_CFLAGS=-pipe install install_utils \
	2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/uclibc-install-utils-$(DATE).log || { echo "安装 uclibc install_utils 失败！" ; exit 1;}; \
	export LD_LIBRARY_PATH="$$LD_LIBRARY_PATH_old";
	echo "安装标准 C 库头文件和启动文件成功，接下来请执行: make pass2-gcc"
pass2-gcc: init
	echo "配置和安装 pass2-gcc..."
	if [ -d $(GCC2_BUILD_DIR) ]; then \
		rm -rf $(GCC2_BUILD_DIR); \
	fi; 
	mkdir -p $(GCC2_BUILD_DIR) && cd $(GCC2_BUILD_DIR); \
	export LDFLAGS="-L$(BUILD_LIB_DIR)" ;\
	export LDFLAGS_FOR_TARGET= "-static";\
	cd $(GCC2_BUILD_DIR); \
	$(GCC_DIR)/configure --target=$(TARGET) --prefix=$(TOOLS_DIR) \
				--with-sysroot=$(SYSROOT_DIR) \
				--disable-multilib \
				--disable-libsanitizer \
				--disable-lto --disable-libmudflap \
				--disable-libquadmath \
				--disable-libquadmath-support \
				--disable-libssp --disable-nls \
				--enable-languages=c \
				--disable-libgomp \
				--with-ppl=no \
				--with-isl=no \
				--with-cloog=no \
				--with-libelf=no \
				--disable-libatomic \
				--disable-werror \
				--disable-__cxa_atexit \
				--disable-libmpx \
				--without-zstd \
				--disable-plugin\
				--disable-tm-clone-registry \
				--enable-libunwind-exceptions \
				--with-libunwind=yes \
				--enable-shared \
				--disable-werror \
				2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass2-configure-$(DATE).log || { echo "配置 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC2_BUILD_DIR); \
	export CFLAGS="-fPIC -Os";\
	PATH="$(TOOLS_DIR)/bin:$$PATH" make $(JOBS)  2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass2-make-all-gcc-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	
	echo "安装 C/C++ 编译器完成，接下来请执行: make uclibc_full"
cc:
	PATH="$(TOOLS_DIR)/bin:$$PATH" make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass2-make-install-gcc-$(DATE).log || { echo "安装 pass1-gcc 失败！"; exit 1; }; \
	
	cp -r $(TOOLS_DIR)/lib $(SYSROOT_DIR)/ ; \
	cp -r $(TOOLS_DIR)/$(TARGET)/lib $(SYSROOT_DIR)/ ; \
	cp -r $(TOOLS_DIR)/$(TARGET)/lib64 $(SYSROOT_DIR)/; \
uclibc_full: init
	echo "安装完整uclibc."
	if [ -d $(UCLIBC_HEADER_BUILD_DIR) ]; then \
		rm -rf $(UCLIBC_HEADER_BUILD_DIR); \
	fi; 
	mkdir -p $(UCLIBC_HEADER_BUILD_DIR) && cd $(UCLIBC_HEADER_BUILD_DIR); \
	LD_LIBRARY_PATH_old="$$LD_LIBRARY_PATH" ;\
	unset LD_LIBRARY_PATH ;\
	cd $(UCLIBC_HEADER_BUILD_DIR); \
	cp -av $(UCLIBC_DIR)/* $(UCLIBC_HEADER_BUILD_DIR) ;\
	cp $(WORK_DIR)/.config $(UCLIBC_HEADER_BUILD_DIR);\
	cp $(UCLIBC_HEADER_BUILD_DIR)/.config $(UCLIBC_HEADER_BUILD_DIR)/.config.copy;\
	cd $(UCLIBC_HEADER_BUILD_DIR) ;\
	make CROSS_COMPILE=$(TARGET)- PREFIX=$(SYSROOT_DIR) \
	STRIPTOOL=true olddefconfig \
	-v 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/uclibc-configure-$(DATE).log || { echo "配置 uclibc 失败！"; exit 1; }; \

	cd $(UCLIBC_HEADER_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make CROSS_COMPILE=$(TARGET)- PREFIX=$(SYSROOT_DIR) \
	STRIPTOOL=true UCLIBC_EXTRA_CFLAGS=-pipe \
	pregen 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/uclibc-install-headers-$(DATE).log || { echo "安装 uclibc headers 失败！" ; exit 1;}; \

	cd $(UCLIBC_HEADER_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make CROSS_COMPILE=$(TARGET)- PREFIX=$(SYSROOT_DIR) \
	STRIPTOOL=true UCLIBC_EXTRA_CFLAGS=-pipe all  2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/uclibc-all-$(DATE).log || { echo "安装 uclibc all 失败！" ; exit 1;}; \

	cd $(UCLIBC_HEADER_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make CROSS_COMPILE=$(TARGET)- PREFIX=$(SYSROOT_DIR) \
	STRIPTOOL=true UCLIBC_EXTRA_CFLAGS=-pipe install install_utils \
	2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/uclibc-install-utils-$(DATE).log || { echo "安装 uclibc install_utils 失败！" ; exit 1;}; \
	export LD_LIBRARY_PATH="$$LD_LIBRARY_PATH_old";
	echo "安装完整uclibc完成,接下来请执行: make gcc_full"

gcc_full: init
	echo "安装完整gcc..."
	if [ -d $(GCC3_BUILD_DIR) ]; then \
		rm -rf $(GCC3_BUILD_DIR); \
	fi; 
	mkdir -p $(GCC3_BUILD_DIR) && cd $(GCC3_BUILD_DIR); \
	cd $(GCC3_BUILD_DIR); \
	export LDFLAGS="-L$(BUILD_LIB_DIR)" ;\
	export LDFLAGS_FOR_TARGET= "-static";\
	cd $(GCC3_BUILD_DIR); \
	$(GCC_DIR)/configure --target=$(TARGET) --prefix=$(TOOLS_DIR) \
				--with-sysroot=$(SYSROOT_DIR) \
				--disable-multilib \
				--disable-libgomp \
				--disable-libmudflap \
				--disable-libsanitizer \
				--disable-lto \
				--disable-libquadmath \
				--disable-libquadmath-support \
				--disable-libssp --disable-nls \
				--enable-languages=c,c++,go \
				--enable-threads=posix \
				--disable-__cxa_atexit \
				--disable-tm-clone-registry \
				--without-zstd \
				--with-system-zlib \
				--disable-plugin \
				--with-ppl=no \
				--with-isl=no \
				--with-cloog=no \
				--with-libelf=no \
				--enable-libunwind-exceptions \
				--with-libunwind=yes \
				--enable-shared \
				--disable-werror \
				2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/full_gcc-configure-$(DATE).log || { echo "配置完整gcc失败！"; exit 1; }; \
	cd $(GCC3_BUILD_DIR); \
	export CXXFLAGS="-std=c++03";\
	PATH="$(TOOLS_DIR)/bin:$$PATH" make $(JOBS) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-gcc-make-$(DATE).log || { echo "编译 all-uclibc 失败！"; exit 1; }; \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-gcc-install-$(DATE).log || { echo "安装 all-uclibc 失败！"; exit 1; }; \
	echo "安装完整gcc完成，接下来请执行: make install_env"

install_env: 
	echo "安装完成，配置环境变量..."
	@if ! grep -q "${TOOLS_DIR}/bin" ~/.bashrc; then \
		echo "export PATH=${TOOLS_DIR}/bin:\$$PATH" >> ~/.bashrc; \
	fi
	. ~/.bashrc;
	echo "环境变量配置完成! 请手动执行: source ~/.bashrc"

compile_test:
	@echo "Compiling test code with $(TARGET)-gcc..." | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
	$(TARGET)-gcc  -o test_code/$(TEST_CODE)c test_code/$(TEST_CODE).c | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log

	$(TARGET)-g++ -o test_code/$(TEST_CODE)cpp test_code/$(TEST_CODE).cpp \
	-Wl,-rpath-link=$(TOOLS_DIR)/$(TARGET)/lib64 \
	-L$(TOOLS_DIR)/$(TARGET)/lib64 -lunwind -lgcc_s -lpthread  | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log

	$(TARGET)-gccgo -o test_code/$(TEST_CODE)go test_code/$(TEST_CODE).go \
	-Wl,-rpath-link=$(TOOLS_DIR)/$(TARGET)/lib64 \
	-L$(TOOLS_DIR)/$(TARGET)/lib64 -lunwind -lgcc_s -lpthread  | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log

	$(TARGET)-gccgo -o test_code/$(TEST_CODE)go_static test_code/$(TEST_CODE).go \
	-static -L$(TOOLS_DIR)/$(TARGET)/lib64 \
	$(TOOLS_DIR)/$(TARGET)/lib64/libunwind.a -lgcc -lpthread   | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
	@echo "Compilation completed."

file:
	@echo "display file type" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/file-target-$(DATE).log
	file test_code/$(TEST_CODE)c | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/file-target-$(DATE).log
	file test_code/$(TEST_CODE)cpp | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/file-target-$(DATE).log
	file test_code/$(TEST_CODE)go | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/file-target-$(DATE).log
	file test_code/$(TEST_CODE)go_static | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/file-target-$(DATE).log

ldd:
	@echo "display ldd" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/ldd-target-$(DATE).log
	ldd test_code/$(TEST_CODE)c | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/ldd-target-$(DATE).log
	ldd test_code/$(TEST_CODE)cpp | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/ldd-target-$(DATE).log
	ldd test_code/$(TEST_CODE)go | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/ldd-target-$(DATE).log
#ldd test_code/$(TEST_CODE)_static > static_ldd.log 2>&1 | tee -a $(LOG_DIR)/ldd-target.log
run_test:
	@echo "Running compiled binary with qemu-aarch64..." | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	@echo "begin first test" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	qemu-aarch64 -L $(TOOLS_DIR)/$(TARGET) test_code/$(TEST_CODE) | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	@echo "=========================================" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	@echo "begin static test" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	qemu-aarch64 -L $(TOOLS_DIR)/$(TARGET) test_code/$(TEST_CODE)_static | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	@echo "Test execution completed." | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log

libunwind:
	if [ -d $(LIBUNWIND_BUILD_DIR) ]; then \
		rm -rf $(LIBUNWIND_BUILD_DIR); \
	fi; 
	mkdir -p $(LIBUNWIND_BUILD_DIR);
	@if [ ! -f $(SOURCE_DIR)/libunwind-$(LIBUNWIND_VERSION).tar.gz ]; then \
		wget $(LIBUNWIND_URL) -P $(SOURCE_DIR) \
		|| { echo "下载 libunwind 失败！"; exit 1; }; \
	fi
	@if [ ! -d $(LIBUNWIND_DIR) ]; then \
    	echo "解压 libunwind..."; \
    	7z x -y $(SOURCE_DIR)/libunwind-$(LIBUNWIND_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 libunwind 失败！"; rm -rf $(LIBUNWIND_DIR); exit 1; }; \
		patch $(LIBUNWIND_DIR)/src/aarch64/Gos-linux.c < Gos-linux.patch;\
	fi
	
	cd $(LIBUNWIND_BUILD_DIR);\
	SYSROOT="$(SYSROOT_DIR)";\
	CC="$(TARGET)-gcc" \
   	CXX="$(TARGET)-g++" \
	CFLAGS="-fPIC -I$(SYSROOT_DIR)/usr/include -D_GNU_SOURCE" \
	LDFLAGS="-L$(TOOLS_DIR)/$(TARGET)/lib64" \
	$(LIBUNWIND_DIR)/configure   --host=$(TARGET)  --enable-static --enable-shared \
	--prefix=$(TOOLS_DIR)/$(TARGET)  --libdir=$(TOOLS_DIR)/$(TARGET)/lib64 --disable-tests --with-sysroot=$(SYSROOT_DIR);\
	make && make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/libunwind-install-$(DATE).log || { echo "安装 libunwind 失败！"; exit 1; }; \

#--libdir=$(SYSROOT_DIR)/usr/lib64
libunwind_clean:
	cd $(LIBUNWIND_BUILD_DIR); \
	make clean; \

clean:
	echo "删除无用文件..."
	@cd $(SOURCE_DIR); \
	rm -rf $(OBJ_DIR) $(TOOLS_DIR) \
	echo "删除无用文件完成，接下来请执行: make init"

delete:
	echo "删除全部构建..."
	@cd $(TOOLCHAIN_HOME); 
	rm -rf $(TOOLCHAIN_HOME)
	echo "删除全部构建完成，接下来请执行: make all"


download:
	echo "下载源码..."
	@if [ ! -f ./binutils-$(BINUTILS_VERSION).tar.gz ]; then \
		wget $(BINUTILS_URL) || { echo "下载 binutils 失败！"; exit 1; }; \
	fi
	@if [ ! -f ./gcc-$(GCC_VERSION).tar.gz ]; then \
		wget $(GCC_URL) || { echo "下载 gcc 失败！"; exit 1; }; \
	fi
	@if [ ! -f ./linux-$(LINUX_VERSION).tar.gz ]; then \
		wget $(LINUX_URL) || { echo "下载 linux 内核源码失败！"; exit 1; }; \
	fi
	@if [ ! -f ./uClibc-ng-$(UCLIBC_VERSION).tar.gz ]; then \
		wget $(UCLIBC_URL) || { echo "下载 uclibc 失败！"; exit 1; }; \
	fi


copy:
	@mkdir -p $(SOURCE_DIR)
	cp $(HOME)/build_toolchain/*.tar.gz $(SOURCE_DIR)


rm_log:
	find $(LOG_DIR) -name "*.log" -mtime +1 -exec rm -rf {} \;
