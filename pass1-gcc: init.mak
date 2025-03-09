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
				--disable-libsanitizer \
				--disable-lto --disable-libmudflap \
				--disable-libquadmath --disable-libssp --disable-nls \
				--enable-languages=c,c++,go \
				--with-arch=armv7-a \
				--with-float=soft \
				--with-sysroot=$(SYSROOT_DIR) \
				--with-native-system-header-dir=/$(TARGET)/include \
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
		--prefix=$(SYSROOT_DIR)/$(TARGET)\
		--host=$(TARGET) \
		--with-headers=$(SYSROOT_DIR)/$(TARGET)/include \
		--with-sysroot=$(SYSROOT_DIR) \
		--with-arch=armv7-a \
		--with-float=soft \
		--disable-multilib \
		--disable-profile \
		--enable-threads=posix \
		--enable-force-unwind \
		--with-libgcc-s=yes \
		--enable-static-pie=no \
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