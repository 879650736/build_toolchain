# ARM Linux 交叉工具链构建指南

## 项目概述

本工具链用于构建ARM架构的交叉编译环境，支持arm-linux-gnueabihf目标平台。包含以下核心组件：

- GCC 13.2.0
- Binutils 2.37
- Glibc 2.39
- Linux 内核头文件 6.1.10

## 环境要求

- Linux 操作系统（在ubuntu 18.04、24.04上测试通过）
- 基础开发工具：make, wget, tar, gcc
- 磁盘空间：至少 10GB 可用空间
- 内存：推荐 8GB+

## 建议安装依赖

```bash
sudo apt update && sudo apt upgrade -y
	sudo apt-get install -y gcc g++ \
	build-essential gperf bison flex texinfo  \
	help2man make libncurses5-dev  \
	python3-dev autoconf automake libtool \
	libtool-bin gawk wget bzip2 xz-utils\
	unzip dejagnu libcrypt-dev
```

## 安装步骤

### 1. 初始化构建环境

```bash
make init_env
```

### 2. 下载源代码

```bash
make code
```

### 3. 解压源码包

```bash
make init
```

### 4. 完整构建流程

```bash
make all
```

## 分步构建说明


| 阶段             | 命令             | 日志文件                          | 说明                            |
| ---------------- | ---------------- | --------------------------------- | ------------------------------- |
| Linux头文件安装  | `make linux`     | headers_install-{date}.log        | 安装内核头文件                  |
| Binutils构建     | `make binutils`  | binutils-configure-{date}.log     | 构建基础工具链                  |
|                  |                  | binutils-make-{date}.log          |                                 |
|                  |                  | binutils-make-install-{date}.log  |                                 |
| 初始GCC构建      | `make pass1-gcc` | pass1-configure-{date}.log        | 构建第一阶段编译器              |
|                  |                  | pass1-make-all-gcc-{date}.log     |                                 |
|                  |                  | pass1-make-install-gcc-{date}.log |                                 |
| Glibc构建        | `make glibc`     | glibc-target-{date}.log           | 配置和安装glibc头文件和启动文件 |
|                  |                  | glibc-configure-{date}.log        |                                 |
|                  |                  | glibc-install-headers-{date}.log  |                                 |
|                  |                  | glibc-make-csu-{date}.log         |                                 |
|                  |                  | glibc-install-crt-{date}.log      |                                 |
|                  |                  | glibc-create-libc-{date}.log      |                                 |
| 编译器支持库构建 | `make libgcc`    | all-target-libgcc-{date}.log      | 安装编译器支持库                |
|                  |                  | install-target-libgcc-{date}.log  |                                 |
| 标准C库构建      | `make all-glibc` | all-glibc-make-{date}.log         | 安装标准C库                     |
|                  |                  | all-glibc-install-{date}.log      |                                 |
| 最后gcc的构建    | `make libstdc++` | libstdc++-make-{date}.log         | 完成最后的构建                  |
|                  |                  | libstdc++-install-{date}.log      |                                 |

注意：

- {date} 表示构建日期，格式为 YYYYMMDD
- 所有日志文件位于 logs/ 目录下
- 可通过查看对应日志文件排查构建问题

## 测试工具链

```bash
make test          # 执行完整测试流程
```

## 维护命令

```bash
make clean     # 清理中间文件
make delete    # 完全删除构建目录
make copy      # 复制源码到构建目录
```

## 推荐构建顺序

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

1. 构建过程可能耗时1-3小时，建议使用`-j`参数指定并行任务数：
   ```bash
   make all JOBS=8
   ```
2. 日志文件保存在`logs/`目录，可用于排查构建问题
3. 确保网络连接正常以下载源码包

### msys2 branch注意事项

1. msys解压tar.gz时可能无法解析符号链接，需要使用git 或者使用7zip解压
2. 需要将windows设为大小写敏感，注册表路径：HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\kernel，将1改为0
3. mwing64中不存在pthread.h,指定为glibc中的

