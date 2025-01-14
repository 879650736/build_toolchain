FROM ubuntu:20.04

# 更新 apt 源并安装必要的软件包
RUN apt-get update && apt-get install -y \
    wget \
    tar \
    make \
    gcc \
    g++ \
    flex \
    bison \
    gawk \
    rsync \
    xz-utils \
    python3 \
    python3-dev \
    sudo

# 创建一个用户来执行编译
WORKDIR /home

# 设置默认命令 (可选，可用于调试)
# CMD ["bash"]