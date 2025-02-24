# 定义变量
SHELL := /bin/bash
TARGET := arm-linux-gnueabihf
TOOLCHAIN_HOME := $(HOME)/arm-gcc-build
SOURCE_DIR := $(TOOLCHAIN_HOME)/source
TOOLS_DIR := $(TOOLCHAIN_HOME)/tools
GCC_VERSION ?= 13.2.0
BINUTILS_VERSION ?= 2.37
LINUX_VERSION ?= 6.1.10
GLIBC_VERSION ?= 2.39
BINUTILS_DIR := $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION)
GCC_DIR := $(SOURCE_DIR)/gcc-$(GCC_VERSION)
GLIBC_DIR := $(SOURCE_DIR)/glibc-$(GLIBC_VERSION)
LINUX_DIR := $(SOURCE_DIR)/linux-$(LINUX_VERSION)
BINUTILS_BUILD_DIR := $(BINUTILS_DIR)/binutils_build
GCC_BUILD_DIR := $(GCC_DIR)/gcc_build-pass1
GLIBC_BUILD_DIR := $(GLIBC_DIR)/glibc_build
GCC_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.gz
BINUTILS_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.gz
LINUX_URL := https://ftp.sjtu.edu.cn/sites/ftp.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.xz
GLIBC_URL := https://ftp.gnu.org/pub/gnu/glibc/glibc-$(GLIBC_VERSION).tar.gz
USER_DIR := /usr
LOG_DIR := /home/logs
JOBS ?= 4
export PATH
export PATH := $(TOOLS_DIR)/bin:$(PATH)

# 定义目标
all: init_env code init linux binutils pass1-gcc glibc libgcc all-glibc libstdc++ install_env

test: init_env copy init linux binutils pass1-gcc
init_env:
	mkdir -p $(LOG_DIR)
	echo "检查 ${TOOLCHAIN_HOME} 是否存在..."
	@if [ ! -d "${TOOLCHAIN_HOME}" ]; then \
		mkdir -p $(TOOLCHAIN_HOME) $(SOURCE_DIR) $(TOOLS_DIR); \
	fi
	@echo "环境初始化完成，接下来请执行: make init"

code:
	echo "下载源码..."
	@mkdir -p $(SOURCE_DIR)
	@cd $(SOURCE_DIR); 
	@if [ ! -f $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION).tar.gz ]; then \
		wget $(BINUTILS_URL) -P $(SOURCE_DIR) || { echo "下载 binutils 失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/gcc-$(GCC_VERSION).tar.gz ]; then \
		wget $(GCC_URL) -P $(SOURCE_DIR) || { echo "下载 gcc 失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/linux-$(LINUX_VERSION).tar.xz ]; then \
		wget $(LINUX_URL) -P $(SOURCE_DIR) || { echo "下载 linux 内核源码失败！"; exit 1; }; \
	fi
	@if [ ! -f $(SOURCE_DIR)/glibc-$(GLIBC_VERSION).tar.gz ]; then \
		wget $(GLIBC_URL) -P $(SOURCE_DIR) || { echo "下载 glibc 失败！"; exit 1; }; \
	fi
	@echo "源码下载完成，接下来请执行: make init"


init: 
	echo "解压源码..."
	@if [ ! -d $(BINUTILS_DIR) ]; then \
		echo "解压 binutils..."; \
		tar -zxvf $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION).tar.gz -C $(SOURCE_DIR) || { echo "解压 binutils 失败！"; exit 1; }; \
	fi
	@if [ ! -d $(GCC_DIR) ]; then \
		echo "解压 gcc..."; \
		tar -zxvf $(SOURCE_DIR)/gcc-$(GCC_VERSION).tar.gz -C $(SOURCE_DIR) || { echo "解压 gcc 失败！"; exit 1; }; \
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


linux: init
	echo "安装 Linux 内核头文件..."
	mkdir -p $(TOOLS_DIR)/$(TARGET) 
	echo "TOOLS_DIR=$(TOOLS_DIR), TARGET=$(TARGET), LINUX_DIR=$(LINUX_DIR)"
	cd $(LINUX_DIR) && \
	make ARCH=arm INSTALL_HDR_PATH=$(TOOLS_DIR)/$(TARGET) headers_install || \
	(echo "安装 Linux 内核头文件失败！" && exit 1)
	echo "Linux 内核头文件安装完成，接下来请执行: make binutils"

binutils: init
	echo "配置和安装 binutils..."
	cd $(BINUTILS_DIR); \
	if [ -d $(BINUTILS_BUILD_DIR) ]; then \
		rm -rf $(BINUTILS_BUILD_DIR); \
	fi; \
	mkdir -p $(BINUTILS_BUILD_DIR) && cd $(BINUTILS_BUILD_DIR); \
	../configure --target=$(TARGET) --prefix=$(TOOLS_DIR) \
		--disable-multilib \
		--disable-werror \
		--with-arch=armv7-a \
		--with-float=soft \
		-v 2>&1 | tee $(LOG_DIR)/binutils-configure.log || { echo "配置 binutils 失败！"; exit 1; }; \
	make -j$(JOBS) 2>&1 | tee $(LOG_DIR)/binutils-make.log || { echo "构建 binutils 失败！"; exit 1; }; \
	make install 2>&1 | tee $(LOG_DIR)/binutils-make-install.log || { echo "安装 binutils 失败！"; exit 1; }; \
	echo "binutils 安装完成，接下来请执行: make pass1-gcc"


pass1-gcc: init
	echo "配置和安装 pass1-gcc..."
	if [ -d $(GCC_BUILD_DIR) ]; then \
		rm -rf $(GCC_BUILD_DIR); \
	fi; 
	cd $(GCC_DIR); \
	./contrib/download_prerequisites 
	mkdir -p $(GCC_BUILD_DIR) && cd $(GCC_BUILD_DIR); \
	../configure --target=$(TARGET) --prefix=$(TOOLS_DIR) \
				--disable-multilib \
				--enable-languages=c,c++,go \
				--with-arch=armv7-a \
				--with-float=soft \
				--enable-threads=posix 2>&1 | tee $(LOG_DIR)/pass1-configure.log || { echo "配置 pass1-gcc 失败！"; exit 1; }; \
	make -j$(JOBS) all-gcc 2>&1 | tee $(LOG_DIR)/pass1-make-all-gcc.log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	make install-gcc 2>&1 | tee $(LOG_DIR)/pass1-make-install-gcc.log || { echo "安装 pass1-gcc 失败！"; exit 1; }; \
	echo "安装 C/C++ 编译器完成，接下来请执行: make glibc"

glibc: init
	echo "配置和安装 glibc 头文件和启动文件..."
	cd $(GLIBC_DIR); \
	if [ -d $(GLIBC_BUILD_DIR) ]; then \
		rm -rf $(GLIBC_BUILD_DIR); \
	fi; \
	mkdir -p $(GLIBC_BUILD_DIR) && cd $(GLIBC_BUILD_DIR); \
	../configure --host=$(TARGET) \
		--target=$(TARGET) \
		--prefix=$(TOOLS_DIR)/$(TARGET) \
		--with-headers=$(TOOLS_DIR)/$(TARGET)/include \
		--with-arch=armv7-a \
		--with-fpu=vfpv3-d16 \
		--with-float=hard \
		--disable-multilib \
		--disable-profile \
		--enable-threads=posix \
		--disable-werror \
		libc_cv_forced_unwind=yes \
		--with-pkgversion="Self across toolchain with glibc and glibc-2.39" \
		-v 2>&1 | tee $(LOG_DIR)/glibc-configure.log || { \
			echo "配置 glibc 失败！" >&2; \
			cat $(LOG_DIR)/glibc-configure.log >&2; \
			exit 1; \
		}; \
	make install-bootstrap-headers=yes install-headers 2>&1 | tee $(LOG_DIR)/glibc-install-headers.log || { \
	echo "安装 glibc headers 失败！" >&2; \
		cat $(LOG_DIR)/glibc-install-headers.log >&2; \
	exit 1; \
	}; \
	make -j$(JOBS) csu/subdir_lib 2>&1 | tee $(LOG_DIR)/glibc-make-csu.log || { \
	echo "编译 glibc 启动文件失败！" >&2; \
		cat $(LOG_DIR)/glibc-make-csu.log >&2; \
	exit 1; \
	}; 
	cd $(GLIBC_BUILD_DIR); \
	install csu/crt1.o csu/crti.o csu/crtn.o $(TOOLS_DIR)/$(TARGET)/lib  | tee $(LOG_DIR)/glibc-make-csu/crt1.log || { \
	echo "安装 glibc csu/crt1.o失败!" >&2; \
		cat $(LOG_DIR)/glibc-make-csu/crt1.log >&2; \
	exit 1; \
	}; \
	${TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $(TOOLS_DIR)/$(TARGET)/lib/libc.so | tee $(LOG_DIR)/glibc-placeholder.log  || { \
	echo "创建 glibc 占位符失败!" >&2; \
		cat $(LOG_DIR)/glibc-placeholder.log >&2; \
	exit 1; \
	}; \
	touch $(TOOLS_DIR)/$(TARGET)/include/gnu/stubs.h || { \
	echo "创建 gnu/stubs.h 失败！" >&2; \
	exit 1; \
	}; \
	echo "安装标准 C 库头文件和启动文件成功，接下来请执行: make libgcc"

libgcc: init
	echo "安装编译器支持库..."
	@cd $(GCC_BUILD_DIR); \
	make -j$(JOBS) all-target-libgcc 2>&1 | tee $(LOG_DIR)/all-target-libgcc.log || { echo "编译 libgcc 失败！"; exit 1; }; \
	make install-target-libgcc 2>&1 | tee $(LOG_DIR)/install-target-libgcc.log || { echo "安装 libgcc 失败！"; exit 1; }; \
	echo "安装编译器支持库完成，接下来请执行: make all-glibc"

all-glibc: init
	echo "安装标准 C 库..."
	@cd $(GLIBC_BUILD_DIR); \
	make -j$(JOBS) 2>&1 | tee $(LOG_DIR)/all-glibc-make.log || { echo "编译 all-glibc 失败！"; exit 1; }; \
	make install 2>&1 | tee $(LOG_DIR)/all-glibc-install.log || { echo "安装 all-glibc 失败！"; exit 1; }; \
	echo "安装标准 C 库完成，接下来请执行: make libstdc++"

libstdc++: init
	echo "完成最后的构建..."
	@cd $(GCC_BUILD_DIR); \
	make -j$(JOBS) 2>&1 | tee $(LOG_DIR)/libstdc++-make.log || { echo "完成最后的构建失败！"; exit 1; }; \
	make install 2>&1 | tee $(LOG_DIR)/libstdc++-install.log || { echo "安装 libstdc++ GCC 失败！"; exit 1; }; \
echo "所有构建完成!"

install_env: init
	echo "安装完成，配置环境变量..."
	@if ! grep -q "${TOOLS_DIR}/bin" ~/.bashrc; then \
		echo "export PATH=${TOOLS_DIR}/bin:\$$PATH" >> ~/.bashrc; \
	fi
	. ~/.bashrc;
	echo "环境变量配置完成!"

testsuite: init
	echo "Running GCC Testsuite..."
	@cd $(GCC_BUILD_DIR); \
	unset LD_LIBRARY_PATH;\
	make check-gcc RUNTESTFLAGS="--target_board=unix-arm" 2>&1 | tee $(LOG_DIR)/testsuite.log; \
	echo "GCC Testsuite finished. Check testsuite.log for results."

clean:
	echo "删除无用文件..."
	@cd $(SOURCE_DIR); \
	rm -rf $(BINUTILS_BUILD_DIR) $(GCC_BUILD_DIR) $(GLIBC_BUILD_DIR)\
			$(MPFR_BUILD_DIR) $(GMP_BUILD_DIR) $(MPC_BUILD_DIR); \
	echo "删除无用文件完成，接下来请执行: make init"

delete:
	echo "删除全部构建..."
	@cd $(TOOLCHAIN_HOME); 
	rm -rf $(TOOLCHAIN_HOME)
	echo "删除全部构建完成，接下来请执行: make all"

copy:
	@mkdir -p $(SOURCE_DIR)
	cp /home/*.tar.gz $(SOURCE_DIR)
	cp /home/*.tar.xz $(SOURCE_DIR)