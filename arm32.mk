# 定义变量
SHELL := /bin/bash
TARGET := arm-unknown-linux-gnueabi
TOOLCHAIN_HOME := $(HOME)/arm-unknown-gcc-build
SOURCE_DIR := $(TOOLCHAIN_HOME)/source
TOOLS_DIR := $(TOOLCHAIN_HOME)/tools
GCC_VERSION ?= 13.2.0
BINUTILS_VERSION ?= 2.37
LINUX_VERSION ?= 6.1.10
GLIBC_VERSION ?= 2.39
LIBUNWIND_VERSION ?= 1.8.1
BINUTILS_DIR := $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION)
GCC_DIR := $(SOURCE_DIR)/gcc-$(GCC_VERSION)
GLIBC_DIR := $(SOURCE_DIR)/glibc-$(GLIBC_VERSION)
LINUX_DIR := $(SOURCE_DIR)/linux-$(LINUX_VERSION)
LIBUNWIND_DIR := $(SOURCE_DIR)/libunwind-$(LIBUNWIND_VERSION)
BINUTILS_BUILD_DIR := $(BINUTILS_DIR)/binutils_build
GCC_BUILD_DIR := $(GCC_DIR)/gcc_build-pass1
GLIBC_BUILD_DIR := $(GLIBC_DIR)/glibc_build
GCC_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.gz
BINUTILS_URL := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.gz
LINUX_URL := https://ftp.sjtu.edu.cn/sites/ftp.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.xz
GLIBC_URL := https://ftp.gnu.org/pub/gnu/glibc/glibc-$(GLIBC_VERSION).tar.gz
LIBUNWIND_URL := https://github.com/libunwind/libunwind/releases/download/v$(LIBUNWIND_VERSION)/libunwind-$(LIBUNWIND_VERSION).tar.gz
USER_DIR := /usr
SYSROOT_DIR := $(TOOLS_DIR)/$(TARGET)/sysroot
LOG_DIR := $(HOME)/build_toolchain/logs
TEST_CODE := arm_test
JOBS ?= 

DATE := $(shell date +%Y%m%d)


export PATH
export PATH := $(TOOLS_DIR)/bin:$(PATH)

# 定义目标
test: init_env download copy init linux binutils
all: init_env code init linux binutils pass1-gcc glibc libgcc all-glibc libstdc++ install_env compile_test run_test

init_env:
	mkdir -p $(LOG_DIR)
	@if ! grep -q "${TOOLS_DIR}/bin" ~/.bashrc; then \
		echo "export MSYS=winsymlinks:nativestrict >> ~/.bashrc; \
	fi
	. ~/.bashrc;
	@echo "环境变量配置完成! 请手动执行: source ~/.bashrc"
	@echo "检查 ${TOOLCHAIN_HOME} 是否存在..."
	@if [ ! -d "${TOOLCHAIN_HOME}" ]; then \
		mkdir -p $(TOOLCHAIN_HOME) $(SOURCE_DIR) $(TOOLS_DIR) $(SYSROOT_DIR); \
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
# 检查并解压 binutils
	@if [ ! -d $(BINUTILS_DIR) ]; then \
    echo "解压 binutils..."; \
    7z x -y $(SOURCE_DIR)/binutils-$(BINUTILS_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 binutils 失败！"; rm -rf $(BINUTILS_DIR); exit 1; }; \
	fi

# 检查并解压 gcc
	@if [ ! -d $(GCC_DIR) ]; then \
    echo "解压 gcc..."; \
    7z x -y $(SOURCE_DIR)/gcc-$(GCC_VERSION).tar.gz -so | 7z x -y -si -ttar -o$(SOURCE_DIR) || { echo "解压 gcc 失败！"; rm -rf $(GCC_DIR); exit 1; }; \
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


linux: init
	echo "安装 Linux 内核头文件..."
	mkdir -p $(TOOLS_DIR)/$(TARGET) 
	echo "TOOLS_DIR=$(TOOLS_DIR), TARGET=$(TARGET), LINUX_DIR=$(LINUX_DIR)"
	cd $(LINUX_DIR) && \
	make ARCH=arm INSTALL_HDR_PATH=$(TOOLS_DIR)/$(TARGET) headers_install \
	2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/headers_install-$(DATE).log || \
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
		--with-sysroot \
		--disable-nls \
		-v 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-configure-$(DATE).log || { echo "配置 binutils 失败！"; exit 1; }; \
	make $(JOBS) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-make-$(DATE).log || { echo "构建 binutils 失败！"; exit 1; }; \
	make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-make-install-$(DATE).log || { echo "安装 binutils 失败！"; exit 1; }; \
	echo "binutils 安装完成，接下来请执行: make pass1-gcc"

gdb:	

pass1-gcc: init
	echo "配置和安装 pass1-gcc..."
	if [ -d $(GCC_BUILD_DIR) ]; then \
		rm -rf $(GCC_BUILD_DIR); \
	fi; 
	cd $(GCC_DIR); \
	./contrib/download_prerequisites; 
	mkdir -p $(GCC_BUILD_DIR) && cd $(GCC_BUILD_DIR); \
	../configure --target=$(TARGET) --prefix=$(TOOLS_DIR) \
				--disable-multilib \
				--disable-libsanitizer \
				--disable-lto --disable-libmudflap \
				--disable-libquadmath --disable-libssp --disable-nls \
				--enable-languages=c,c++,go \
				--with-arch=armv7-a \
				--enable-static \
				--with-float=soft \
				--enable-threads=posix 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-configure-$(DATE).log || { echo "配置 pass1-gcc 失败！"; exit 1; }; \
	make $(JOBS) all-gcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-make-all-gcc-$(DATE).log || { echo "构建 pass1-gcc 失败！"; exit 1; }; \
	make install-gcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/pass1-make-install-gcc-$(DATE).log || { echo "安装 pass1-gcc 失败！"; exit 1; }; \
	echo "安装 C/C++ 编译器完成，接下来请执行: make glibc"

glibc: init
	echo "配置和安装 glibc 头文件和启动文件..." 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-target-$(DATE).log
	cd $(GLIBC_DIR); \
	if [ -d $(GLIBC_BUILD_DIR) ]; then \
		rm -rf $(GLIBC_BUILD_DIR); \
	fi; \
	mkdir -p $(GLIBC_BUILD_DIR) && cd $(GLIBC_BUILD_DIR); \
	unset LD_LIBRARY_PATH; \
	../configure --host=$(TARGET) \
		--target=$(TARGET) \
		--prefix=$(SYSROOT_DIR)/usr \
		--with-headers=$(TOOLS_DIR)/$(TARGET)/include \
		--with-arch=armv7-a \
		--with-float=soft \
		--disable-multilib \
		--disable-profile \
		--enable-threads=posix \
		--enable-force-unwind \
		--with-libgcc-s=yes \
		--enable-static \
		--enable-static-pie \
		--disable-werror \
		libc_cv_forced_unwind=yes \
		--with-pkgversion="Self across toolchain with glibc and glibc-2.39" \
		-v 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-configure-$(DATE).log || { \
			echo "配置 glibc 失败！" >&2; \
			cat $(LOG_DIR)/glibc-configure-$(DATE).log >&2; \
			exit 1; \
		}; \
	cd $(GLIBC_BUILD_DIR); \
	make $(JOBS) csu/subdir_lib 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-make-csu-$(DATE).log || { \
	echo "编译 glibc 启动文件失败！" >&2; \
		cat $(LOG_DIR)/glibc-make-csu-$(DATE).log >&2; \
	exit 1; \
	}; \
	make install-bootstrap-headers=yes install-headers 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-install-headers-$(DATE).log || { \
	echo "安装 glibc headers 失败！" >&2; \
		cat $(LOG_DIR)/glibc-install-headers-$(DATE).log >&2; \
	exit 1; \
	}; 
	
	cd $(GLIBC_BUILD_DIR); \
	install csu/crt1.o csu/crti.o csu/crtn.o $(TOOLS_DIR)/$(TARGET)/lib 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-install-crt-$(DATE).log; \
	${TARGET}-gcc -nostdlib -nostartfiles -shared \
	-x c /dev/null -o $(TOOLS_DIR)/$(TARGET)/lib/libc.so 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-create-libc-$(DATE).log;\
	touch $(TOOLS_DIR)/$(TARGET)/include/gnu/stubs.h; \
	echo "安装标准 C 库头文件和启动文件成功，接下来请执行: make libgcc"
aa:
	cd $(GLIBC_BUILD_DIR); \
	install csu/crt1.o csu/crti.o csu/crtn.o $(TOOLS_DIR)/$(TARGET)/lib 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-install-crt-$(DATE).log; \
	${TARGET}-gcc -nostdlib -nostartfiles -shared \
	-x c /dev/null -o $(TOOLS_DIR)/$(TARGET)/lib/libc.so 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-create-libc-$(DATE).log;\
	touch $(TOOLS_DIR)/$(TARGET)/include/gnu/stubs.h; \
	echo "安装标准 C 库头文件和启动文件成功，接下来请执行: make libgcc"

libgcc: init
	echo "安装编译器支持库..."
	@cd $(GCC_BUILD_DIR); \
	make -j$(JOBS) all-target-libgcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-target-libgcc-$(DATE).log || { echo "编译 libgcc 失败！"; exit 1; }; \
	make install-target-libgcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/install-target-libgcc-$(DATE).log || { echo "安装 libgcc 失败！"; exit 1; }; \
	echo "安装编译器支持库完成，接下来请执行: make all-glibc"

all-glibc: init
	echo "安装标准 C 库..."
	@cd $(GLIBC_BUILD_DIR); \
	make -j$(JOBS) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-glibc-make-$(DATE).log || { echo "编译 all-glibc 失败！"; exit 1; }; \
	make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-glibc-install-$(DATE).log || { echo "安装 all-glibc 失败！"; exit 1; }; \
	echo "安装标准 C 库完成，接下来请执行: make libstdc++"

libstdc++: init
	echo "完成最后的构建..."
	@cd $(GCC_BUILD_DIR); \
	make $(JOBS) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/libstdc++-make-$(DATE).log || { echo "完成最后的构建失败！"; exit 1; }; \
	make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/libstdc++-install-$(DATE).log || { echo "安装 libstdc++ GCC 失败！"; exit 1; }; \
	echo "所有构建完成!"

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
	make check-gcc RUNTESTFLAGS="--target_board=unix-arm " 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/testsuite-$(DATE).log; \
	echo "GCC Testsuite finished. Check $(LOG_DIR)/testsuite-$(DATE).log for results."

compile_test:
	@echo "Compiling test code with arm-linux-gnueabihf-gcc..." | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
	arm-linux-gnueabihf-gccgo -o test_code/$(TEST_CODE) test_code/$(TEST_CODE).go  -lunwind -lgcc -lgcc_eh   -I${SYSROOT_DIR}/usr/include -L${SYSROOT_DIR}/usr/lib| ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
	arm-linux-gnueabihf-gccgo -static -o test_code/$(TEST_CODE)_static test_code/$(TEST_CODE).go  -lunwind -lgcc -lgcc_eh   -I${SYSROOT_DIR}/usr/include -L${SYSROOT_DIR}/usr/lib | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/compile_test-$(DATE).log
	@echo "Compilation completed."

file:
	@echo "display file type" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/file-target-$(DATE).log
	file test_code/$(TEST_CODE) | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/file-target-$(DATE).log
	file test_code/$(TEST_CODE)_static | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/file-target-$(DATE).log

ldd:
	@echo "display ldd" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/ldd-target-$(DATE).log
	ldd test_code/$(TEST_CODE) | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/ldd-target-$(DATE).log
#ldd test_code/$(TEST_CODE)_static > static_ldd.log 2>&1 | tee -a $(LOG_DIR)/ldd-target.log

run_test:
	@echo "Running compiled binary with qemu-arm..." | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	@echo "begin first test" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	qemu-arm -L $(TOOLS_DIR)/$(TARGET) test_code/$(TEST_CODE) | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	@echo "=========================================" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	@echo "begin static test" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
	qemu-arm -L $(TOOLS_DIR)/$(TARGET) test_code/$(TEST_CODE)_static | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/run_test-target-$(DATE).log
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
	rm -rf $(BINUTILS_BUILD_DIR) $(GCC_BUILD_DIR) $(GLIBC_BUILD_DIR)\
			$(MPFR_BUILD_DIR) $(GMP_BUILD_DIR) $(MPC_BUILD_DIR); \
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

copy:
	@mkdir -p $(SOURCE_DIR)
	cp $(HOME)/build_toolchain/*.tar.gz $(SOURCE_DIR)
	cp $(HOME)/build_toolchain/*.tar.xz $(SOURCE_DIR)
