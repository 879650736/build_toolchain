# 定义变量
SHELL := /bin/bash
TARGET := aarch64-unknown-linux-gnu
TOOLCHAIN_HOME := $(HOME)/aarch-gcc-build
SOURCE_DIR := $(TOOLCHAIN_HOME)/source
TOOLS_DIR := $(TOOLCHAIN_HOME)/tools
GCC_VERSION ?= 13.2.0
BINUTILS_VERSION ?= 2.37
LINUX_VERSION ?= 6.1.10
GLIBC_VERSION ?= 2.35
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
LINUX_SIGN_URL := https://ftp.sjtu.edu.cn/sites/ftp.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.sign
GLIBC_URL := https://ftp.gnu.org/pub/gnu/glibc/glibc-$(GLIBC_VERSION).tar.gz
LIBUNWIND_URL := https://github.com/libunwind/libunwind/releases/download/v$(LIBUNWIND_VERSION)/libunwind-$(LIBUNWIND_VERSION).tar.gz
SYSROOT_DIR := $(TOOLS_DIR)
LOG_DIR := $(HOME)/build_toolchain/logs
TEST_CODE := aarch64_test
JOBS ?= 
DATE := $(shell date +%Y%m%d)


export PATH
export PATH := $(TOOLS_DIR)/bin:$(PATH)

test: init_env download copy init_tar linux binutils pass1-gcc glibc libgcc all-glibc libstdc++
# 定义目标
all: init_env code init linux binutils pass1-gcc glibc libgcc all-glibc libstdc++ install_env compile_test run_test

test_code: install_env compile_test run_test

init_env:
	mkdir -p $(LOG_DIR)
	mkdir -p $(TOOLCHAIN_HOME) $(SOURCE_DIR) $(TOOLS_DIR)  $(SYSROOT_DIR)
	@echo "环境初始化完成，接下来请执行: make init"

code:
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
	make ARCH=arm64 INSTALL_HDR_PATH=$(SYSROOT_DIR)/$(TARGET) headers_install \
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
	../configure --target=$(TARGET) --prefix=$(SYSROOT_DIR) \
		--disable-multilib \
		--disable-werror \
		--with-arch=armv8-a \
		-v 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-configure-$(DATE).log || { echo "配置 binutils 失败！"; exit 1; }; \
	make $(JOBS) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-make-$(DATE).log || { echo "构建 binutils 失败！"; exit 1; }; \
	make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/binutils-make-install-$(DATE).log || { echo "安装 binutils 失败！"; exit 1; }; \
	echo "binutils 安装完成，接下来请执行: make pass1-gcc"


pass1-gcc: init
	echo "配置和安装 pass1-gcc..."
	if [ -d $(GCC_BUILD_DIR) ]; then \
		rm -rf $(GCC_BUILD_DIR); \
	fi; 
	cd $(GCC_DIR); \
	./contrib/download_prerequisites 
	mkdir -p $(GCC_BUILD_DIR) && cd $(GCC_BUILD_DIR); \
	../configure --target=$(TARGET) --prefix=$(SYSROOT_DIR) \
				--disable-multilib \
				--disable-libsanitizer \
				--disable-lto --disable-libmudflap \
				--disable-libquadmath --disable-libssp --disable-nls \
				--enable-languages=c,c++,go \
				--with-native-system-header-dir=/$(TARGET)/include \
				--with-arch=armv8-a \
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
		--prefix=$(SYSROOT_DIR)/$(TARGET) \
		--with-headers=$(SYSROOT_DIR)/$(TARGET)/include \
		--with-arch=armv8-a \
		--disable-multilib \
		--disable-profile \
		--enable-threads=posix \
		--disable-werror \
		libc_cv_forced_unwind=yes \
		--enable-force-unwind \
		--with-libgcc-s=yes \
		--enable-static-pie=no \
		--with-pkgversion="Self across toolchain with glibc and glibc-2.39" \
		-v 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-configure-$(DATE).log || { \
			echo "配置 glibc 失败！" >&2; \
			cat $(LOG_DIR)/glibc-configure-$(DATE).log >&2; \
			exit 1; \
		}; \
	cd $(GLIBC_BUILD_DIR); \
	make install-bootstrap-headers=yes install-headers 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-install-headers-$(DATE).log || { \
	echo "安装 glibc headers 失败！" >&2; \
	cat $(LOG_DIR)/glibc-install-headers-$(DATE).log >&2; \
	exit 1; \
	}; \
	make $(JOBS) csu/subdir_lib 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-make-csu-$(DATE).log || { \
	echo "编译 glibc 启动文件失败！" >&2; \
	cat $(LOG_DIR)/glibc-make-csu-$(DATE).log >&2; \
	exit 1; \
	};
	
	cd $(GLIBC_BUILD_DIR); \
	install csu/crt1.o csu/crti.o csu/crtn.o $(TOOLS_DIR)/$(TARGET)/lib 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-install-crt-$(DATE).log; \
	${TARGET}-gcc -nostdlib -nostartfiles -shared \
	-x c /dev/null -o $(TOOLS_DIR)/$(TARGET)/lib/libc.so 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/glibc-create-libc-$(DATE).log;\
	touch $(TOOLS_DIR)/$(TARGET)/include/gnu/stubs.h; \
	echo "安装标准 C 库头文件和启动文件成功，接下来请执行: make libgcc"
bb:
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
	make $(JOBS) all-target-libgcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-target-libgcc-$(DATE).log || { echo "编译 libgcc 失败！"; exit 1; }; \
	make install-target-libgcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/install-target-libgcc-$(DATE).log || { echo "安装 libgcc 失败！"; exit 1; }; \
	echo "安装编译器支持库完成，接下来请执行: make all-glibc"

all-glibc: init
	echo "安装标准 C 库..."
	@cd $(GLIBC_BUILD_DIR); \
	make $(JOBS) 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-glibc-make-$(DATE).log || { echo "编译 all-glibc 失败！"; exit 1; }; \
	make install 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-glibc-install-$(DATE).log || { echo "安装 all-glibc 失败！"; exit 1; }; \
	echo "安装标准 C 库完成，接下来请执行: make libstdc++"

# 新增共享库构建目标，依赖all-glibc
libgcc-shared: init
	@echo "构建共享编译器支持库..."
	@cd $(GCC_BUILD_DIR); \
	make $(JOBS) all-target-libgcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/all-target-libgcc-shared-$(DATE).log || { echo "编译共享libgcc失败！"; exit 1; }; \
	make install-target-libgcc 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/install-target-libgcc-shared-$(DATE).log || { echo "安装共享libgcc失败！"; exit 1; }; \
	echo "共享编译器支持库安装完成。"

cc: init
	echo "构建并安装 libstdc++..."
	@cd $(GCC_BUILD_DIR); \
	make $(JOBS) all-target-libstdc++-v3 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/libstdc++-make-$(DATE).log || { echo "构建 libstdc++ 失败！"; exit 1; }; \
	make install-target-libstdc++-v3 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $(LOG_DIR)/libstdc++-install-$(DATE).log || { echo "安装 libstdc++ 失败！"; exit 1; }; \
	echo "所有构建完成!"


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
	export CFLAGS="-I$(SYSROOT_DIR)/include -D_GNU_SOURCE -O2";\
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
	cp /home/ssy/build_toolchain/*.tar.gz $(SOURCE_DIR)
	cp /home/ssy/build_toolchain/*.tar.xz $(SOURCE_DIR)
	cp /home/ssy/build_toolchain/*.tar.sign $(SOURCE_DIR)
	cp /home/ssy/build_toolchain/*.tar.gz.sig $(SOURCE_DIR)


