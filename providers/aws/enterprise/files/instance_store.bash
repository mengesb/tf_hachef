#!/usr/bin/env bash

# -----------------------------------------------------------------------------
VERSION=1.0
AUTHOR="Brian Menges"
AUTHOR_EMAIL="mengesb@gmail.com"
LICENSE="Apache 2.0"
LICENSE_URL="http://www.apache.org/licenses/LICENSE-2.0"
# -----------------------------------------------------------------------------

PROTECTED_ROOT=$(mount|grep ' / '|cut -d' ' -f 1|sed 's,/dev/,,')

# Usage
usage()
{
  cat <<EOF
  usage: bash $0 [OPTIONS]
  This script will attempt to make use of the local node storage for the VM
  instance

  OPTIONS:
    -y  Use local instance store disk

  OPTIONAL:
    -d  Device name           Default: xvdb
    -f  Filesystem            Default: ext4
    -h  This help message
    -m  Mount point           Default: /mnt/[device_name]
    -o  Mount options         Default: defaults,noatime,errors=remount-ro
    -v  Verbose output

  Licensed under ${LICENSE} (${LICENSE_URL})
  Author : ${AUTHOR} <${AUTHOR_EMAIL}>
  Version: ${VERSION}

EOF
}

while getopts ":d:e:f:m:ohv" OPTION; do
  case "$OPTION" in
    d)
      DEV=${OPTARG}
      ;;
    e)
      case ${OPTARG} in
        true)
          ENABLED=1
          ;;
        1)
          ENABLED=1
          ;;
      esac
      ;;
    f)
      FS=${OPTARG}
      ;;
    h)
      usage && exit 0
      ;;
    m)
      MNT=${OPTARG}
      ;;
    o)
      OPT=${OPTARG}
      ;;
    v)
      set -x
      VERBOSE=1
      ;;
    *)
      usage && exit 1
      ;;
    ?)
      usage && exit 1
      ;;
  esac
done

# Defaults
[[ -z $DEV ]] && DEV=xvdb
[[ -z $FS  ]] && FS=ext4
[[ -z $MNT ]] && MNT=/mnt/$DEV
[[ -z $OPT ]] && OPT='defaults,noatime,errors=remount-ro'

# Requirements check
[[ -z $ENABLED ]] && echo "The safety is still on" && exit 0

[[ $EUID -ne 0 ]] && echo "$0 must be ran as root" && exit 1

if [[ ! -b /dev/$DEV ]]
then
  echo "ERROR: Device not a block device: /dev/$DEV" && exit 1
fi

if [[ $DEV =~ $PROTECTED_ROOT ]]
then
  echo "ERROR: Cannot use root device" && exit 1
fi

# Main

# Setup instance store device
mkfs -t $FS /dev/$DEV

# Mount point setup
mkdir -p ${MNT} /opt /var/opt /var/cache/chef /var/log/chef-backend
mount /dev/${DEV} ${MNT}
mkdir -p /mnt/${DEV}/var/opt /mnt/${DEV}/var/log/chef-backend /mnt/${DEV}/opt /mnt/${DEV}/var/cache/chef
umount /dev/${DEV}

# Update /etc/fstab
sed -i "/$DEV/d" /etc/fstab
echo "
/dev/${DEV}                      ${MNT}         auto ${OPT} 0 0
/mnt/${DEV}/opt                  /opt                  auto defaults,bind 0 0
/mnt/${DEV}/var/cache/chef       /var/cache/chef       auto defaults,bind 0 0
/mnt/${DEV}/var/log/chef-backend /var/log/chef-backend auto defaults,bind 0 0
/mnt/${DEV}/var/opt              /var/opt              auto defaults,bind 0 0
" | tee -a /etc/fstab

# Mount
mount -a
