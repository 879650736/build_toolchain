# 定义变量
SHELL := /bin/bash
TARGET := aarch64-unknown-linux-gnu
TOOLCHAIN_HOME := $(HOME)/aarch-gcc-build_a
SOURCE_DIR := $(TOOLCHAIN_HOME)/source
TOOLS_DIR := $(TOOLCHAIN_HOME)/tools
OBJ_DIR := $(TOOLCHAIN_HOME)/obj
GCC_VERSION ?= 13.2.0
BINUTILS_VERSION ?= 2.37
LINUX_VERSION ?= 6.1.10
GLIBC_VERSION ?= 2.35
BINUTILS_DIR := $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION)
GCC_DIR := $(SOURCE_DIR)/gcc-$(GCC_VERSION)
GLIBC_DIR := $(SOURCE_DIR)/glibc-$(GLIBC_VERSION)
GLIBC_PORTS_DIR := $(SOURCE_DIR)/glibc-ports-$(GLIBC_VERSION)
LINUX_DIR := $(SOURCE_DIR)/linux-$(LINUX_VERSION)
BINUTILS_BUILD_DIR := $(OBJ_DIR)/binutils_build
GCC1_BUILD_DIR := $(OBJ_DIR)/gcc_build-pass1
GCC2_BUILD_DIR := $(OBJ_DIR)/gcc_build-pass2
GCC3_BUILD_DIR := $(OBJ_DIR)/gcc_build-pass3
LINUX_BUILD_DIR := $(OBJ_DIR)/linux-$(LINUX_VERSION)
GLIBC_BUILD_DIR := $(OBJ_DIR)/glibc_build
GLIBC_HEADER_BUILD_DIR := $(OBJ_DIR)/glibc_header_build
GLIBC_PORTS_BUILD_DIR := $(OBJ_DIR)/glibc_ports_build
GCC_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.gz
BINUTILS_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.gz
LINUX_URL := https://ftp.sjtu.edu.cn/sites/ftp.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.xz
LINUX_SIGN_URL := https://ftp.sjtu.edu.cn/sites/ftp.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.sign
GLIBC_URL := https://ftp.gnu.org/pub/gnu/glibc/glibc-$(GLIBC_VERSION).tar.gz
GLIBC_PORTS_URL := https://ftp.gnu.org/pub/gnu/glibc/glibc-ports-$(GLIBC_VERSION).tar.gz
LIBUNWIND_URL := https://github.com/libunwind/libunwind/releases/download/v$(LIBUNWIND_VERSION)/libunwind-$(LIBUNWIND_VERSION).tar.gz
SYSROOT_DIR := $(TOOLCHAIN_HOME)/sysroot
LOG_DIR := $(HOME)/ewxb-gcc-cross-compiler-builder/logs
TEST_CODE := aarch64_test
#glibc版本小于2.16时，需要改为--enable-add-ons=nptl,ports
ADDONS := --enable-add-ons
JOBS ?= 
DATE := $(shell date +%Y%m%d)


export PATH
export PATH := $(TOOLS_DIR)/bin:$(PATH)

test1: run_test
test: init_env download copy init binutils 
all: init_env code init linux binutils pass1-gcc glibc libgcc all-glibc libstdc++ install_env compile_test run_test

test_code: install_env compile_test run_test

init_env:
	mkdir -p $(LOG_DIR)
	mkdir -p $(TOOLCHAIN_HOME) $(SOURCE_DIR) $(TOOLS_DIR) \
	$(SYSROOT_DIR) $(SYSROOT_DIR)/usr/include 
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
	@if [ ! -f $(SOURCE_DIR)/glibc-$(GLIBC_VERSION).tar.gz ]; then \
		wget -nc  $(GLIBC_URL) -P $(SOURCE_DIR) || { echo "下载 glibc 失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/glibc-prots-$(GLIBC_VERSION).tar.gz ] ; then \
		wget -nc  $(GLIBC_URL) -P $(SOURCE_DIR) || { echo "下载 glibc-ports 失败！"; exit 1; }; \
	fi
	@echo "源码下载完成，接下来请执行: make init"
code1:
	echo "下载源码..."
	@mkdir -p $(SOURCE_DIR)
	@cd $(SOURCE_DIR); 
	@if [ ! -f $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION).tar.gz ] || [ ! -f $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION).tar.gz.sig ]; then \
		wget -nc  $(BINUTILS_URL) -P $(SOURCE_DIR) || { echo "下载 binutils 失败！"; exit 1; }; \
		wget -nc  $(BINUTILS_URL).sig -P $(SOURCE_DIR) || { echo "下载 binutils 签名文件失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/gcc-$(GCC_VERSION).tar.gz ] || [ ! -f $(SOURCE_DIR)/gcc-$(GCC_VERSION).tar.gz.sig ]; then \
		wget -nc  $(GCC_URL) -P $(SOURCE_DIR) || { echo "下载 gcc 失败！"; exit 1; }; \
		wget -nc  $(GCC_URL).sig -P $(SOURCE_DIR) || { echo "下载 gcc 签名文件失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/linux-$(LINUX_VERSION).tar.xz ] || [ ! -f $(SOURCE_DIR)/linux-$(LINUX_VERSION).tar.xz.sign ]; then \
		wget -nc  $(LINUX_URL) -P $(SOURCE_DIR) || { echo "下载 linux 内核源码失败！"; exit 1; }; \
		wget -nc  $(LINUX_SIGN_URL) -P $(SOURCE_DIR) || { echo "下载 linux 签名文件失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/glibc-$(GLIBC_VERSION).tar.gz ] || [ ! -f $(SOURCE_DIR)/glibc-$(GLIBC_VERSION).tar.gz.sig ]; then \
		wget -nc  $(GLIBC_URL) -P $(SOURCE_DIR) || { echo "下载 glibc 失败！"; exit 1; }; \
		wget -nc  $(GLIBC_URL).sig -P $(SOURCE_DIR) || { echo "下载 glibc 签名文件失败！"; exit 1; }; \
	fi
	@echo "源码下载完成，接下来请执行: make init"
check:
	@echo "检查源码签名..."
# download the Gnu keyring and import it
	curl http://ftp.gnu.org/gnu/gnu-keyring.gpg -O
	gpg --import gnu-keyring.gpg

	@cd $(SOURCE_DIR); \
	gpg --verify binutils-$(BINUTILS_VERSION).tar.gz.sig || { echo "binutils 签名验证失败！"; exit 1; }; \
	gpg --verify gcc-$(GCC_VERSION).tar.gz.sig || { echo "gcc 签名验证失败！"; exit 1; }; \
	gpg --verify glibc-$(GLIBC_VERSION).tar.gz.sig || { echo "glibc 签名验证失败！"; exit 1; }; 
# gpg --verify linux-$(LINUX_VERSION).tar.xz.sign || { echo "linux 签名验证失败！"; exit 1; }; \
	@echo "源码签名验证通过，接下来请执行: make init"

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
	@if [ ! -d $(GLIBC_DIR) ]; then \
		echo "解压 glibc..."; \
		tar -zxvf $(SOURCE_DIR)/glibc-$(GLIBC_VERSION).tar.gz -C $(SOURCE_DIR) || { echo "解压 glibc 失败！"; exit 1; }; \
	fi
	@if [ ! -d $(LINUX_DIR) ]; then \
		echo "解压 linux..."; \
		tar -xvJf $(SOURCE_DIR)/linux-$(LINUX_VERSION).tar.xz -C $(SOURCE_DIR) || { echo "解压 linux 失败！"; exit 1; }; \
	fi
	mkdir -p $(TOOLS_DIR); 
	@echo "解压操作完成，并且完成文件夹的初始化，接下来请执行: make linux"

init_tar1: 
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
	@if [ ! -d $(GLIBC_DIR) ]; then \
		echo "解压 glibc..."; \
		tar -zxvf $(SOURCE_DIR)/glibc-$(GLIBC_VERSION).tar.gz -C $(SOURCE_DIR) || { echo "解压 glibc 失败！"; exit 1; }; \
	fi
	@if [ ! -d $(GLIBC_PORTS_DIR) ]; then \
		echo "解压 glibc-ports..."; \
		tar -zxvf $(SOURCE_DIR)/glibc-port-$(GLIBC_VERSION).tar.gz -C $(SOURCE_DIR) || { echo "解压 glibc-port 失败！"; exit 1; }; \
		ln -s glibc-port-$(GLIBC_VERSION) ports; \
	fi
	@if [ ! -d $(LINUX_DIR) ]; then \
		echo "解压 linux..."; \
		tar -xvJf $(SOURCE_DIR)/linux-$(LINUX_VERSION).tar.xz -C $(SOURCE_DIR) || { echo "解压 linux 失败！"; exit 1; }; \
	fi
	mkdir -p $(TOOLS_DIR); 
	@echo "解压操作完成，并且完成文件夹的初始化，接下来请执行: make linux"

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

# 检查并解压 glibc-ports
	@if [ ! -d $(GLIBC_PROTS_DIR) ]; then \
    echo "解压 glibc-ports..."; \
    7z x -y $(SOURCE_DIR)/glibc-ports-$(GLIBC_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 glibc-ports 失败！"; rm -rf $(GLIBC_DIR); exit 1; }; \
	ln -s glibc-port-$(GLIBC_VERSION) ports; \
	fi

# 检查并解压 glibc
	@if [ ! -d $(GLIBC_DIR) ]; then \
    echo "解压 glibc..."; \
    7z x -y $(SOURCE_DIR)/glibc-$(GLIBC_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 glibc 失败！"; rm -rf $(GLIBC_DIR); exit 1; }; \
	fi


# 检查并解压 linux 内核
	@if [ ! -d $(LINUX_DIR) ]; then \
    echo "解压 linux..."; \
    7z x -y $(SOURCE_DIR)/linux-$(LINUX_VERSION).tar.xz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 linux 失败！"; rm -rf $(LINUX_DIR); exit 1; }; \
	fi
	mkdir -p $(TOOLS_DIR); 
	@echo "解压操作完成，并且完成文件夹的初始化，接下来请执行: make linux"

aaa:
	cd $(GCC_DIR); \
	contrib/download_prerequisites;

binutils: init
	echo "配置和安装 binutils..."
	if [ -d $(BINUTILS_BUILD_DIR) ]; then \
		rm -rf $(BINUTILS_BUILD_DIR); \
	fi; \
	mkdir -p $(BINUTILS_BUILD_DIR) && cd $(BINUTILS_BUILD_DIR); \
	$(BINUTILS_DIR)/configure --target=$(TARGET) --prefix=$(TOOLS_DIR) \
		--with-sysroot=$(SYSROOT_DIR) \
		--disable-multilib \
		--disable-werror \
		--with-arch=armv8-a \
		-v 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-configure-$(DATE).log || { echo "配置 binutils 失败！"; exit 1; }; \
	make $(JOBS) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-make-$(DATE).log || { echo "构建 binutils 失败！"; exit 1; }; \
	make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-make-install-$(DATE).log || { echo "安装 binutils 失败！"; exit 1; }; \
	echo "binutils 安装完成，接下来请执行: make pass1-gcc"

pass1-gcc: init
	echo "配置和安装 pass1-gcc..."
	if [ -d $(GCC1_BUILD_DIR) ]; then \
		rm -rf $(GCC1_BUILD_DIR); \
	fi; 
	mkdir -p $(GCC1_BUILD_DIR) && cd $(GCC1_BUILD_DIR); \
	$(GCC_DIR)/configure --target=$(TARGET) --prefix=$(TOOLS_DIR) \
				--disable-multilib \
				--disable-libsanitizer \
				--disable-lto --disable-libmudflap \
				--with-newlib \
				--disable-nls \
				--disable-libgcc \
				--disable-shared \
				--disable-threads \
				--disable-libssp \
				--disable-libgomp \
				--disable-libmudflap \
				--disable-libquadmath \
				--disable-libquadmath-support \
				--enable-languages=c \
				--without-headers \
				--with-arch=armv8-a  2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-configure-$(DATE).log || { echo "配置 pass1-gcc 失败！"; exit 1; }; \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make $(JOBS) all-gcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-make-all-gcc-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make install-gcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-make-install-gcc-$(DATE).log || { echo "安装 pass1-gcc 失败！"; exit 1; }; \
	echo "安装 C/C++ 编译器完成，接下来请执行: make linux"

linux: init
	echo "安装 Linux 内核头文件..."
	if [ -d $(LINUX_BUILD_DIR) ]; then \
		rm -rf $(LINUX_BUILD_DIR); \
	fi; 
	cp -r $(LINUX_DIR) $(OBJ_DIR)
	mkdir -p $(SYSROOT_DIR)/usr
	cd $(LINUX_BUILD_DIR); \
	make clean; \
	make ARCH=arm64 INSTALL_HDR_PATH=$(SYSROOT_DIR)/usr \
	CROSS_COMPILE=$(TARGET) headers_install \
	2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/headers_install-$(DATE).log || \
	(echo "安装 Linux 内核头文件失败！" && exit 1)
	echo "Linux 内核头文件安装完成，接下来请执行: make glibc"


glibc: init
	echo "配置和安装 glibc 头文件和启动文件..." 
	if [ -d $(GLIBC_HEADER_BUILD_DIR) ]; then \
		rm -rf $(GLIBC_HEADER_BUILD_DIR); \
	fi; 
	mkdir -p $(GLIBC_HEADER_BUILD_DIR) && cd $(GLIBC_HEADER_BUILD_DIR); \
	LD_LIBRARY_PATH_old="$$LD_LIBRARY_PATH" ;\
	unset LD_LIBRARY_PATH ;\
	cd $(GLIBC_HEADER_BUILD_DIR); \
	BUILD_CC=gcc \
	CC=$(TOOLS_DIR)/bin/$(TARGET)-gcc \
	CXX=$(TOOLS_DIR)/bin/$(TARGET)-g++ \
	AR=$(TOOLS_DIR)/bin/$(TARGET)-ar \
	RANLIB=$(TOOLS_DIR)/bin/$(TARGET)-ranlib \
	$(GLIBC_DIR)/configure \
		--host=$(TARGET) \
		--target=$(TARGET) \
		--prefix=/usr \
		--with-headers=$(SYSROOT_DIR)/usr/include \
		--with-binutils=$(TOOLS_DIR)/$(TARGET)/bin \
		$(ADDONS)\
		--enable-kernel=$(LINUX_VERSION) \
		--with-arch=armv8-a \
		--disable-multilib \
		--disable-profile \
		--disable-werror \
		--enable-force-unwind \
		libc_cv_ctors_header=yes \
		libc_cv_forced_unwind=yes \
		libc_cv_gcc_builtin_expect=yes \
		libc_cv_c_cleanup=yes \
		-v 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-configure-$(DATE).log || { echo "配置 glibc 失败！"; exit 1; }; \
	make install-bootstrap-headers=yes install-headers install_root=$(SYSROOT_DIR) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-install-headers-$(DATE).log || { echo "安装 glibc headers 失败！" ; exit 1;}; \
	mkdir -p $(SYSROOT_DIR)/usr/lib; \
	make $(JOBS) csu/subdir_lib 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-make-csu-$(DATE).log || { \
	echo "编译 glibc 启动文件失败！" >&2; \
	exit 1; \
	}; \
	cd $(GLIBC_HEADER_BUILD_DIR);\
	cp -r csu/crt1.o csu/crti.o csu/crtn.o $(SYSROOT_DIR)/usr/lib; \
	$(TOOLS_DIR)/bin/$(TARGET)-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $(SYSROOT_DIR)/usr/lib/libc.so 2>&1 \
	| ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-create-libc-$(DATE).log;\

	touch $(SYSROOT_DIR)/usr/include/gnu/stubs.h; \
	
	export LD_LIBRARY_PATH="$$LD_LIBRARY_PATH_old";

	echo "安装标准 C 库头文件和启动文件成功，接下来请执行: make pass2-gcc"


pass2-gcc: init
	echo "配置和安装 pass2-gcc..."
	if [ -d $(GCC2_BUILD_DIR) ]; then \
		rm -rf $(GCC2_BUILD_DIR); \
	fi; 
	mkdir -p $(GCC2_BUILD_DIR) && cd $(GCC2_BUILD_DIR); \
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
				--with-arch=armv8-a  2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass2-configure-$(DATE).log || { echo "配置 pass1-gcc 失败！"; exit 1; }; \
	cd $(GCC2_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make $(JOBS)  2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass2-make-all-gcc-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass2-make-install-gcc-$(DATE).log || { echo "安装 pass1-gcc 失败！"; exit 1; }; \
	echo "安装 C/C++ 编译器完成，接下来请执行: make glibc_full"

glibc_full: init
	echo "安装完整glibc."
	if [ -d $(GLIBC_BUILD_DIR) ]; then \
		rm -rf $(GLIBC_BUILD_DIR); \
	fi; 
	mkdir -p $(GLIBC_BUILD_DIR) && cd $(GLIBC_BUILD_DIR); \
	LD_LIBRARY_PATH_old="$$LD_LIBRARY_PATH";\
	unset LD_LIBRARY_PATH;\
	cd $(GLIBC_BUILD_DIR); \
	BUILD_CC=gcc \
	CC=$(TOOLS_DIR)/bin/$(TARGET)-gcc \
	CXX=$(TOOLS_DIR)/bin/$(TARGET)-g++ \
	AR=$(TOOLS_DIR)/bin/$(TARGET)-ar \
	RANLIB=$(TOOLS_DIR)/bin/$(TARGET)-ranlib \
	$(GLIBC_DIR)/configure \
				--prefix=/usr \
				--host=$(TARGET) \
				--disable-profile \
				--without-gd \
				--without-cvs \
				--disable-werror
				$(ADDONS) \
				--enable-kernel=$(LINUX_VERSION) \
				libc_cv_forced_unwind=yes 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/full_glibc-configure-$(DATE).log || { echo "配置完整glibc失败！"; exit 1; }; \
	cd $(GLIBC_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make $(JOBS)  2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/full_glibc-$(DATE).log || { echo "编译完整glibc失败！"; exit 1; }; \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make install install_root=$(SYSROOT_DIR) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/install-full_glibc-$(DATE).log || { echo "安装完整glibc失败！"; exit 1; }; \
	
	export LD_LIBRARY_PATH="$$LD_LIBRARY_PATH_old";\
	echo "安装完整glibc完成,接下来请执行: make gcc_full"

gcc_full: init
	echo "安装完整gcc..."
	if [ -d $(GCC3_BUILD_DIR) ]; then \
		rm -rf $(GCC3_BUILD_DIR); \
	fi; 
	mkdir -p $(GCC3_BUILD_DIR) && cd $(GCC3_BUILD_DIR); \
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
				--with-ppl=no \
				--with-isl=no \
				--with-cloog=no \
				--with-libelf=no \
				--with-arch=armv8-a  2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/full_gcc-configure-$(DATE).log || { echo "配置完整gcc失败！"; exit 1; }; \
	cd $(GCC3_BUILD_DIR); \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make $(JOBS) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-glibc-make-$(DATE).log || { echo "编译 all-glibc 失败！"; exit 1; }; \
	PATH="$(TOOLS_DIR)/bin:$$PATH" make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-glibc-install-$(DATE).log || { echo "安装 all-glibc 失败！"; exit 1; }; \
	echo "安装完整gcc完成，接下来请执行: make install_env"


install_env: 
	echo "安装完成，配置环境变量..."
	@if ! grep -q "${TOOLS_DIR}/bin" ~/.bashrc; then \
		echo "export PATH=${TOOLS_DIR}/bin:\$$PATH" >> ~/.bashrc; \
	fi
	. ~/.bashrc;
	echo "环境变量配置完成! 请手动执行: source ~/.bashrc"

testsuite: init
	echo "Running GCC Testsuite..."
	@cd $(GCC_BUILD_DIR); \
	unset LD_LIBRARY_PATH; \
	if [ -d $(LOG_DIR) ]; then \
		echo "Log directory exists."; \
	else \
		mkdir -p $(LOG_DIR); \
		echo "Created log directory."; \
	fi; \
	make check-gcc RUNTESTFLAGS="--target_board=unix-aarch64 " 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/testsuite-$(DATE).log; \
	echo "GCC Testsuite finished. Check $(LOG_DIR)/testsuite-$(DATE).log for results."

compile_test:
	@echo "Compiling test code with $(TARGET)-gcc..." | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
	$(TARGET)-gccgo -o test_code/$(TEST_CODE)go test_code/$(TEST_CODE).go | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
	$(TARGET)-gccgo -static -o test_code/$(TEST_CODE)go_static test_code/$(TEST_CODE).go | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
	$(TARGET)-gcc  -o test_code/$(TEST_CODE)c test_code/$(TEST_CODE).c | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
	$(TARGET)-g++ -o test_code/$(TEST_CODE)cpp test_code/$(TEST_CODE).cpp | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
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
	@if [ ! -f $(SOURCE_DIR)/libunwind-$(LIBUNWIND_VERSION).tar.gz ]; then \
		wget $(LIBUNWIND_URL) -P $(SOURCE_DIR) \
		 || { echo "下载 libunwind 失败！"; exit 1; }; \
	fi
	@if [ ! -d $(LIBUNWIND_DIR) ]; then \
    echo "解压 libunwind..."; \
    7z x -y $(SOURCE_DIR)/libunwind-$(LIBUNWIND_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 libunwind 失败！"; rm -rf $(LIBUNWIND_DIR); exit 1; }; \
	fi
	cd $(SOURCE_DIR)/libunwind-$(LIBUNWIND_VERSION); \
	export SYSROOT="/home/879650736/arm-unknown-gcc-build/tools/arm-linux-gnueabihf";\
	export CC="arm-linux-gnueabihf-gcc"; \
   	export CXX="arm-linux-gnueabihf-g++"; \
	export CFLAGS="-I$(SYSROOT_DIR)/include -D_GNU_SOURCE";\
	export LDFLAGS="-L$(SYSROOT_DIR)/lib -lgcc  -lpthread -static";\
	./configure   --host=$(TARGET)  \
	--prefix=$(SYSROOT_DIR)   --enable-static --disable-tests ;   \
	make && make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/libunwind-install-$(DATE).log || { echo "安装 libunwind 失败！"; exit 1; }; \

libunwind_clean:
	cd $(SOURCE_DIR)/libunwind-$(LIBUNWIND_VERSION); \
	make clean

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
	@if [ ! -f ./linux-$(LINUX_VERSION).tar.xz ]; then \
		wget $(LINUX_URL) || { echo "下载 linux 内核源码失败！"; exit 1; }; \
	fi
	@if [ ! -f ./glibc-$(GLIBC_VERSION).tar.gz ]; then \
		wget $(GLIBC_URL) || { echo "下载 glibc 失败！"; exit 1; }; \
	fi

download1:
	echo "下载源码..."
	@if [ ! -f ./binutils-$(BINUTILS_VERSION).tar.gz ] || [ ! -f ./binutils-$(BINUTILS_VERSION).tar.gz.sig ]; then \
		wget -nc  $(BINUTILS_URL) || { echo "下载 binutils 失败！"; exit 1; }; \
		wget -nc  $(BINUTILS_URL).sig || { echo "下载 binutils 签名文件失败！"; exit 1; }; \
	fi
	@if [ ! -f ./gcc-$(GCC_VERSION).tar.gz ] || [ ! -f ./gcc-$(GCC_VERSION).tar.gz.sig ]; then \
		wget -nc  $(GCC_URL) || { echo "下载 gcc 失败！"; exit 1; }; \
		wget -nc  $(GCC_URL).sig|| { echo "下载 gcc 签名文件失败！"; exit 1; }; \
	fi
	@if [ ! -f ./linux-$(LINUX_VERSION).tar.xz ] || [ ! -f ./linux-$(LINUX_VERSION).tar.sign ]; then \
		wget -nc  $(LINUX_URL) || { echo "下载 linux 内核源码失败！"; exit 1; }; \
		wget -nc  $(LINUX_SIGN_URL) || { echo "下载 linux 签名文件失败！"; exit 1; }; \
	fi
	@if [ ! -f ./glibc-$(GLIBC_VERSION).tar.gz ] || [ ! -f ./glibc-$(GLIBC_VERSION).tar.gz.sig ]; then \
		wget -nc  $(GLIBC_URL) || { echo "下载 glibc 失败！"; exit 1; }; \
		wget -nc  $(GLIBC_URL).sig || { echo "下载 glibc 签名文件失败！"; exit 1; }; \
	fi

copy:
	@mkdir -p $(SOURCE_DIR)
	cp $(HOME)/build_toolchain/*.tar.gz $(SOURCE_DIR)
	cp $(HOME)/build_toolchain/*.tar.xz $(SOURCE_DIR)


copy1:
	@mkdir -p $(SOURCE_DIR)
	cp $(HOME)/build_toolchain/*.tar.gz $(SOURCE_DIR)
	cp $(HOME)/build_toolchain/*.tar.xz $(SOURCE_DIR)
	cp $(HOME)/build_toolchain/*.tar.sign $(SOURCE_DIR)
	cp $(HOME)/build_toolchain/*.tar.gz.sig $(SOURCE_DIR)

