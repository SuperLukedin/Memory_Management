lab2 notes

1 page = 4096 Bytes


C Functions notes:

`ROUNDUP(x, width)` -> returns a value in a multiple of `width`
`memset(*ptr, x, n)` -> fill the memory from `*ptr` to `(*ptr + n)` with value 'x'


single vertical bar: bitwise OR


variables defined in mmu.h
PDX = page directory index
PADDR = page address
PTE_U user flag
PTE_P present flag
bitwise OR with this flag can add flag into the page address
