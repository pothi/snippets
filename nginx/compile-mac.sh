#!/bin/bash

NGX_VER=1.10.1

OPENSSL_VER="1.0.2h"
OPENSSL_DIR="/Users/pothi/src/openssl-${OPENSSL_VER}"

# nginx doesn't support pcre 2, yet
# PCRE2_VER=10.21
# PCRE_DIR="/Users/pothi/src/pcre2-${PCRE2_VER}"
PCRE_VER=8.38
PCRE_DIR="/Users/pothi/src/pcre-${PCRE_VER}"

CONFIGURE_OPTIONS="
  --with-cc-opt=-m64 --with-ld-opt=-m64
  --prefix=/usr/local/nginx-${NGX_VER}
  --with-pcre=${PCRE_DIR}
  --with-pcre-jit
  --conf-path=/etc/nginx/nginx.conf 
  --error-log-path=/var/log/nginx/error.log 
  --http-log-path=/var/log/nginx/access.log 
  --modules-path=/usr/local/nginx/modules 
  --pid-path=/var/run/nginx.pid 
  --sbin-path=/usr/local/bin/nginx
  --with-http_ssl_module
  --with-openssl=${OPENSSL_DIR}
"

./configure ${CONFIGURE_OPTIONS}

echo 'Sleeping for a few seconds... before making'
sleep 5

export KERNEL_BITS=64
make
