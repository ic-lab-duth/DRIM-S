.globl _start
_start:
li a0,10000
mv sp,a0
jal notmain
hang: j hang
