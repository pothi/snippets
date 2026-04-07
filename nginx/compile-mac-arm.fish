#!/usr/bin/env fish

set ver 1.1

# changelog
# 1.1:
#   - date: 2026-04-07
#   - Download OpenSSL, PCRE lib files.
#   - Install nginx locally (as per XDG structure)
# 1.0:
#   - date: 2026-04-02

if not type -q check_status
    function check_status -a return_value error_message
        if test $return_value -ne 0
            echo $error_message
            exit $return_value
        end
    end
end

# set src_dir (mktemp -d)
set src_dir ~/projects/nginx
test -d $src_dir; or mkdir -p $src_dir
set ngx_ver 1.28.3

cd $src_dir
if not test -f nginx-$ngx_ver.tar.gz
    printf '%-72s' 'Downloading nginx source...'
    curl -sSLO https://nginx.org/download/nginx-$ngx_ver.tar.gz
    echo done.
end
printf '%-72s' 'Extracting nginx sources archive...'
tar xf nginx-$ngx_ver.tar.gz
echo done.

cd nginx-$ngx_ver

./configure \
    --prefix=$HOME/.local/nginx \
    --with-openssl=../openssl-3.5.5 \
    --with-pcre=../pcre2-10.47 \
    --sbin-path=$HOME/.local/bin/nginx \
    --conf-path=$HOME/.local/etc/nginx/nginx.conf \
    --error-log-path=$HOME/log/nginx/error.log \
    --http-log-path=$HOME/log/nginx/access.log \
    --user=pothi \
    --group=pothi \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_gzip_static_module \
    --with-debug

# echo Sleeping before making nginx binary...
# sleep 2

make -j$(sysctl -n hw.ncpu)   # Use all CPU cores for faster build
make install
