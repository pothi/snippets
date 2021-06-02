#!/usr/bin/env sh

# Remove i386 from dpkg
# https://wiki.debian.org/Multiarch/HOWTO
# https://askubuntu.com/a/1336013/65814
[ ! $(dpkg -l | grep -q i386) ] && dpkg --remove-architecture i386
