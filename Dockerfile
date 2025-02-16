FROM debian:bookworm

ARG OPENSSL_VERSION="3.3.1"
ARG PYTHON_VERSION="3.12.7"

ENV DEBIAN_FRONTEND=noninteractive

# add/remove dependencies.
RUN apt-get update && apt-get install -y wget build-essential gdb lcov pkg-config \
    libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
    libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
    lzma lzma-dev tk-dev uuid-dev zlib1g-dev && \
    apt-get remove -y libssl-dev openssl

# install openssl
RUN mkdir -p /workdir && \
    cd /workdir && \
    wget https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar zxvf openssl-${OPENSSL_VERSION}.tar.gz && rm openssl-${OPENSSL_VERSION}.tar.gz && \
    cd /workdir/openssl-${OPENSSL_VERSION} && \
    ./Configure --prefix=/usr --openssldir=/etc/ssl shared && \
    make && make install && \
    set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "aarch64" ]; then \
        cp /usr/lib/libssl.so*          /lib/aarch64-linux-gnu/ && \
        cp /usr/lib/libcrypto.so*       /lib/aarch64-linux-gnu/; \
    elif [ "${arch}" = "x86_64" ]; then \
        cp /usr/lib64/libssl.so*          /lib/x86_64-linux-gnu/ && \
        cp /usr/lib64/libcrypto.so*       /lib/x86_64-linux-gnu/; \
    else \
        echo "Unsupported architecture: ${arch}."; \
        exit 1; \
    fi && \
    ldconfig && \
    rm -rf /workdir

# install python
RUN mkdir -p /workdir && \
    cd /workdir && \
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar zxvf Python-${PYTHON_VERSION}.tgz && \
    cd /workdir/Python-${PYTHON_VERSION} && \
    set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        ./configure \
            --with-openssl=/usr\
            --with-openssl-rpath=/usr/lib64\
            --enable-optimizations; \
    elif [ "${arch}" = "aarch64"  ]; then \
        ./configure \
            --with-openssl=/usr \
            --enable-optimizations; \
    else \
        echo "Unsupported architecture: ${arch}."; \
        exit 1; \
    fi && \
    make && make install && \
    rm -rf /workdir

# verify that python uses the compiled OpenSSL.
CMD [ "python3", "-c", "import ssl; print(ssl.OPENSSL_VERSION)" ]
