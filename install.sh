#!/bin/bash

# The original author of this program, clover-linux-installer, is StarBrilliant.
# This file is released under General Public License version 3.
# You should have received a copy of General Public License text alongside with
# this program. If not, you can obtain it at http://gnu.org/copyleft/gpl.html .
# This program comes with no warranty, the author will not be resopnsible for
# any damage or problems caused by this program.

set -e

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

extract_pkg() {
    for i in "$@"
    do
        echo -ne '\e[1;34m==>\e[0m Extract package '>&2
        echo "$i" >&2
        mkdir "Clover/Clover.pkg/$i"
        gzip -c -d "Clover/Clover.pkg/$i.pkg/Payload" > "Clover/Clover.pkg/$i.cpio"
        7z x -o"Clover/Clover.pkg/$i" "Clover/Clover.pkg/$i.cpio"
    done
}

test_cmd 7z p7zip
test_cmd curl curl
test_cmd dd coreutils
test_cmd gzip gzip
test_cmd mkdir coreutils
test_cmd mount util-linux
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

if [ ! -e Clover.zip ]
then
    log curl -o Clover.zip.part -C - -L https://sourceforge.net/projects/cloverefiboot/files/latest/download
    log mv Clover.zip.part Clover.zip
fi

log sudo umount Clover/work/mnt || true
log rm -rf Clover/
log mkdir Clover
log 7z x -oClover Clover.zip
log mkdir Clover/Clover.pkg
log 7z x -oClover/Clover.pkg Clover/Clover_*.pkg
for pkg in Clover/Clover.pkg/*.pkg
do
    extract_pkg "$(basename "$pkg" .pkg)"
done

log mkdir Clover/work
log cp Clover/Clover.pkg/BiosBoot/usr/standalone/i386/boot0af Clover/work/boot0
log cp Clover/Clover.pkg/BiosBoot/usr/standalone/i386/boot1f32 Clover/work/boot1
log cp Clover/Clover.pkg/BiosBoot/usr/standalone/i386/x64/boot6 Clover/work/boot

log sudo dd if="$TARGET_DISK" bs=512 count=1 >Clover/work/origMBR 
log cp Clover/work/origMBR Clover/work/newMBR
log dd if=Clover/work/boot0 of=Clover/work/newMBR bs=440 count=1 conv=notrunc

log sudo dd if="$TARGET_PARTITION" bs=512 count=1 >Clover/work/origPBR 
log cp Clover/work/boot1 Clover/work/newPBR
log dd if=Clover/work/origPBR of=Clover/work/newPBR skip=3 seek=3 bs=1 count=87 conv=notrunc

log sudo dd if=Clover/work/newMBR of="$TARGET_DISK" bs=512 count=1 conv=notrunc
log sudo dd if=Clover/work/newPBR of="$TARGET_PARTITION" bs=512 count=1 conv=notrunc

log mkdir Clover/work/mnt
log sudo mount -t vfat "$TARGET_PARTITION" Clover/work/mnt
log sudo rm -rf Clover/work/mnt/EFI/CLOVER
log sudo cp Clover/work/boot Clover/work/mnt/
log sudo cp -r Clover/Clover.pkg/EFIFolder/EFI Clover/work/mnt/
log sudo mkdir -p Clover/work/mnt/EFI/CLOVER/drivers64 Clover/work/mnt/EFI/CLOVER/drivers64UEFI
log sudo cp -r Clover/Clover.pkg/black_green/black_green Clover/work/mnt/EFI/CLOVER/themes/
log sudo rm -rf Clover/work/mnt/EFI/CLOVER/themes/embedded
log sudo rm -rf Clover/work/mnt/EFI/CLOVER/themes/random
log sudo umount Clover/work/mnt

echo>&2
echo 'Installation finished successfully.'>&2
