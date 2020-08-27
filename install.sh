#!/bin/bash

# The original author of this program, clover-linux-installer, is StarBrilliant.
# This file is released under General Public License version 3.
# You should have received a copy of General Public License text alongside with
# this program. If not, you can obtain it at http://gnu.org/copyleft/gpl.html .
# This program comes with no warranty, the author will not be resopnsible for
# any damage or problems caused by this program.

set -e

BOOTFILE=boot6

log() {
    echo -ne '\e[1;34m==>\e[0m '>&2
    echo "$*" >&2
    "$@"
}

test_cmd() {
    if which "$1" &>/dev/null
    then
        true
    else
        echo "Error: cannot execute \"$1\", install the package \"$2\"">&2
        exit 2
    fi
}

test_cmd 7z p7zip
test_cmd curl curl
test_cmd dd coreutils
test_cmd gzip gzip
test_cmd mkdir coreutils
test_cmd mount util-linux
test_cmd python3 python3
test_cmd rm coreutils
test_cmd sudo sudo
test_cmd umount util-linux

echo 'Welcome to Clover-Linux-installer.'>&2
echo 'Ensure your target disk has a GPT partition table.'>&2
echo 'Create a FAT32 partition (about 200 MiB) and set it to "EFI System Partition" type.'>&2
echo -n 'Type in your target disk device (e.g. /dev/sdx): '>&2
read TARGET_DISK
echo -n 'Type in your ESP partition device (e.g. /dev/sdx9): '>&2
read TARGET_PARTITION
if [ -z "$TARGET_DISK" -o -z "$TARGET_PARTITION" ]
then
    echo 'Invalid input, quitting.'>&2
    exit 1
fi
echo>&2
echo "You are about to install Clover on disk \"$TARGET_DISK\", partition \"$TARGET_PARTITION\".">&2
echo 'Make sure you backed up your files before you continue, since the author of this installer program will not be responsible for any damage to your device or your files.'>&2
ANSWER=n
while [ "$ANSWER" != "y" ]
do
    echo -n 'Type "y" to continue, type Ctrl-C to quit: '>&2
    read ANSWER
done
echo>&2
echo 'Starting installation.'>&2

if [ ! -e CloverV2.zip ]
then
    log curl -o CloverV2.zip.part -C - -L "$(curl -s -S https://api.github.com/repos/CloverHackyColor/CloverBootloader/releases/latest | python3 ./parse-download-url.py)"
    log mv CloverV2.zip.part CloverV2.zip
fi

log sudo umount Clover/work/mnt || true
log rm -rf Clover/
log mkdir Clover
log 7z x -oClover CloverV2.zip

log mkdir Clover/work
log cp Clover/CloverV2/BootSectors/boot0af Clover/work/boot0
log cp Clover/CloverV2/BootSectors/boot1f32 Clover/work/boot1
log cp Clover/CloverV2/Bootloaders/x64/"$BOOTFILE" Clover/work/boot

log sudo dd if="$TARGET_DISK" bs=512 count=1 >Clover/work/origMBR 
log cp Clover/work/origMBR Clover/work/newMBR
log dd if=Clover/work/boot0 of=Clover/work/newMBR bs=440 count=1 conv=notrunc

log sudo dd if="$TARGET_PARTITION" bs=512 count=1 >Clover/work/origPBR1
log cp Clover/work/boot1 Clover/work/newPBR1
log dd if=Clover/work/origPBR1 of=Clover/work/newPBR1 skip=3 seek=3 bs=1 count=87 conv=notrunc

# Assume the backup boot sector is located at 0xC00.
# Hope you have backed up your important files in caes I guessed it wrong.
log sudo dd if="$TARGET_PARTITION" skip=6 bs=512 count=1 >Clover/work/origPBR2
log cp Clover/work/boot1 Clover/work/newPBR2
log dd if=Clover/work/origPBR2 of=Clover/work/newPBR2 skip=3 seek=3 bs=1 count=87 conv=notrunc

log sudo dd if=Clover/work/newPBR1 of="$TARGET_PARTITION" bs=512 count=1 conv=nocreat,notrunc
log sudo dd if=Clover/work/newPBR2 of="$TARGET_PARTITION" seek=6 bs=512 count=1 conv=nocreat,notrunc
log sudo dd if=Clover/work/newMBR of="$TARGET_DISK" bs=512 count=1 conv=nocreat,notrunc
sleep 2

log mkdir Clover/work/mnt
log sudo mount -t vfat "$TARGET_PARTITION" Clover/work/mnt
log sudo rm -rf Clover/work/mnt/EFI/CLOVER
log sudo cp Clover/work/boot Clover/work/mnt/
log sudo cp -r Clover/CloverV2/EFI Clover/work/mnt/
log sudo umount Clover/work/mnt

echo>&2
echo 'Installation finished successfully.'>&2
