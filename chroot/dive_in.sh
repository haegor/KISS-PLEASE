#!/bin/bash
#
# Предназначен чтобы "нырять" в chroot директорию
#
# 2023 (c) haegor
#

[ -n "$1" ] && dive_dir="$1" || dive_dir='/mnt/dev/'
[ -n "$2" ] && dive_cmd="$2" || dive_cmd='/bin/bash'

sudo chroot "${dive_dir}" "${dive_cmd}"
