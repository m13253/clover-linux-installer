Clover-Linux-installer
======================

Install Clover UEFI emulation environment from Linux

## Introduction

[Clover EFI bootloader](https://clover-wiki.zetam.org/Home) contains an UEFI emulation environment, which can be used on older systems without UEFI.

With Clover-Linux-installer, you can easily install Clover onto a GPT partitioned disk from Linux.

## Before you start

Install these packages:

```
curl
gzip
p7zip
p7zip-full or p7zip-plugins (depending on distribution)
sudo
```

Use [GParted](http://gparted.org/) or [cgdisk](http://www.rodsbooks.com/gdisk/) to partition your hard disk.

Create a partition (about 200 MiB), set its type to "EFI System Partiton (0xef00)" and set on it a `boot` flag. Format it as FAT32.

Remember your disk device name (e.g. /dev/sdx) and your EFI System Partition device name (e.g. /dev/sdx9).

Connect to the Internet, because the installer will download the latest Clover as `CloverV2.zip`.

## Installing on a disk

You do not have to switch to root user, but you must make "sudo" available.

Type `./install.sh`, it might look like this:

```
Welcome to Clover-Linux-installer.
Ensure your target disk has a GPT partition table.
Create a FAT32 partition (about 200 MiB) and set it to "EFI System Partition"
type.
Type in your target disk device (e.g. /dev/sdx): /dev/sdx
Type in your ESP partition device (e.g. /dev/sdx9): /dev/sdx9

You are about to install Clover on disk "/dev/sdx", partition "/dev/sdx9".
Make sure you backed up your files before you continue, since the author of this
installer program will not be responsible for any damage to your device or your
files.
Type "y" to continue, type Ctrl-C to quit: y

Starting installation.

...

Installation finished successfully.
```

## Or, installing on a disk image

Install these packages:

```
gdisk
multipath-tools (for kpartx)
```

Here is an example session:

```bash
# Allocate 512 MiB for your disk image
fallocate -l 512M image.img
# Alternatively you can use truncate -s 512M image.img

# Partition the disk image
gdisk image.img
  Command (? for help): n
  Partition number (1-128, default 1): 1
  First sector (34-1048542, default = 2048) or {+-}size{KMGTP}: 2048
  Last sector (2048-1048542, default = 1048542) or {+-}size{KMGTP}: +256M
  Hex code or GUID (L to show codes, Enter = 8300): ef00
  Command (? for help): w
  Do you want to proceed? (Y/N): y

# Attach the loopback device
sudo losetup -f image.img
losetup
  NAME       SIZELIMIT OFFSET AUTOCLEAR RO BACK-FILE DIO
  /dev/loop9         0      0         0  0 image.img   0
sudo kpartx -av /dev/loop9
# If kpartx does not work, you can also try losetup with "-P".

# Format the EFI System Partition
sudo mkfs -t vfat -n EFI -F 32 /dev/mapper/loop9p1

# Install Clover
./install.sh
  Type in your target disk device (e.g. /dev/sdx): /dev/loop9
  Type in your ESP partition device (e.g. /dev/sdx9): /dev/mapper/loop9p1

# Detach the loopback device
sudo kpartx -dv /dev/loop9
sudo losetup -d /dev/loop9
```


## For some buggy BIOS

For some buggy BIOS where `BiosBlockIO` is needed, search `install.sh` for `BOOTFILE=boot6` and replace with `BOOTFILE=boot7`.


## License

The original author of this program, clover-linux-installer, is StarBrilliant.

This program is released under General Public License version 3.

You should have received a copy of General Public License text alongside with this program. If not, you can obtain it at <http://gnu.org/copyleft/gpl.html>.

This program comes with no warranty, the author will not be resopnsible for any damage or problems caused by this program.
