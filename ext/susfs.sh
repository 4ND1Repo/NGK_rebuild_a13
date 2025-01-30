#!/usr/bin/env bash

EXTDIR="/tmp/ext"
KERNELDIR="/data"

cp -rf $EXTDIR/susfs/ksu/* $KERNELDIR/KernelSU-Next
cp -rf $EXTDIR/susfs/kernel/* $KERNELDIR

patch -p1 -d $KERNELDIR/KernelSU-Next < $KERNELDIR/KernelSU-Next/10_enable_susfs_for_ksu.patch
patch -p1 -d $KERNELDIR < $KERNELDIR/50_add_susfs_in_kernel-4.9.patch
