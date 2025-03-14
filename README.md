# ARM Linux 交叉工具链构建指南

## 项目概述

本工具链用于构建ARM架构的交叉编译环境，支持arm-linux-gnueabihf、aarch64-unknown-linux-gnu目标平台。包含以下核心组件：

- GCC 13.2.0
- Binutils 2.37
- Glibc 2.39
- Linux 内核头文件 6.1.10

## 环境要求

- Linux 操作系统（在ubuntu 18.04、24.04上测试通过）
- msys2开发环境（在windows10测试通过）
- 基础开发工具：make, wget, tar, gcc
- 磁盘空间：至少 10GB 可用空间
- 内存：推荐 8GB+

## 建议安装依赖

Debian系

```bash
sudo apt update && sudo apt upgrade -y
sudo apt-get install -y gcc g++ \
	build-essential gperf bison flex texinfo  \
	help2man make libncurses5-dev  \
	python3-dev autoconf automake libtool \
	libtool-bin gawk wget bzip2 xz-utils\
	unzip dejagnu libcrypt-dev
```

msys环境

```bash
pacman -Syu
pacman -S make gcc flex texinfo unzip  \
	help2man patch libtool bison autoconf automake \
	base-devel mingw-w64-x86_64-toolchain \
	mingw-w64-x86_64-ncurses ncurses-devel\
	tar gzip xz p7zip coreutils moreutils\
	rsync autoconf diffutils gawk \
	git gperf mingw-w64-x86_64-libunwind
```

```

```##

GMP -> MPFR -> (PPL) -> (ISL) -> (C LOOG) -> (libelf) -> (binutils) -> core pass 1 compiler -> kernel headers -> c library headers and start files -> core pass 2 comiler -> complete c library -> final compiler

1. 括号项为可不构建项
2. MPRF依赖GMP,MPC依赖GMP和MPRF
3. PPL依赖GMP,C LOOG/PPL依赖GMP和  PPL或者ISL
4. final compiler依赖binutils和c库
5. c库依赖binutils和core pass 2 comiler
6. core pass 2 comiler依赖binutils、c library headers 和 start files
7. c library headers 和 start files依赖core pass 1 compiler和kernel headers
8. core pass 1 compiler依赖binutils

## 构建信息

1. 一部分主机操作系统需要额外的库：libraries、gettext、libiconv
2. binutils 可能需要elf2flt，zlib依赖elf2flt
3. 可构建额外的debug utilities： cross-gdb、gdb server、 native gdb 、strace 、ltrace 、DUMA 、 dmalloc
4. 目标机系统使用的内核头文件必须和构建出的工具链的版本一样或者更高
5. uclibc只支持linux,uclibc-ng支持其他的os
6. glibc不支持no-MMU,但uclibc支持
7. Glibc默认架构一致性（host和target位数相同），gcc-multilib 、binutils可绕过限制
8. windows构建需要启用大小写敏感、可尝试用Cygwin构建
9. adbanced features in gcc: GRAPHITE、LTO
10. GRAPHITE additional libraries: PPL、ISL 、CLooG/PPL
11. LTO additional libraries： libelf

## 注意事项

1. 日志文件保存在`./logs/`目录，可用于排查构建问题
2. 确保网络连接正常以下载源码包

### msys2 branch注意事项

1. msys解压tar.gz时可能无法解析符号链接，需要使用git 或者使用7zip解压
2. 需要将windows设为大小写敏感，注册表路径：HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\kernel\obcaseinsensitive，将1改为0
3. export PATH MSYS=winsymlinks:nativestrict写入~/.bashrc
