# OS_Design_Proj
CS630 Group Project


Setting up environments
- need to install two tools
  1. QEMU, an x86 emulator
  2. compiler toolchain
  
# 1. QEMU
Need to download the MIT version of QEMU using Git

(1.0) install linux 64 on Win 10 requires [changing BIOS option] (https://www.laptopmag.com/articles/access-bios-windows-10):

1.1 Install Git:
```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install git
```

1.2 clone QEMU from MIT repo
`git clone http://web.mit.edu/ccutler/www/qemu.git -b 6.828-2.3.0`

1.3 install libraries
```
sudo apt-get install libsdl1.2-dev
sudo apt-get install libtool-bin
sudo apt-get install libglib2.0-dev
sudo apt-get install libz-dev
sudo apt-get install libpixman-1-dev
```

1.4 configure (linux)
```
cd qemu
./configure --disable-kvm [--prefix="/home/**YOUR_USERNAME**/qemu" --target-list="i386-softmmu x86_64-softmmu"
```

1.5 `make && make install`




# 2. Compiler toolchain
For linux machine, these should be readily available.
type command in VM Linux terminal:

`objdump -i`   should print a table with 2nd line = `elf32-i386`

`gcc -m32 -print-libgcc-file-name`   should print a directory start with `/user/lib` and end with `/libgcc.a`

