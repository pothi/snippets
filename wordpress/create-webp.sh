#!/bin/bash

# requirements: webp (sudo apt install webp or yum install webp)
# version 1.4

# version: 1.4
#   - date: 2022-06-01
#   - check for webp executive
# version 1.3
#   - date: 2020-05-28
#   - change the logic litte bit to make the output less noisy
# version 1.2
#   - date: 2020-05-28
#   - example for cron usage
# version 1.1
#   - date: 2020-05-28
#   - change default quality to 82 (copied from ewww)
#   - sleep only when webp conversion takes place
# version 1.0
#   - none.

# usage example
# ~/path/to/create_webp.sh ~/sites/example.com/public/wp-content/uploads/$(date +\%Y)/$(date +\%m)

quality=82
sleep_time=1

if [ "$1" == "" ]; then
    echo "Usage $0 directory to process"
fi

[ ! -f /usr/bin/cwebp ] && echo "Couldn't find webp executive. Please install using 'sudo apt/yum install webp'." && exit 1

files=$(find $1 -type f -size +10k -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg')

echo
for file in $files; do
    if [ -f $file ]; then
        if [ ! -f "$file.webp" ]; then
            /usr/bin/cwebp -q $quality $file -o "$file.webp"
            echo Sleeping for $sleep_time seconds before processing next file...
            sleep $sleep_time
            echo
        # else
            # echo "Webp file already exists for $file."
        fi
    fi
done

