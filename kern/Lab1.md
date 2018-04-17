# lab 1


1. Create local git repo.

(in home directory)
```
mkdir ~/6.828
cd ~/6.828
~~add git~~
git clone https://pdos.csail.mit.edu/6.828/2017/jos.git lab
cd lab
```

install package to support 32-bit system
`sudo apt-get install gcc-multilib`

edit the conf/env.mk file in the jos folder
QEMU = YOUR_PATH/bin/qemu-system-i386
(delete the # sign)

(in lab directory)
`make`
