#!/usr/bin/env fish

set ver 1.0

# changelog
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
set fish_trace on
test -d $src_dir; or mkdir -p $src_dir
set ngx_ver 1.28.3
exit

cd $src_dir
echo Downloading nginx source...
curl -O https://nginx.org/download/nginx-1.28.3.tar.gz
tar xf nginx-$ngx_ver.tar.gz
cd nginx-$ngx_ver


