
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 49 11 f0       	mov    $0xf0114970,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 a3 1e 00 00       	call   f0101f00 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 a0 23 10 f0       	push   $0xf01023a0
f010006f:	e8 d3 13 00 00       	call   f0101447 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 ed 0c 00 00       	call   f0100d66 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 ae 06 00 00       	call   f0100734 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 49 11 f0 00 	cmpl   $0x0,0xf0114960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 49 11 f0    	mov    %esi,0xf0114960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 bb 23 10 f0       	push   $0xf01023bb
f01000b5:	e8 8d 13 00 00       	call   f0101447 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 5d 13 00 00       	call   f0101421 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 f7 23 10 f0 	movl   $0xf01023f7,(%esp)
f01000cb:	e8 77 13 00 00       	call   f0101447 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 57 06 00 00       	call   f0100734 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 d3 23 10 f0       	push   $0xf01023d3
f01000f7:	e8 4b 13 00 00       	call   f0101447 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 19 13 00 00       	call   f0101421 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 f7 23 10 f0 	movl   $0xf01023f7,(%esp)
f010010f:	e8 33 13 00 00       	call   f0101447 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100159:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 40 25 10 f0 	movzbl -0xfefdac0(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 40 25 10 f0 	movzbl -0xfefdac0(%edx),%eax
f0100211:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f0100217:	0f b6 8a 40 24 10 f0 	movzbl -0xfefdbc0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 20 24 10 f0 	mov    -0xfefdbe0(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 ed 23 10 f0       	push   $0xf01023ed
f010026d:	e8 d5 11 00 00       	call   f0101447 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 45 11 f0 	mov    %dx,0xf0114528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 2c 1b 00 00       	call   f0101f4d <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 45 11 f0       	mov    0xf0114520,%eax
f01004c3:	3b 05 24 45 11 f0    	cmp    0xf0114524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 45 11 f0    	mov    %edx,0xf0114520
f01004d4:	0f b6 88 20 43 11 f0 	movzbl -0xfeebce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 45 11 f0 	setne  0xf0114534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 f9 23 10 f0       	push   $0xf01023f9
f01005f0:	e8 52 0e 00 00       	call   f0101447 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010062e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100633:	5d                   	pop    %ebp
f0100634:	c3                   	ret    

f0100635 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100635:	55                   	push   %ebp
f0100636:	89 e5                	mov    %esp,%ebp
f0100638:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010063b:	68 40 26 10 f0       	push   $0xf0102640
f0100640:	68 5e 26 10 f0       	push   $0xf010265e
f0100645:	68 63 26 10 f0       	push   $0xf0102663
f010064a:	e8 f8 0d 00 00       	call   f0101447 <cprintf>
f010064f:	83 c4 0c             	add    $0xc,%esp
f0100652:	68 d4 26 10 f0       	push   $0xf01026d4
f0100657:	68 6c 26 10 f0       	push   $0xf010266c
f010065c:	68 63 26 10 f0       	push   $0xf0102663
f0100661:	e8 e1 0d 00 00       	call   f0101447 <cprintf>
f0100666:	83 c4 0c             	add    $0xc,%esp
f0100669:	68 fc 26 10 f0       	push   $0xf01026fc
f010066e:	68 75 26 10 f0       	push   $0xf0102675
f0100673:	68 63 26 10 f0       	push   $0xf0102663
f0100678:	e8 ca 0d 00 00       	call   f0101447 <cprintf>
	return 0;
}
f010067d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100682:	c9                   	leave  
f0100683:	c3                   	ret    

f0100684 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100684:	55                   	push   %ebp
f0100685:	89 e5                	mov    %esp,%ebp
f0100687:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010068a:	68 7f 26 10 f0       	push   $0xf010267f
f010068f:	e8 b3 0d 00 00       	call   f0101447 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100694:	83 c4 08             	add    $0x8,%esp
f0100697:	68 0c 00 10 00       	push   $0x10000c
f010069c:	68 28 27 10 f0       	push   $0xf0102728
f01006a1:	e8 a1 0d 00 00       	call   f0101447 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a6:	83 c4 0c             	add    $0xc,%esp
f01006a9:	68 0c 00 10 00       	push   $0x10000c
f01006ae:	68 0c 00 10 f0       	push   $0xf010000c
f01006b3:	68 50 27 10 f0       	push   $0xf0102750
f01006b8:	e8 8a 0d 00 00       	call   f0101447 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006bd:	83 c4 0c             	add    $0xc,%esp
f01006c0:	68 91 23 10 00       	push   $0x102391
f01006c5:	68 91 23 10 f0       	push   $0xf0102391
f01006ca:	68 74 27 10 f0       	push   $0xf0102774
f01006cf:	e8 73 0d 00 00       	call   f0101447 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006d4:	83 c4 0c             	add    $0xc,%esp
f01006d7:	68 00 43 11 00       	push   $0x114300
f01006dc:	68 00 43 11 f0       	push   $0xf0114300
f01006e1:	68 98 27 10 f0       	push   $0xf0102798
f01006e6:	e8 5c 0d 00 00       	call   f0101447 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006eb:	83 c4 0c             	add    $0xc,%esp
f01006ee:	68 70 49 11 00       	push   $0x114970
f01006f3:	68 70 49 11 f0       	push   $0xf0114970
f01006f8:	68 bc 27 10 f0       	push   $0xf01027bc
f01006fd:	e8 45 0d 00 00       	call   f0101447 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100702:	b8 6f 4d 11 f0       	mov    $0xf0114d6f,%eax
f0100707:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010070c:	83 c4 08             	add    $0x8,%esp
f010070f:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100714:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010071a:	85 c0                	test   %eax,%eax
f010071c:	0f 48 c2             	cmovs  %edx,%eax
f010071f:	c1 f8 0a             	sar    $0xa,%eax
f0100722:	50                   	push   %eax
f0100723:	68 e0 27 10 f0       	push   $0xf01027e0
f0100728:	e8 1a 0d 00 00       	call   f0101447 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010072d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100732:	c9                   	leave  
f0100733:	c3                   	ret    

f0100734 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100734:	55                   	push   %ebp
f0100735:	89 e5                	mov    %esp,%ebp
f0100737:	57                   	push   %edi
f0100738:	56                   	push   %esi
f0100739:	53                   	push   %ebx
f010073a:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010073d:	68 0c 28 10 f0       	push   $0xf010280c
f0100742:	e8 00 0d 00 00       	call   f0101447 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100747:	c7 04 24 30 28 10 f0 	movl   $0xf0102830,(%esp)
f010074e:	e8 f4 0c 00 00       	call   f0101447 <cprintf>
f0100753:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100756:	83 ec 0c             	sub    $0xc,%esp
f0100759:	68 98 26 10 f0       	push   $0xf0102698
f010075e:	e8 46 15 00 00       	call   f0101ca9 <readline>
f0100763:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100765:	83 c4 10             	add    $0x10,%esp
f0100768:	85 c0                	test   %eax,%eax
f010076a:	74 ea                	je     f0100756 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010076c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100773:	be 00 00 00 00       	mov    $0x0,%esi
f0100778:	eb 0a                	jmp    f0100784 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010077a:	c6 03 00             	movb   $0x0,(%ebx)
f010077d:	89 f7                	mov    %esi,%edi
f010077f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100782:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100784:	0f b6 03             	movzbl (%ebx),%eax
f0100787:	84 c0                	test   %al,%al
f0100789:	74 63                	je     f01007ee <monitor+0xba>
f010078b:	83 ec 08             	sub    $0x8,%esp
f010078e:	0f be c0             	movsbl %al,%eax
f0100791:	50                   	push   %eax
f0100792:	68 9c 26 10 f0       	push   $0xf010269c
f0100797:	e8 27 17 00 00       	call   f0101ec3 <strchr>
f010079c:	83 c4 10             	add    $0x10,%esp
f010079f:	85 c0                	test   %eax,%eax
f01007a1:	75 d7                	jne    f010077a <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01007a3:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007a6:	74 46                	je     f01007ee <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007a8:	83 fe 0f             	cmp    $0xf,%esi
f01007ab:	75 14                	jne    f01007c1 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007ad:	83 ec 08             	sub    $0x8,%esp
f01007b0:	6a 10                	push   $0x10
f01007b2:	68 a1 26 10 f0       	push   $0xf01026a1
f01007b7:	e8 8b 0c 00 00       	call   f0101447 <cprintf>
f01007bc:	83 c4 10             	add    $0x10,%esp
f01007bf:	eb 95                	jmp    f0100756 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007c1:	8d 7e 01             	lea    0x1(%esi),%edi
f01007c4:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007c8:	eb 03                	jmp    f01007cd <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007ca:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007cd:	0f b6 03             	movzbl (%ebx),%eax
f01007d0:	84 c0                	test   %al,%al
f01007d2:	74 ae                	je     f0100782 <monitor+0x4e>
f01007d4:	83 ec 08             	sub    $0x8,%esp
f01007d7:	0f be c0             	movsbl %al,%eax
f01007da:	50                   	push   %eax
f01007db:	68 9c 26 10 f0       	push   $0xf010269c
f01007e0:	e8 de 16 00 00       	call   f0101ec3 <strchr>
f01007e5:	83 c4 10             	add    $0x10,%esp
f01007e8:	85 c0                	test   %eax,%eax
f01007ea:	74 de                	je     f01007ca <monitor+0x96>
f01007ec:	eb 94                	jmp    f0100782 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01007ee:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007f5:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007f6:	85 f6                	test   %esi,%esi
f01007f8:	0f 84 58 ff ff ff    	je     f0100756 <monitor+0x22>
f01007fe:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100803:	83 ec 08             	sub    $0x8,%esp
f0100806:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100809:	ff 34 85 60 28 10 f0 	pushl  -0xfefd7a0(,%eax,4)
f0100810:	ff 75 a8             	pushl  -0x58(%ebp)
f0100813:	e8 4d 16 00 00       	call   f0101e65 <strcmp>
f0100818:	83 c4 10             	add    $0x10,%esp
f010081b:	85 c0                	test   %eax,%eax
f010081d:	75 21                	jne    f0100840 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f010081f:	83 ec 04             	sub    $0x4,%esp
f0100822:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100825:	ff 75 08             	pushl  0x8(%ebp)
f0100828:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010082b:	52                   	push   %edx
f010082c:	56                   	push   %esi
f010082d:	ff 14 85 68 28 10 f0 	call   *-0xfefd798(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100834:	83 c4 10             	add    $0x10,%esp
f0100837:	85 c0                	test   %eax,%eax
f0100839:	78 25                	js     f0100860 <monitor+0x12c>
f010083b:	e9 16 ff ff ff       	jmp    f0100756 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100840:	83 c3 01             	add    $0x1,%ebx
f0100843:	83 fb 03             	cmp    $0x3,%ebx
f0100846:	75 bb                	jne    f0100803 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100848:	83 ec 08             	sub    $0x8,%esp
f010084b:	ff 75 a8             	pushl  -0x58(%ebp)
f010084e:	68 be 26 10 f0       	push   $0xf01026be
f0100853:	e8 ef 0b 00 00       	call   f0101447 <cprintf>
f0100858:	83 c4 10             	add    $0x10,%esp
f010085b:	e9 f6 fe ff ff       	jmp    f0100756 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100860:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100863:	5b                   	pop    %ebx
f0100864:	5e                   	pop    %esi
f0100865:	5f                   	pop    %edi
f0100866:	5d                   	pop    %ebp
f0100867:	c3                   	ret    

f0100868 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100868:	55                   	push   %ebp
f0100869:	89 e5                	mov    %esp,%ebp
f010086b:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010086d:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f0100874:	75 0f                	jne    f0100885 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); //round up to the nearest address
f0100876:	b8 6f 59 11 f0       	mov    $0xf011596f,%eax
f010087b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100880:	a3 38 45 11 f0       	mov    %eax,0xf0114538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;  
f0100885:	a1 38 45 11 f0       	mov    0xf0114538,%eax
  	nextfree += ROUNDUP(n,PGSIZE);  
f010088a:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100890:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100896:	01 c2                	add    %eax,%edx
f0100898:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
   	return result;
}
f010089e:	5d                   	pop    %ebp
f010089f:	c3                   	ret    

f01008a0 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008a0:	55                   	push   %ebp
f01008a1:	89 e5                	mov    %esp,%ebp
f01008a3:	56                   	push   %esi
f01008a4:	53                   	push   %ebx
f01008a5:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008a7:	83 ec 0c             	sub    $0xc,%esp
f01008aa:	50                   	push   %eax
f01008ab:	e8 30 0b 00 00       	call   f01013e0 <mc146818_read>
f01008b0:	89 c6                	mov    %eax,%esi
f01008b2:	83 c3 01             	add    $0x1,%ebx
f01008b5:	89 1c 24             	mov    %ebx,(%esp)
f01008b8:	e8 23 0b 00 00       	call   f01013e0 <mc146818_read>
f01008bd:	c1 e0 08             	shl    $0x8,%eax
f01008c0:	09 f0                	or     %esi,%eax
}
f01008c2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008c5:	5b                   	pop    %ebx
f01008c6:	5e                   	pop    %esi
f01008c7:	5d                   	pop    %ebp
f01008c8:	c3                   	ret    

f01008c9 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01008c9:	89 d1                	mov    %edx,%ecx
f01008cb:	c1 e9 16             	shr    $0x16,%ecx
f01008ce:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01008d1:	a8 01                	test   $0x1,%al
f01008d3:	74 52                	je     f0100927 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01008d5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008da:	89 c1                	mov    %eax,%ecx
f01008dc:	c1 e9 0c             	shr    $0xc,%ecx
f01008df:	3b 0d 64 49 11 f0    	cmp    0xf0114964,%ecx
f01008e5:	72 1b                	jb     f0100902 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01008e7:	55                   	push   %ebp
f01008e8:	89 e5                	mov    %esp,%ebp
f01008ea:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01008ed:	50                   	push   %eax
f01008ee:	68 84 28 10 f0       	push   $0xf0102884
f01008f3:	68 b0 02 00 00       	push   $0x2b0
f01008f8:	68 60 2a 10 f0       	push   $0xf0102a60
f01008fd:	e8 89 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100902:	c1 ea 0c             	shr    $0xc,%edx
f0100905:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010090b:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100912:	89 c2                	mov    %eax,%edx
f0100914:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100917:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010091c:	85 d2                	test   %edx,%edx
f010091e:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100923:	0f 44 c2             	cmove  %edx,%eax
f0100926:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100927:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f010092c:	c3                   	ret    

f010092d <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f010092d:	55                   	push   %ebp
f010092e:	89 e5                	mov    %esp,%ebp
f0100930:	57                   	push   %edi
f0100931:	56                   	push   %esi
f0100932:	53                   	push   %ebx
f0100933:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100936:	84 c0                	test   %al,%al
f0100938:	0f 85 81 02 00 00    	jne    f0100bbf <check_page_free_list+0x292>
f010093e:	e9 8e 02 00 00       	jmp    f0100bd1 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100943:	83 ec 04             	sub    $0x4,%esp
f0100946:	68 a8 28 10 f0       	push   $0xf01028a8
f010094b:	68 f1 01 00 00       	push   $0x1f1
f0100950:	68 60 2a 10 f0       	push   $0xf0102a60
f0100955:	e8 31 f7 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010095a:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010095d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100960:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100963:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100966:	89 c2                	mov    %eax,%edx
f0100968:	2b 15 6c 49 11 f0    	sub    0xf011496c,%edx
f010096e:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100974:	0f 95 c2             	setne  %dl
f0100977:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f010097a:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f010097e:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100980:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100984:	8b 00                	mov    (%eax),%eax
f0100986:	85 c0                	test   %eax,%eax
f0100988:	75 dc                	jne    f0100966 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f010098a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010098d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100993:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100996:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100999:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f010099b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010099e:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009a3:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009a8:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f01009ae:	eb 53                	jmp    f0100a03 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009b0:	89 d8                	mov    %ebx,%eax
f01009b2:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f01009b8:	c1 f8 03             	sar    $0x3,%eax
f01009bb:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01009be:	89 c2                	mov    %eax,%edx
f01009c0:	c1 ea 16             	shr    $0x16,%edx
f01009c3:	39 f2                	cmp    %esi,%edx
f01009c5:	73 3a                	jae    f0100a01 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009c7:	89 c2                	mov    %eax,%edx
f01009c9:	c1 ea 0c             	shr    $0xc,%edx
f01009cc:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f01009d2:	72 12                	jb     f01009e6 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009d4:	50                   	push   %eax
f01009d5:	68 84 28 10 f0       	push   $0xf0102884
f01009da:	6a 52                	push   $0x52
f01009dc:	68 6c 2a 10 f0       	push   $0xf0102a6c
f01009e1:	e8 a5 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f01009e6:	83 ec 04             	sub    $0x4,%esp
f01009e9:	68 80 00 00 00       	push   $0x80
f01009ee:	68 97 00 00 00       	push   $0x97
f01009f3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01009f8:	50                   	push   %eax
f01009f9:	e8 02 15 00 00       	call   f0101f00 <memset>
f01009fe:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a01:	8b 1b                	mov    (%ebx),%ebx
f0100a03:	85 db                	test   %ebx,%ebx
f0100a05:	75 a9                	jne    f01009b0 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a07:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a0c:	e8 57 fe ff ff       	call   f0100868 <boot_alloc>
f0100a11:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a14:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a1a:	8b 0d 6c 49 11 f0    	mov    0xf011496c,%ecx
		assert(pp < pages + npages);
f0100a20:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100a25:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a28:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a2b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a2e:	be 00 00 00 00       	mov    $0x0,%esi
f0100a33:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a36:	e9 30 01 00 00       	jmp    f0100b6b <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a3b:	39 ca                	cmp    %ecx,%edx
f0100a3d:	73 19                	jae    f0100a58 <check_page_free_list+0x12b>
f0100a3f:	68 7a 2a 10 f0       	push   $0xf0102a7a
f0100a44:	68 86 2a 10 f0       	push   $0xf0102a86
f0100a49:	68 0b 02 00 00       	push   $0x20b
f0100a4e:	68 60 2a 10 f0       	push   $0xf0102a60
f0100a53:	e8 33 f6 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100a58:	39 fa                	cmp    %edi,%edx
f0100a5a:	72 19                	jb     f0100a75 <check_page_free_list+0x148>
f0100a5c:	68 9b 2a 10 f0       	push   $0xf0102a9b
f0100a61:	68 86 2a 10 f0       	push   $0xf0102a86
f0100a66:	68 0c 02 00 00       	push   $0x20c
f0100a6b:	68 60 2a 10 f0       	push   $0xf0102a60
f0100a70:	e8 16 f6 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a75:	89 d0                	mov    %edx,%eax
f0100a77:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a7a:	a8 07                	test   $0x7,%al
f0100a7c:	74 19                	je     f0100a97 <check_page_free_list+0x16a>
f0100a7e:	68 cc 28 10 f0       	push   $0xf01028cc
f0100a83:	68 86 2a 10 f0       	push   $0xf0102a86
f0100a88:	68 0d 02 00 00       	push   $0x20d
f0100a8d:	68 60 2a 10 f0       	push   $0xf0102a60
f0100a92:	e8 f4 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a97:	c1 f8 03             	sar    $0x3,%eax
f0100a9a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100a9d:	85 c0                	test   %eax,%eax
f0100a9f:	75 19                	jne    f0100aba <check_page_free_list+0x18d>
f0100aa1:	68 af 2a 10 f0       	push   $0xf0102aaf
f0100aa6:	68 86 2a 10 f0       	push   $0xf0102a86
f0100aab:	68 10 02 00 00       	push   $0x210
f0100ab0:	68 60 2a 10 f0       	push   $0xf0102a60
f0100ab5:	e8 d1 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100aba:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100abf:	75 19                	jne    f0100ada <check_page_free_list+0x1ad>
f0100ac1:	68 c0 2a 10 f0       	push   $0xf0102ac0
f0100ac6:	68 86 2a 10 f0       	push   $0xf0102a86
f0100acb:	68 11 02 00 00       	push   $0x211
f0100ad0:	68 60 2a 10 f0       	push   $0xf0102a60
f0100ad5:	e8 b1 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ada:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100adf:	75 19                	jne    f0100afa <check_page_free_list+0x1cd>
f0100ae1:	68 00 29 10 f0       	push   $0xf0102900
f0100ae6:	68 86 2a 10 f0       	push   $0xf0102a86
f0100aeb:	68 12 02 00 00       	push   $0x212
f0100af0:	68 60 2a 10 f0       	push   $0xf0102a60
f0100af5:	e8 91 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100afa:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100aff:	75 19                	jne    f0100b1a <check_page_free_list+0x1ed>
f0100b01:	68 d9 2a 10 f0       	push   $0xf0102ad9
f0100b06:	68 86 2a 10 f0       	push   $0xf0102a86
f0100b0b:	68 13 02 00 00       	push   $0x213
f0100b10:	68 60 2a 10 f0       	push   $0xf0102a60
f0100b15:	e8 71 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b1a:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b1f:	76 3f                	jbe    f0100b60 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b21:	89 c3                	mov    %eax,%ebx
f0100b23:	c1 eb 0c             	shr    $0xc,%ebx
f0100b26:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b29:	77 12                	ja     f0100b3d <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b2b:	50                   	push   %eax
f0100b2c:	68 84 28 10 f0       	push   $0xf0102884
f0100b31:	6a 52                	push   $0x52
f0100b33:	68 6c 2a 10 f0       	push   $0xf0102a6c
f0100b38:	e8 4e f5 ff ff       	call   f010008b <_panic>
f0100b3d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b42:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b45:	76 1e                	jbe    f0100b65 <check_page_free_list+0x238>
f0100b47:	68 24 29 10 f0       	push   $0xf0102924
f0100b4c:	68 86 2a 10 f0       	push   $0xf0102a86
f0100b51:	68 14 02 00 00       	push   $0x214
f0100b56:	68 60 2a 10 f0       	push   $0xf0102a60
f0100b5b:	e8 2b f5 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100b60:	83 c6 01             	add    $0x1,%esi
f0100b63:	eb 04                	jmp    f0100b69 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100b65:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b69:	8b 12                	mov    (%edx),%edx
f0100b6b:	85 d2                	test   %edx,%edx
f0100b6d:	0f 85 c8 fe ff ff    	jne    f0100a3b <check_page_free_list+0x10e>
f0100b73:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100b76:	85 f6                	test   %esi,%esi
f0100b78:	7f 19                	jg     f0100b93 <check_page_free_list+0x266>
f0100b7a:	68 f3 2a 10 f0       	push   $0xf0102af3
f0100b7f:	68 86 2a 10 f0       	push   $0xf0102a86
f0100b84:	68 1c 02 00 00       	push   $0x21c
f0100b89:	68 60 2a 10 f0       	push   $0xf0102a60
f0100b8e:	e8 f8 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100b93:	85 db                	test   %ebx,%ebx
f0100b95:	7f 19                	jg     f0100bb0 <check_page_free_list+0x283>
f0100b97:	68 05 2b 10 f0       	push   $0xf0102b05
f0100b9c:	68 86 2a 10 f0       	push   $0xf0102a86
f0100ba1:	68 1d 02 00 00       	push   $0x21d
f0100ba6:	68 60 2a 10 f0       	push   $0xf0102a60
f0100bab:	e8 db f4 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100bb0:	83 ec 0c             	sub    $0xc,%esp
f0100bb3:	68 6c 29 10 f0       	push   $0xf010296c
f0100bb8:	e8 8a 08 00 00       	call   f0101447 <cprintf>
}
f0100bbd:	eb 29                	jmp    f0100be8 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bbf:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100bc4:	85 c0                	test   %eax,%eax
f0100bc6:	0f 85 8e fd ff ff    	jne    f010095a <check_page_free_list+0x2d>
f0100bcc:	e9 72 fd ff ff       	jmp    f0100943 <check_page_free_list+0x16>
f0100bd1:	83 3d 3c 45 11 f0 00 	cmpl   $0x0,0xf011453c
f0100bd8:	0f 84 65 fd ff ff    	je     f0100943 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bde:	be 00 04 00 00       	mov    $0x400,%esi
f0100be3:	e9 c0 fd ff ff       	jmp    f01009a8 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100be8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100beb:	5b                   	pop    %ebx
f0100bec:	5e                   	pop    %esi
f0100bed:	5f                   	pop    %edi
f0100bee:	5d                   	pop    %ebp
f0100bef:	c3                   	ret    

f0100bf0 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100bf0:	55                   	push   %ebp
f0100bf1:	89 e5                	mov    %esp,%ebp
f0100bf3:	57                   	push   %edi
f0100bf4:	56                   	push   %esi
f0100bf5:	53                   	push   %ebx
f0100bf6:	83 ec 04             	sub    $0x4,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
    	uint32_t nextfree = (uint32_t)boot_alloc(0);
f0100bf9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bfe:	e8 65 fc ff ff       	call   f0100868 <boot_alloc>
    	//cprintf("1 %d \r\n", nextfree);
    	nextfree -= KERNBASE;
    	//pages[1].pp_link = 0;
    	//int lower_p = IOPHYSMEM;
    	//int upper_p = ROUNDUP (nextfree,PGSIZE);
    	page_free_list = &pages[1];
f0100c03:	8b 35 6c 49 11 f0    	mov    0xf011496c,%esi
f0100c09:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100c0c:	89 1d 3c 45 11 f0    	mov    %ebx,0xf011453c
    	int lower_p = PGNUM (IOPHYSMEM);
    	int upper_p = PGNUM (ROUNDUP (nextfree,PGSIZE)) ;
f0100c12:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100c17:	c1 e8 0c             	shr    $0xc,%eax
        	{
            	pages[i].pp_ref = 0;
            	continue;
        	}
	
        	if(i >= 2 && i < npages_basemem ) 
f0100c1a:	8b 35 40 45 11 f0    	mov    0xf0114540,%esi
    	int lower_p = PGNUM (IOPHYSMEM);
    	int upper_p = PGNUM (ROUNDUP (nextfree,PGSIZE)) ;
    	//cprintf("page_init\r\n");
    	//cprintf("2 %d \r\n", upper_p);
	
   	 for (i = 0; i < npages; i++) {
f0100c20:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c25:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c2a:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c2f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100c32:	eb 74                	jmp    f0100ca8 <page_init+0xb8>

        	if(i == 0  || i == 1) 
f0100c34:	83 fa 01             	cmp    $0x1,%edx
f0100c37:	77 0e                	ja     f0100c47 <page_init+0x57>
        	{
            	pages[i].pp_ref = 0;
f0100c39:	a1 6c 49 11 f0       	mov    0xf011496c,%eax
f0100c3e:	66 c7 44 08 04 00 00 	movw   $0x0,0x4(%eax,%ecx,1)
            	continue;
f0100c45:	eb 5b                	jmp    f0100ca2 <page_init+0xb2>
        	}
	
        	if(i >= 2 && i < npages_basemem ) 
f0100c47:	39 f2                	cmp    %esi,%edx
f0100c49:	73 1f                	jae    f0100c6a <page_init+0x7a>
        	{
            	pages[i].pp_ref = 0;
f0100c4b:	89 c8                	mov    %ecx,%eax
f0100c4d:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f0100c53:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
            	pages[i].pp_link = page_free_list;
f0100c59:	89 18                	mov    %ebx,(%eax)
            	page_free_list = &pages[i];
f0100c5b:	89 cb                	mov    %ecx,%ebx
f0100c5d:	03 1d 6c 49 11 f0    	add    0xf011496c,%ebx
       	     	continue;
f0100c63:	bf 01 00 00 00       	mov    $0x1,%edi
f0100c68:	eb 38                	jmp    f0100ca2 <page_init+0xb2>
        	}	
		
        	if(lower_p <= i && i < upper_p)
f0100c6a:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0100c70:	76 13                	jbe    f0100c85 <page_init+0x95>
f0100c72:	3b 55 f0             	cmp    -0x10(%ebp),%edx
f0100c75:	73 0e                	jae    f0100c85 <page_init+0x95>
        	{
           	 pages[i].pp_ref = 1;
f0100c77:	a1 6c 49 11 f0       	mov    0xf011496c,%eax
f0100c7c:	66 c7 44 08 04 01 00 	movw   $0x1,0x4(%eax,%ecx,1)
           	 continue;
f0100c83:	eb 1d                	jmp    f0100ca2 <page_init+0xb2>
        	}
        	else
        	{   
            	pages[i].pp_ref = 0;        
f0100c85:	89 c8                	mov    %ecx,%eax
f0100c87:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f0100c8d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
            	pages[i].pp_link = page_free_list;
f0100c93:	89 18                	mov    %ebx,(%eax)
            	page_free_list = &pages[i];
f0100c95:	89 cb                	mov    %ecx,%ebx
f0100c97:	03 1d 6c 49 11 f0    	add    0xf011496c,%ebx
f0100c9d:	bf 01 00 00 00       	mov    $0x1,%edi
    	int lower_p = PGNUM (IOPHYSMEM);
    	int upper_p = PGNUM (ROUNDUP (nextfree,PGSIZE)) ;
    	//cprintf("page_init\r\n");
    	//cprintf("2 %d \r\n", upper_p);
	
   	 for (i = 0; i < npages; i++) {
f0100ca2:	83 c2 01             	add    $0x1,%edx
f0100ca5:	83 c1 08             	add    $0x8,%ecx
f0100ca8:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f0100cae:	72 84                	jb     f0100c34 <page_init+0x44>
f0100cb0:	89 f8                	mov    %edi,%eax
f0100cb2:	84 c0                	test   %al,%al
f0100cb4:	74 06                	je     f0100cbc <page_init+0xcc>
f0100cb6:	89 1d 3c 45 11 f0    	mov    %ebx,0xf011453c
            	pages[i].pp_ref = 0;        
            	pages[i].pp_link = page_free_list;
            	page_free_list = &pages[i];
        	}
   	 }
}
f0100cbc:	83 c4 04             	add    $0x4,%esp
f0100cbf:	5b                   	pop    %ebx
f0100cc0:	5e                   	pop    %esi
f0100cc1:	5f                   	pop    %edi
f0100cc2:	5d                   	pop    %ebp
f0100cc3:	c3                   	ret    

f0100cc4 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100cc4:	55                   	push   %ebp
f0100cc5:	89 e5                	mov    %esp,%ebp
f0100cc7:	53                   	push   %ebx
f0100cc8:	83 ec 04             	sub    $0x4,%esp
	if (page_free_list == NULL)
f0100ccb:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100cd1:	85 db                	test   %ebx,%ebx
f0100cd3:	74 52                	je     f0100d27 <page_alloc+0x63>
        return NULL;

    	struct PageInfo *res = page_free_list;
    	page_free_list = page_free_list->pp_link;
f0100cd5:	8b 03                	mov    (%ebx),%eax
f0100cd7:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

    	if(alloc_flags & ALLOC_ZERO)
f0100cdc:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ce0:	74 45                	je     f0100d27 <page_alloc+0x63>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ce2:	89 d8                	mov    %ebx,%eax
f0100ce4:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f0100cea:	c1 f8 03             	sar    $0x3,%eax
f0100ced:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cf0:	89 c2                	mov    %eax,%edx
f0100cf2:	c1 ea 0c             	shr    $0xc,%edx
f0100cf5:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f0100cfb:	72 12                	jb     f0100d0f <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cfd:	50                   	push   %eax
f0100cfe:	68 84 28 10 f0       	push   $0xf0102884
f0100d03:	6a 52                	push   $0x52
f0100d05:	68 6c 2a 10 f0       	push   $0xf0102a6c
f0100d0a:	e8 7c f3 ff ff       	call   f010008b <_panic>
       	 	memset(page2kva(res),'\0',PGSIZE);    
f0100d0f:	83 ec 04             	sub    $0x4,%esp
f0100d12:	68 00 10 00 00       	push   $0x1000
f0100d17:	6a 00                	push   $0x0
f0100d19:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d1e:	50                   	push   %eax
f0100d1f:	e8 dc 11 00 00       	call   f0101f00 <memset>
f0100d24:	83 c4 10             	add    $0x10,%esp
        	//page2kva:for the conversion of phy addr to vir addr
        	//memset need vir addr
    	return res;
}
f0100d27:	89 d8                	mov    %ebx,%eax
f0100d29:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d2c:	c9                   	leave  
f0100d2d:	c3                   	ret    

f0100d2e <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d2e:	55                   	push   %ebp
f0100d2f:	89 e5                	mov    %esp,%ebp
f0100d31:	83 ec 08             	sub    $0x8,%esp
f0100d34:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp->pp_ref == 0);
f0100d37:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d3c:	74 19                	je     f0100d57 <page_free+0x29>
f0100d3e:	68 16 2b 10 f0       	push   $0xf0102b16
f0100d43:	68 86 2a 10 f0       	push   $0xf0102a86
f0100d48:	68 4f 01 00 00       	push   $0x14f
f0100d4d:	68 60 2a 10 f0       	push   $0xf0102a60
f0100d52:	e8 34 f3 ff ff       	call   f010008b <_panic>
    	pp->pp_link = page_free_list;
f0100d57:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100d5d:	89 10                	mov    %edx,(%eax)
    	page_free_list = pp;
f0100d5f:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
}
f0100d64:	c9                   	leave  
f0100d65:	c3                   	ret    

f0100d66 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100d66:	55                   	push   %ebp
f0100d67:	89 e5                	mov    %esp,%ebp
f0100d69:	57                   	push   %edi
f0100d6a:	56                   	push   %esi
f0100d6b:	53                   	push   %ebx
f0100d6c:	83 ec 1c             	sub    $0x1c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100d6f:	b8 15 00 00 00       	mov    $0x15,%eax
f0100d74:	e8 27 fb ff ff       	call   f01008a0 <nvram_read>
f0100d79:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);    //0x100000~0x
f0100d7b:	b8 17 00 00 00       	mov    $0x17,%eax
f0100d80:	e8 1b fb ff ff       	call   f01008a0 <nvram_read>
f0100d85:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100d87:	b8 34 00 00 00       	mov    $0x34,%eax
f0100d8c:	e8 0f fb ff ff       	call   f01008a0 <nvram_read>
f0100d91:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100d94:	85 c0                	test   %eax,%eax
f0100d96:	74 07                	je     f0100d9f <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100d98:	05 00 40 00 00       	add    $0x4000,%eax
f0100d9d:	eb 0b                	jmp    f0100daa <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100d9f:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100da5:	85 f6                	test   %esi,%esi
f0100da7:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100daa:	89 c2                	mov    %eax,%edx
f0100dac:	c1 ea 02             	shr    $0x2,%edx
f0100daf:	89 15 64 49 11 f0    	mov    %edx,0xf0114964
	npages_basemem = basemem / (PGSIZE / 1024);
f0100db5:	89 da                	mov    %ebx,%edx
f0100db7:	c1 ea 02             	shr    $0x2,%edx
f0100dba:	89 15 40 45 11 f0    	mov    %edx,0xf0114540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100dc0:	89 c2                	mov    %eax,%edx
f0100dc2:	29 da                	sub    %ebx,%edx
f0100dc4:	52                   	push   %edx
f0100dc5:	53                   	push   %ebx
f0100dc6:	50                   	push   %eax
f0100dc7:	68 90 29 10 f0       	push   $0xf0102990
f0100dcc:	e8 76 06 00 00       	call   f0101447 <cprintf>

	// Remove this line when you're ready to test this function.

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100dd1:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100dd6:	e8 8d fa ff ff       	call   f0100868 <boot_alloc>
f0100ddb:	a3 68 49 11 f0       	mov    %eax,0xf0114968
	memset(kern_pgdir, 0, PGSIZE);
f0100de0:	83 c4 0c             	add    $0xc,%esp
f0100de3:	68 00 10 00 00       	push   $0x1000
f0100de8:	6a 00                	push   $0x0
f0100dea:	50                   	push   %eax
f0100deb:	e8 10 11 00 00       	call   f0101f00 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100df0:	a1 68 49 11 f0       	mov    0xf0114968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100df5:	83 c4 10             	add    $0x10,%esp
f0100df8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100dfd:	77 15                	ja     f0100e14 <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100dff:	50                   	push   %eax
f0100e00:	68 cc 29 10 f0       	push   $0xf01029cc
f0100e05:	68 8e 00 00 00       	push   $0x8e
f0100e0a:	68 60 2a 10 f0       	push   $0xf0102a60
f0100e0f:	e8 77 f2 ff ff       	call   f010008b <_panic>
f0100e14:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100e1a:	83 ca 05             	or     $0x5,%edx
f0100e1d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0100e23:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100e28:	c1 e0 03             	shl    $0x3,%eax
f0100e2b:	e8 38 fa ff ff       	call   f0100868 <boot_alloc>
f0100e30:	a3 6c 49 11 f0       	mov    %eax,0xf011496c
	memset(pages, 0 , sizeof(struct PageInfo)*npages);
f0100e35:	83 ec 04             	sub    $0x4,%esp
f0100e38:	8b 0d 64 49 11 f0    	mov    0xf0114964,%ecx
f0100e3e:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100e45:	52                   	push   %edx
f0100e46:	6a 00                	push   $0x0
f0100e48:	50                   	push   %eax
f0100e49:	e8 b2 10 00 00       	call   f0101f00 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100e4e:	e8 9d fd ff ff       	call   f0100bf0 <page_init>

	check_page_free_list(1);
f0100e53:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e58:	e8 d0 fa ff ff       	call   f010092d <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100e5d:	83 c4 10             	add    $0x10,%esp
f0100e60:	83 3d 6c 49 11 f0 00 	cmpl   $0x0,0xf011496c
f0100e67:	75 17                	jne    f0100e80 <mem_init+0x11a>
		panic("'pages' is a null pointer!");
f0100e69:	83 ec 04             	sub    $0x4,%esp
f0100e6c:	68 26 2b 10 f0       	push   $0xf0102b26
f0100e71:	68 30 02 00 00       	push   $0x230
f0100e76:	68 60 2a 10 f0       	push   $0xf0102a60
f0100e7b:	e8 0b f2 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100e80:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100e85:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e8a:	eb 05                	jmp    f0100e91 <mem_init+0x12b>
		++nfree;
f0100e8c:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100e8f:	8b 00                	mov    (%eax),%eax
f0100e91:	85 c0                	test   %eax,%eax
f0100e93:	75 f7                	jne    f0100e8c <mem_init+0x126>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100e95:	83 ec 0c             	sub    $0xc,%esp
f0100e98:	6a 00                	push   $0x0
f0100e9a:	e8 25 fe ff ff       	call   f0100cc4 <page_alloc>
f0100e9f:	89 c7                	mov    %eax,%edi
f0100ea1:	83 c4 10             	add    $0x10,%esp
f0100ea4:	85 c0                	test   %eax,%eax
f0100ea6:	75 19                	jne    f0100ec1 <mem_init+0x15b>
f0100ea8:	68 41 2b 10 f0       	push   $0xf0102b41
f0100ead:	68 86 2a 10 f0       	push   $0xf0102a86
f0100eb2:	68 38 02 00 00       	push   $0x238
f0100eb7:	68 60 2a 10 f0       	push   $0xf0102a60
f0100ebc:	e8 ca f1 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100ec1:	83 ec 0c             	sub    $0xc,%esp
f0100ec4:	6a 00                	push   $0x0
f0100ec6:	e8 f9 fd ff ff       	call   f0100cc4 <page_alloc>
f0100ecb:	89 c6                	mov    %eax,%esi
f0100ecd:	83 c4 10             	add    $0x10,%esp
f0100ed0:	85 c0                	test   %eax,%eax
f0100ed2:	75 19                	jne    f0100eed <mem_init+0x187>
f0100ed4:	68 57 2b 10 f0       	push   $0xf0102b57
f0100ed9:	68 86 2a 10 f0       	push   $0xf0102a86
f0100ede:	68 39 02 00 00       	push   $0x239
f0100ee3:	68 60 2a 10 f0       	push   $0xf0102a60
f0100ee8:	e8 9e f1 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100eed:	83 ec 0c             	sub    $0xc,%esp
f0100ef0:	6a 00                	push   $0x0
f0100ef2:	e8 cd fd ff ff       	call   f0100cc4 <page_alloc>
f0100ef7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100efa:	83 c4 10             	add    $0x10,%esp
f0100efd:	85 c0                	test   %eax,%eax
f0100eff:	75 19                	jne    f0100f1a <mem_init+0x1b4>
f0100f01:	68 6d 2b 10 f0       	push   $0xf0102b6d
f0100f06:	68 86 2a 10 f0       	push   $0xf0102a86
f0100f0b:	68 3a 02 00 00       	push   $0x23a
f0100f10:	68 60 2a 10 f0       	push   $0xf0102a60
f0100f15:	e8 71 f1 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0100f1a:	39 f7                	cmp    %esi,%edi
f0100f1c:	75 19                	jne    f0100f37 <mem_init+0x1d1>
f0100f1e:	68 83 2b 10 f0       	push   $0xf0102b83
f0100f23:	68 86 2a 10 f0       	push   $0xf0102a86
f0100f28:	68 3d 02 00 00       	push   $0x23d
f0100f2d:	68 60 2a 10 f0       	push   $0xf0102a60
f0100f32:	e8 54 f1 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0100f37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f3a:	39 c7                	cmp    %eax,%edi
f0100f3c:	74 04                	je     f0100f42 <mem_init+0x1dc>
f0100f3e:	39 c6                	cmp    %eax,%esi
f0100f40:	75 19                	jne    f0100f5b <mem_init+0x1f5>
f0100f42:	68 f0 29 10 f0       	push   $0xf01029f0
f0100f47:	68 86 2a 10 f0       	push   $0xf0102a86
f0100f4c:	68 3e 02 00 00       	push   $0x23e
f0100f51:	68 60 2a 10 f0       	push   $0xf0102a60
f0100f56:	e8 30 f1 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f5b:	8b 0d 6c 49 11 f0    	mov    0xf011496c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0100f61:	8b 15 64 49 11 f0    	mov    0xf0114964,%edx
f0100f67:	c1 e2 0c             	shl    $0xc,%edx
f0100f6a:	89 f8                	mov    %edi,%eax
f0100f6c:	29 c8                	sub    %ecx,%eax
f0100f6e:	c1 f8 03             	sar    $0x3,%eax
f0100f71:	c1 e0 0c             	shl    $0xc,%eax
f0100f74:	39 d0                	cmp    %edx,%eax
f0100f76:	72 19                	jb     f0100f91 <mem_init+0x22b>
f0100f78:	68 95 2b 10 f0       	push   $0xf0102b95
f0100f7d:	68 86 2a 10 f0       	push   $0xf0102a86
f0100f82:	68 3f 02 00 00       	push   $0x23f
f0100f87:	68 60 2a 10 f0       	push   $0xf0102a60
f0100f8c:	e8 fa f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0100f91:	89 f0                	mov    %esi,%eax
f0100f93:	29 c8                	sub    %ecx,%eax
f0100f95:	c1 f8 03             	sar    $0x3,%eax
f0100f98:	c1 e0 0c             	shl    $0xc,%eax
f0100f9b:	39 c2                	cmp    %eax,%edx
f0100f9d:	77 19                	ja     f0100fb8 <mem_init+0x252>
f0100f9f:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100fa4:	68 86 2a 10 f0       	push   $0xf0102a86
f0100fa9:	68 40 02 00 00       	push   $0x240
f0100fae:	68 60 2a 10 f0       	push   $0xf0102a60
f0100fb3:	e8 d3 f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0100fb8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fbb:	29 c8                	sub    %ecx,%eax
f0100fbd:	c1 f8 03             	sar    $0x3,%eax
f0100fc0:	c1 e0 0c             	shl    $0xc,%eax
f0100fc3:	39 c2                	cmp    %eax,%edx
f0100fc5:	77 19                	ja     f0100fe0 <mem_init+0x27a>
f0100fc7:	68 cf 2b 10 f0       	push   $0xf0102bcf
f0100fcc:	68 86 2a 10 f0       	push   $0xf0102a86
f0100fd1:	68 41 02 00 00       	push   $0x241
f0100fd6:	68 60 2a 10 f0       	push   $0xf0102a60
f0100fdb:	e8 ab f0 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0100fe0:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100fe5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0100fe8:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0100fef:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0100ff2:	83 ec 0c             	sub    $0xc,%esp
f0100ff5:	6a 00                	push   $0x0
f0100ff7:	e8 c8 fc ff ff       	call   f0100cc4 <page_alloc>
f0100ffc:	83 c4 10             	add    $0x10,%esp
f0100fff:	85 c0                	test   %eax,%eax
f0101001:	74 19                	je     f010101c <mem_init+0x2b6>
f0101003:	68 ec 2b 10 f0       	push   $0xf0102bec
f0101008:	68 86 2a 10 f0       	push   $0xf0102a86
f010100d:	68 48 02 00 00       	push   $0x248
f0101012:	68 60 2a 10 f0       	push   $0xf0102a60
f0101017:	e8 6f f0 ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010101c:	83 ec 0c             	sub    $0xc,%esp
f010101f:	57                   	push   %edi
f0101020:	e8 09 fd ff ff       	call   f0100d2e <page_free>
	page_free(pp1);
f0101025:	89 34 24             	mov    %esi,(%esp)
f0101028:	e8 01 fd ff ff       	call   f0100d2e <page_free>
	page_free(pp2);
f010102d:	83 c4 04             	add    $0x4,%esp
f0101030:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101033:	e8 f6 fc ff ff       	call   f0100d2e <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101038:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010103f:	e8 80 fc ff ff       	call   f0100cc4 <page_alloc>
f0101044:	89 c6                	mov    %eax,%esi
f0101046:	83 c4 10             	add    $0x10,%esp
f0101049:	85 c0                	test   %eax,%eax
f010104b:	75 19                	jne    f0101066 <mem_init+0x300>
f010104d:	68 41 2b 10 f0       	push   $0xf0102b41
f0101052:	68 86 2a 10 f0       	push   $0xf0102a86
f0101057:	68 4f 02 00 00       	push   $0x24f
f010105c:	68 60 2a 10 f0       	push   $0xf0102a60
f0101061:	e8 25 f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101066:	83 ec 0c             	sub    $0xc,%esp
f0101069:	6a 00                	push   $0x0
f010106b:	e8 54 fc ff ff       	call   f0100cc4 <page_alloc>
f0101070:	89 c7                	mov    %eax,%edi
f0101072:	83 c4 10             	add    $0x10,%esp
f0101075:	85 c0                	test   %eax,%eax
f0101077:	75 19                	jne    f0101092 <mem_init+0x32c>
f0101079:	68 57 2b 10 f0       	push   $0xf0102b57
f010107e:	68 86 2a 10 f0       	push   $0xf0102a86
f0101083:	68 50 02 00 00       	push   $0x250
f0101088:	68 60 2a 10 f0       	push   $0xf0102a60
f010108d:	e8 f9 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101092:	83 ec 0c             	sub    $0xc,%esp
f0101095:	6a 00                	push   $0x0
f0101097:	e8 28 fc ff ff       	call   f0100cc4 <page_alloc>
f010109c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010109f:	83 c4 10             	add    $0x10,%esp
f01010a2:	85 c0                	test   %eax,%eax
f01010a4:	75 19                	jne    f01010bf <mem_init+0x359>
f01010a6:	68 6d 2b 10 f0       	push   $0xf0102b6d
f01010ab:	68 86 2a 10 f0       	push   $0xf0102a86
f01010b0:	68 51 02 00 00       	push   $0x251
f01010b5:	68 60 2a 10 f0       	push   $0xf0102a60
f01010ba:	e8 cc ef ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01010bf:	39 fe                	cmp    %edi,%esi
f01010c1:	75 19                	jne    f01010dc <mem_init+0x376>
f01010c3:	68 83 2b 10 f0       	push   $0xf0102b83
f01010c8:	68 86 2a 10 f0       	push   $0xf0102a86
f01010cd:	68 53 02 00 00       	push   $0x253
f01010d2:	68 60 2a 10 f0       	push   $0xf0102a60
f01010d7:	e8 af ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01010dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010df:	39 c7                	cmp    %eax,%edi
f01010e1:	74 04                	je     f01010e7 <mem_init+0x381>
f01010e3:	39 c6                	cmp    %eax,%esi
f01010e5:	75 19                	jne    f0101100 <mem_init+0x39a>
f01010e7:	68 f0 29 10 f0       	push   $0xf01029f0
f01010ec:	68 86 2a 10 f0       	push   $0xf0102a86
f01010f1:	68 54 02 00 00       	push   $0x254
f01010f6:	68 60 2a 10 f0       	push   $0xf0102a60
f01010fb:	e8 8b ef ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101100:	83 ec 0c             	sub    $0xc,%esp
f0101103:	6a 00                	push   $0x0
f0101105:	e8 ba fb ff ff       	call   f0100cc4 <page_alloc>
f010110a:	83 c4 10             	add    $0x10,%esp
f010110d:	85 c0                	test   %eax,%eax
f010110f:	74 19                	je     f010112a <mem_init+0x3c4>
f0101111:	68 ec 2b 10 f0       	push   $0xf0102bec
f0101116:	68 86 2a 10 f0       	push   $0xf0102a86
f010111b:	68 55 02 00 00       	push   $0x255
f0101120:	68 60 2a 10 f0       	push   $0xf0102a60
f0101125:	e8 61 ef ff ff       	call   f010008b <_panic>
f010112a:	89 f0                	mov    %esi,%eax
f010112c:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f0101132:	c1 f8 03             	sar    $0x3,%eax
f0101135:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101138:	89 c2                	mov    %eax,%edx
f010113a:	c1 ea 0c             	shr    $0xc,%edx
f010113d:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f0101143:	72 12                	jb     f0101157 <mem_init+0x3f1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101145:	50                   	push   %eax
f0101146:	68 84 28 10 f0       	push   $0xf0102884
f010114b:	6a 52                	push   $0x52
f010114d:	68 6c 2a 10 f0       	push   $0xf0102a6c
f0101152:	e8 34 ef ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101157:	83 ec 04             	sub    $0x4,%esp
f010115a:	68 00 10 00 00       	push   $0x1000
f010115f:	6a 01                	push   $0x1
f0101161:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101166:	50                   	push   %eax
f0101167:	e8 94 0d 00 00       	call   f0101f00 <memset>
	page_free(pp0);
f010116c:	89 34 24             	mov    %esi,(%esp)
f010116f:	e8 ba fb ff ff       	call   f0100d2e <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101174:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010117b:	e8 44 fb ff ff       	call   f0100cc4 <page_alloc>
f0101180:	83 c4 10             	add    $0x10,%esp
f0101183:	85 c0                	test   %eax,%eax
f0101185:	75 19                	jne    f01011a0 <mem_init+0x43a>
f0101187:	68 fb 2b 10 f0       	push   $0xf0102bfb
f010118c:	68 86 2a 10 f0       	push   $0xf0102a86
f0101191:	68 5a 02 00 00       	push   $0x25a
f0101196:	68 60 2a 10 f0       	push   $0xf0102a60
f010119b:	e8 eb ee ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01011a0:	39 c6                	cmp    %eax,%esi
f01011a2:	74 19                	je     f01011bd <mem_init+0x457>
f01011a4:	68 19 2c 10 f0       	push   $0xf0102c19
f01011a9:	68 86 2a 10 f0       	push   $0xf0102a86
f01011ae:	68 5b 02 00 00       	push   $0x25b
f01011b3:	68 60 2a 10 f0       	push   $0xf0102a60
f01011b8:	e8 ce ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011bd:	89 f0                	mov    %esi,%eax
f01011bf:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f01011c5:	c1 f8 03             	sar    $0x3,%eax
f01011c8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011cb:	89 c2                	mov    %eax,%edx
f01011cd:	c1 ea 0c             	shr    $0xc,%edx
f01011d0:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f01011d6:	72 12                	jb     f01011ea <mem_init+0x484>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011d8:	50                   	push   %eax
f01011d9:	68 84 28 10 f0       	push   $0xf0102884
f01011de:	6a 52                	push   $0x52
f01011e0:	68 6c 2a 10 f0       	push   $0xf0102a6c
f01011e5:	e8 a1 ee ff ff       	call   f010008b <_panic>
f01011ea:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01011f0:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01011f6:	80 38 00             	cmpb   $0x0,(%eax)
f01011f9:	74 19                	je     f0101214 <mem_init+0x4ae>
f01011fb:	68 29 2c 10 f0       	push   $0xf0102c29
f0101200:	68 86 2a 10 f0       	push   $0xf0102a86
f0101205:	68 5e 02 00 00       	push   $0x25e
f010120a:	68 60 2a 10 f0       	push   $0xf0102a60
f010120f:	e8 77 ee ff ff       	call   f010008b <_panic>
f0101214:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101217:	39 d0                	cmp    %edx,%eax
f0101219:	75 db                	jne    f01011f6 <mem_init+0x490>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010121b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010121e:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f0101223:	83 ec 0c             	sub    $0xc,%esp
f0101226:	56                   	push   %esi
f0101227:	e8 02 fb ff ff       	call   f0100d2e <page_free>
	page_free(pp1);
f010122c:	89 3c 24             	mov    %edi,(%esp)
f010122f:	e8 fa fa ff ff       	call   f0100d2e <page_free>
	page_free(pp2);
f0101234:	83 c4 04             	add    $0x4,%esp
f0101237:	ff 75 e4             	pushl  -0x1c(%ebp)
f010123a:	e8 ef fa ff ff       	call   f0100d2e <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010123f:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101244:	83 c4 10             	add    $0x10,%esp
f0101247:	eb 05                	jmp    f010124e <mem_init+0x4e8>
		--nfree;
f0101249:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010124c:	8b 00                	mov    (%eax),%eax
f010124e:	85 c0                	test   %eax,%eax
f0101250:	75 f7                	jne    f0101249 <mem_init+0x4e3>
		--nfree;
	assert(nfree == 0);
f0101252:	85 db                	test   %ebx,%ebx
f0101254:	74 19                	je     f010126f <mem_init+0x509>
f0101256:	68 33 2c 10 f0       	push   $0xf0102c33
f010125b:	68 86 2a 10 f0       	push   $0xf0102a86
f0101260:	68 6b 02 00 00       	push   $0x26b
f0101265:	68 60 2a 10 f0       	push   $0xf0102a60
f010126a:	e8 1c ee ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010126f:	83 ec 0c             	sub    $0xc,%esp
f0101272:	68 10 2a 10 f0       	push   $0xf0102a10
f0101277:	e8 cb 01 00 00       	call   f0101447 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010127c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101283:	e8 3c fa ff ff       	call   f0100cc4 <page_alloc>
f0101288:	89 c3                	mov    %eax,%ebx
f010128a:	83 c4 10             	add    $0x10,%esp
f010128d:	85 c0                	test   %eax,%eax
f010128f:	75 19                	jne    f01012aa <mem_init+0x544>
f0101291:	68 41 2b 10 f0       	push   $0xf0102b41
f0101296:	68 86 2a 10 f0       	push   $0xf0102a86
f010129b:	68 c4 02 00 00       	push   $0x2c4
f01012a0:	68 60 2a 10 f0       	push   $0xf0102a60
f01012a5:	e8 e1 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01012aa:	83 ec 0c             	sub    $0xc,%esp
f01012ad:	6a 00                	push   $0x0
f01012af:	e8 10 fa ff ff       	call   f0100cc4 <page_alloc>
f01012b4:	89 c6                	mov    %eax,%esi
f01012b6:	83 c4 10             	add    $0x10,%esp
f01012b9:	85 c0                	test   %eax,%eax
f01012bb:	75 19                	jne    f01012d6 <mem_init+0x570>
f01012bd:	68 57 2b 10 f0       	push   $0xf0102b57
f01012c2:	68 86 2a 10 f0       	push   $0xf0102a86
f01012c7:	68 c5 02 00 00       	push   $0x2c5
f01012cc:	68 60 2a 10 f0       	push   $0xf0102a60
f01012d1:	e8 b5 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01012d6:	83 ec 0c             	sub    $0xc,%esp
f01012d9:	6a 00                	push   $0x0
f01012db:	e8 e4 f9 ff ff       	call   f0100cc4 <page_alloc>
f01012e0:	83 c4 10             	add    $0x10,%esp
f01012e3:	85 c0                	test   %eax,%eax
f01012e5:	75 19                	jne    f0101300 <mem_init+0x59a>
f01012e7:	68 6d 2b 10 f0       	push   $0xf0102b6d
f01012ec:	68 86 2a 10 f0       	push   $0xf0102a86
f01012f1:	68 c6 02 00 00       	push   $0x2c6
f01012f6:	68 60 2a 10 f0       	push   $0xf0102a60
f01012fb:	e8 8b ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101300:	39 f3                	cmp    %esi,%ebx
f0101302:	75 19                	jne    f010131d <mem_init+0x5b7>
f0101304:	68 83 2b 10 f0       	push   $0xf0102b83
f0101309:	68 86 2a 10 f0       	push   $0xf0102a86
f010130e:	68 c9 02 00 00       	push   $0x2c9
f0101313:	68 60 2a 10 f0       	push   $0xf0102a60
f0101318:	e8 6e ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010131d:	39 c6                	cmp    %eax,%esi
f010131f:	74 04                	je     f0101325 <mem_init+0x5bf>
f0101321:	39 c3                	cmp    %eax,%ebx
f0101323:	75 19                	jne    f010133e <mem_init+0x5d8>
f0101325:	68 f0 29 10 f0       	push   $0xf01029f0
f010132a:	68 86 2a 10 f0       	push   $0xf0102a86
f010132f:	68 ca 02 00 00       	push   $0x2ca
f0101334:	68 60 2a 10 f0       	push   $0xf0102a60
f0101339:	e8 4d ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f010133e:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0101345:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101348:	83 ec 0c             	sub    $0xc,%esp
f010134b:	6a 00                	push   $0x0
f010134d:	e8 72 f9 ff ff       	call   f0100cc4 <page_alloc>
f0101352:	83 c4 10             	add    $0x10,%esp
f0101355:	85 c0                	test   %eax,%eax
f0101357:	74 19                	je     f0101372 <mem_init+0x60c>
f0101359:	68 ec 2b 10 f0       	push   $0xf0102bec
f010135e:	68 86 2a 10 f0       	push   $0xf0102a86
f0101363:	68 d1 02 00 00       	push   $0x2d1
f0101368:	68 60 2a 10 f0       	push   $0xf0102a60
f010136d:	e8 19 ed ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101372:	68 30 2a 10 f0       	push   $0xf0102a30
f0101377:	68 86 2a 10 f0       	push   $0xf0102a86
f010137c:	68 d7 02 00 00       	push   $0x2d7
f0101381:	68 60 2a 10 f0       	push   $0xf0102a60
f0101386:	e8 00 ed ff ff       	call   f010008b <_panic>

f010138b <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010138b:	55                   	push   %ebp
f010138c:	89 e5                	mov    %esp,%ebp
f010138e:	83 ec 08             	sub    $0x8,%esp
f0101391:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101394:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101398:	83 e8 01             	sub    $0x1,%eax
f010139b:	66 89 42 04          	mov    %ax,0x4(%edx)
f010139f:	66 85 c0             	test   %ax,%ax
f01013a2:	75 0c                	jne    f01013b0 <page_decref+0x25>
		page_free(pp);
f01013a4:	83 ec 0c             	sub    $0xc,%esp
f01013a7:	52                   	push   %edx
f01013a8:	e8 81 f9 ff ff       	call   f0100d2e <page_free>
f01013ad:	83 c4 10             	add    $0x10,%esp
}
f01013b0:	c9                   	leave  
f01013b1:	c3                   	ret    

f01013b2 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01013b2:	55                   	push   %ebp
f01013b3:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01013b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ba:	5d                   	pop    %ebp
f01013bb:	c3                   	ret    

f01013bc <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01013bc:	55                   	push   %ebp
f01013bd:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01013bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c4:	5d                   	pop    %ebp
f01013c5:	c3                   	ret    

f01013c6 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01013c6:	55                   	push   %ebp
f01013c7:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01013c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ce:	5d                   	pop    %ebp
f01013cf:	c3                   	ret    

f01013d0 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01013d0:	55                   	push   %ebp
f01013d1:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01013d3:	5d                   	pop    %ebp
f01013d4:	c3                   	ret    

f01013d5 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01013d5:	55                   	push   %ebp
f01013d6:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01013d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013db:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01013de:	5d                   	pop    %ebp
f01013df:	c3                   	ret    

f01013e0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01013e0:	55                   	push   %ebp
f01013e1:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01013e3:	ba 70 00 00 00       	mov    $0x70,%edx
f01013e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01013eb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01013ec:	ba 71 00 00 00       	mov    $0x71,%edx
f01013f1:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01013f2:	0f b6 c0             	movzbl %al,%eax
}
f01013f5:	5d                   	pop    %ebp
f01013f6:	c3                   	ret    

f01013f7 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01013f7:	55                   	push   %ebp
f01013f8:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01013fa:	ba 70 00 00 00       	mov    $0x70,%edx
f01013ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101402:	ee                   	out    %al,(%dx)
f0101403:	ba 71 00 00 00       	mov    $0x71,%edx
f0101408:	8b 45 0c             	mov    0xc(%ebp),%eax
f010140b:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010140c:	5d                   	pop    %ebp
f010140d:	c3                   	ret    

f010140e <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010140e:	55                   	push   %ebp
f010140f:	89 e5                	mov    %esp,%ebp
f0101411:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0101414:	ff 75 08             	pushl  0x8(%ebp)
f0101417:	e8 e4 f1 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f010141c:	83 c4 10             	add    $0x10,%esp
f010141f:	c9                   	leave  
f0101420:	c3                   	ret    

f0101421 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101421:	55                   	push   %ebp
f0101422:	89 e5                	mov    %esp,%ebp
f0101424:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0101427:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010142e:	ff 75 0c             	pushl  0xc(%ebp)
f0101431:	ff 75 08             	pushl  0x8(%ebp)
f0101434:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101437:	50                   	push   %eax
f0101438:	68 0e 14 10 f0       	push   $0xf010140e
f010143d:	e8 52 04 00 00       	call   f0101894 <vprintfmt>
	return cnt;
}
f0101442:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101445:	c9                   	leave  
f0101446:	c3                   	ret    

f0101447 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101447:	55                   	push   %ebp
f0101448:	89 e5                	mov    %esp,%ebp
f010144a:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010144d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101450:	50                   	push   %eax
f0101451:	ff 75 08             	pushl  0x8(%ebp)
f0101454:	e8 c8 ff ff ff       	call   f0101421 <vcprintf>
	va_end(ap);

	return cnt;
}
f0101459:	c9                   	leave  
f010145a:	c3                   	ret    

f010145b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010145b:	55                   	push   %ebp
f010145c:	89 e5                	mov    %esp,%ebp
f010145e:	57                   	push   %edi
f010145f:	56                   	push   %esi
f0101460:	53                   	push   %ebx
f0101461:	83 ec 14             	sub    $0x14,%esp
f0101464:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101467:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010146a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010146d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101470:	8b 1a                	mov    (%edx),%ebx
f0101472:	8b 01                	mov    (%ecx),%eax
f0101474:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101477:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010147e:	eb 7f                	jmp    f01014ff <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0101480:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101483:	01 d8                	add    %ebx,%eax
f0101485:	89 c6                	mov    %eax,%esi
f0101487:	c1 ee 1f             	shr    $0x1f,%esi
f010148a:	01 c6                	add    %eax,%esi
f010148c:	d1 fe                	sar    %esi
f010148e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101491:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101494:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0101497:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101499:	eb 03                	jmp    f010149e <stab_binsearch+0x43>
			m--;
f010149b:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010149e:	39 c3                	cmp    %eax,%ebx
f01014a0:	7f 0d                	jg     f01014af <stab_binsearch+0x54>
f01014a2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01014a6:	83 ea 0c             	sub    $0xc,%edx
f01014a9:	39 f9                	cmp    %edi,%ecx
f01014ab:	75 ee                	jne    f010149b <stab_binsearch+0x40>
f01014ad:	eb 05                	jmp    f01014b4 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01014af:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01014b2:	eb 4b                	jmp    f01014ff <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01014b4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01014b7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01014ba:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01014be:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01014c1:	76 11                	jbe    f01014d4 <stab_binsearch+0x79>
			*region_left = m;
f01014c3:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01014c6:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01014c8:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01014cb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01014d2:	eb 2b                	jmp    f01014ff <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01014d4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01014d7:	73 14                	jae    f01014ed <stab_binsearch+0x92>
			*region_right = m - 1;
f01014d9:	83 e8 01             	sub    $0x1,%eax
f01014dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01014df:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01014e2:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01014e4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01014eb:	eb 12                	jmp    f01014ff <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01014ed:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01014f0:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01014f2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01014f6:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01014f8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01014ff:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0101502:	0f 8e 78 ff ff ff    	jle    f0101480 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101508:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010150c:	75 0f                	jne    f010151d <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010150e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101511:	8b 00                	mov    (%eax),%eax
f0101513:	83 e8 01             	sub    $0x1,%eax
f0101516:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101519:	89 06                	mov    %eax,(%esi)
f010151b:	eb 2c                	jmp    f0101549 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010151d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101520:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101522:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101525:	8b 0e                	mov    (%esi),%ecx
f0101527:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010152a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010152d:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101530:	eb 03                	jmp    f0101535 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101532:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101535:	39 c8                	cmp    %ecx,%eax
f0101537:	7e 0b                	jle    f0101544 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0101539:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010153d:	83 ea 0c             	sub    $0xc,%edx
f0101540:	39 df                	cmp    %ebx,%edi
f0101542:	75 ee                	jne    f0101532 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101544:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101547:	89 06                	mov    %eax,(%esi)
	}
}
f0101549:	83 c4 14             	add    $0x14,%esp
f010154c:	5b                   	pop    %ebx
f010154d:	5e                   	pop    %esi
f010154e:	5f                   	pop    %edi
f010154f:	5d                   	pop    %ebp
f0101550:	c3                   	ret    

f0101551 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101551:	55                   	push   %ebp
f0101552:	89 e5                	mov    %esp,%ebp
f0101554:	57                   	push   %edi
f0101555:	56                   	push   %esi
f0101556:	53                   	push   %ebx
f0101557:	83 ec 3c             	sub    $0x3c,%esp
f010155a:	8b 75 08             	mov    0x8(%ebp),%esi
f010155d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101560:	c7 03 3e 2c 10 f0    	movl   $0xf0102c3e,(%ebx)
	info->eip_line = 0;
f0101566:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010156d:	c7 43 08 3e 2c 10 f0 	movl   $0xf0102c3e,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101574:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010157b:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010157e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101585:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010158b:	76 11                	jbe    f010159e <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010158d:	b8 2c 96 10 f0       	mov    $0xf010962c,%eax
f0101592:	3d 21 79 10 f0       	cmp    $0xf0107921,%eax
f0101597:	77 19                	ja     f01015b2 <debuginfo_eip+0x61>
f0101599:	e9 aa 01 00 00       	jmp    f0101748 <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010159e:	83 ec 04             	sub    $0x4,%esp
f01015a1:	68 48 2c 10 f0       	push   $0xf0102c48
f01015a6:	6a 7f                	push   $0x7f
f01015a8:	68 55 2c 10 f0       	push   $0xf0102c55
f01015ad:	e8 d9 ea ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01015b2:	80 3d 2b 96 10 f0 00 	cmpb   $0x0,0xf010962b
f01015b9:	0f 85 90 01 00 00    	jne    f010174f <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01015bf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01015c6:	b8 20 79 10 f0       	mov    $0xf0107920,%eax
f01015cb:	2d 74 2e 10 f0       	sub    $0xf0102e74,%eax
f01015d0:	c1 f8 02             	sar    $0x2,%eax
f01015d3:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01015d9:	83 e8 01             	sub    $0x1,%eax
f01015dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01015df:	83 ec 08             	sub    $0x8,%esp
f01015e2:	56                   	push   %esi
f01015e3:	6a 64                	push   $0x64
f01015e5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01015e8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01015eb:	b8 74 2e 10 f0       	mov    $0xf0102e74,%eax
f01015f0:	e8 66 fe ff ff       	call   f010145b <stab_binsearch>
	if (lfile == 0)
f01015f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015f8:	83 c4 10             	add    $0x10,%esp
f01015fb:	85 c0                	test   %eax,%eax
f01015fd:	0f 84 53 01 00 00    	je     f0101756 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101603:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101606:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101609:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010160c:	83 ec 08             	sub    $0x8,%esp
f010160f:	56                   	push   %esi
f0101610:	6a 24                	push   $0x24
f0101612:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101615:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101618:	b8 74 2e 10 f0       	mov    $0xf0102e74,%eax
f010161d:	e8 39 fe ff ff       	call   f010145b <stab_binsearch>

	if (lfun <= rfun) {
f0101622:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101625:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101628:	83 c4 10             	add    $0x10,%esp
f010162b:	39 d0                	cmp    %edx,%eax
f010162d:	7f 40                	jg     f010166f <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010162f:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0101632:	c1 e1 02             	shl    $0x2,%ecx
f0101635:	8d b9 74 2e 10 f0    	lea    -0xfefd18c(%ecx),%edi
f010163b:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f010163e:	8b b9 74 2e 10 f0    	mov    -0xfefd18c(%ecx),%edi
f0101644:	b9 2c 96 10 f0       	mov    $0xf010962c,%ecx
f0101649:	81 e9 21 79 10 f0    	sub    $0xf0107921,%ecx
f010164f:	39 cf                	cmp    %ecx,%edi
f0101651:	73 09                	jae    f010165c <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101653:	81 c7 21 79 10 f0    	add    $0xf0107921,%edi
f0101659:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010165c:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010165f:	8b 4f 08             	mov    0x8(%edi),%ecx
f0101662:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0101665:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0101667:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010166a:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010166d:	eb 0f                	jmp    f010167e <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010166f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101672:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101675:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101678:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010167b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010167e:	83 ec 08             	sub    $0x8,%esp
f0101681:	6a 3a                	push   $0x3a
f0101683:	ff 73 08             	pushl  0x8(%ebx)
f0101686:	e8 59 08 00 00       	call   f0101ee4 <strfind>
f010168b:	2b 43 08             	sub    0x8(%ebx),%eax
f010168e:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101691:	83 c4 08             	add    $0x8,%esp
f0101694:	56                   	push   %esi
f0101695:	6a 44                	push   $0x44
f0101697:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010169a:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010169d:	b8 74 2e 10 f0       	mov    $0xf0102e74,%eax
f01016a2:	e8 b4 fd ff ff       	call   f010145b <stab_binsearch>
	if(lline <= rline) {
f01016a7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01016aa:	83 c4 10             	add    $0x10,%esp
f01016ad:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f01016b0:	0f 8f a7 00 00 00    	jg     f010175d <debuginfo_eip+0x20c>
		info->eip_line = stabs[lline].n_desc;	
f01016b6:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01016b9:	8d 04 85 74 2e 10 f0 	lea    -0xfefd18c(,%eax,4),%eax
f01016c0:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f01016c4:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01016c7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01016ca:	eb 06                	jmp    f01016d2 <debuginfo_eip+0x181>
f01016cc:	83 ea 01             	sub    $0x1,%edx
f01016cf:	83 e8 0c             	sub    $0xc,%eax
f01016d2:	39 d6                	cmp    %edx,%esi
f01016d4:	7f 34                	jg     f010170a <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f01016d6:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01016da:	80 f9 84             	cmp    $0x84,%cl
f01016dd:	74 0b                	je     f01016ea <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01016df:	80 f9 64             	cmp    $0x64,%cl
f01016e2:	75 e8                	jne    f01016cc <debuginfo_eip+0x17b>
f01016e4:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01016e8:	74 e2                	je     f01016cc <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01016ea:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01016ed:	8b 14 85 74 2e 10 f0 	mov    -0xfefd18c(,%eax,4),%edx
f01016f4:	b8 2c 96 10 f0       	mov    $0xf010962c,%eax
f01016f9:	2d 21 79 10 f0       	sub    $0xf0107921,%eax
f01016fe:	39 c2                	cmp    %eax,%edx
f0101700:	73 08                	jae    f010170a <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101702:	81 c2 21 79 10 f0    	add    $0xf0107921,%edx
f0101708:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010170a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010170d:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101710:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101715:	39 f2                	cmp    %esi,%edx
f0101717:	7d 50                	jge    f0101769 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f0101719:	83 c2 01             	add    $0x1,%edx
f010171c:	89 d0                	mov    %edx,%eax
f010171e:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0101721:	8d 14 95 74 2e 10 f0 	lea    -0xfefd18c(,%edx,4),%edx
f0101728:	eb 04                	jmp    f010172e <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010172a:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010172e:	39 c6                	cmp    %eax,%esi
f0101730:	7e 32                	jle    f0101764 <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101732:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101736:	83 c0 01             	add    $0x1,%eax
f0101739:	83 c2 0c             	add    $0xc,%edx
f010173c:	80 f9 a0             	cmp    $0xa0,%cl
f010173f:	74 e9                	je     f010172a <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101741:	b8 00 00 00 00       	mov    $0x0,%eax
f0101746:	eb 21                	jmp    f0101769 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101748:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010174d:	eb 1a                	jmp    f0101769 <debuginfo_eip+0x218>
f010174f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101754:	eb 13                	jmp    f0101769 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101756:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010175b:	eb 0c                	jmp    f0101769 <debuginfo_eip+0x218>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline) {
		info->eip_line = stabs[lline].n_desc;	
	}
	else {
		return -1;
f010175d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101762:	eb 05                	jmp    f0101769 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101764:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101769:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010176c:	5b                   	pop    %ebx
f010176d:	5e                   	pop    %esi
f010176e:	5f                   	pop    %edi
f010176f:	5d                   	pop    %ebp
f0101770:	c3                   	ret    

f0101771 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101771:	55                   	push   %ebp
f0101772:	89 e5                	mov    %esp,%ebp
f0101774:	57                   	push   %edi
f0101775:	56                   	push   %esi
f0101776:	53                   	push   %ebx
f0101777:	83 ec 1c             	sub    $0x1c,%esp
f010177a:	89 c7                	mov    %eax,%edi
f010177c:	89 d6                	mov    %edx,%esi
f010177e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101781:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101784:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101787:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010178a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010178d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101792:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101795:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101798:	39 d3                	cmp    %edx,%ebx
f010179a:	72 05                	jb     f01017a1 <printnum+0x30>
f010179c:	39 45 10             	cmp    %eax,0x10(%ebp)
f010179f:	77 45                	ja     f01017e6 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01017a1:	83 ec 0c             	sub    $0xc,%esp
f01017a4:	ff 75 18             	pushl  0x18(%ebp)
f01017a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01017aa:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01017ad:	53                   	push   %ebx
f01017ae:	ff 75 10             	pushl  0x10(%ebp)
f01017b1:	83 ec 08             	sub    $0x8,%esp
f01017b4:	ff 75 e4             	pushl  -0x1c(%ebp)
f01017b7:	ff 75 e0             	pushl  -0x20(%ebp)
f01017ba:	ff 75 dc             	pushl  -0x24(%ebp)
f01017bd:	ff 75 d8             	pushl  -0x28(%ebp)
f01017c0:	e8 4b 09 00 00       	call   f0102110 <__udivdi3>
f01017c5:	83 c4 18             	add    $0x18,%esp
f01017c8:	52                   	push   %edx
f01017c9:	50                   	push   %eax
f01017ca:	89 f2                	mov    %esi,%edx
f01017cc:	89 f8                	mov    %edi,%eax
f01017ce:	e8 9e ff ff ff       	call   f0101771 <printnum>
f01017d3:	83 c4 20             	add    $0x20,%esp
f01017d6:	eb 18                	jmp    f01017f0 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01017d8:	83 ec 08             	sub    $0x8,%esp
f01017db:	56                   	push   %esi
f01017dc:	ff 75 18             	pushl  0x18(%ebp)
f01017df:	ff d7                	call   *%edi
f01017e1:	83 c4 10             	add    $0x10,%esp
f01017e4:	eb 03                	jmp    f01017e9 <printnum+0x78>
f01017e6:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01017e9:	83 eb 01             	sub    $0x1,%ebx
f01017ec:	85 db                	test   %ebx,%ebx
f01017ee:	7f e8                	jg     f01017d8 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01017f0:	83 ec 08             	sub    $0x8,%esp
f01017f3:	56                   	push   %esi
f01017f4:	83 ec 04             	sub    $0x4,%esp
f01017f7:	ff 75 e4             	pushl  -0x1c(%ebp)
f01017fa:	ff 75 e0             	pushl  -0x20(%ebp)
f01017fd:	ff 75 dc             	pushl  -0x24(%ebp)
f0101800:	ff 75 d8             	pushl  -0x28(%ebp)
f0101803:	e8 38 0a 00 00       	call   f0102240 <__umoddi3>
f0101808:	83 c4 14             	add    $0x14,%esp
f010180b:	0f be 80 63 2c 10 f0 	movsbl -0xfefd39d(%eax),%eax
f0101812:	50                   	push   %eax
f0101813:	ff d7                	call   *%edi
}
f0101815:	83 c4 10             	add    $0x10,%esp
f0101818:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010181b:	5b                   	pop    %ebx
f010181c:	5e                   	pop    %esi
f010181d:	5f                   	pop    %edi
f010181e:	5d                   	pop    %ebp
f010181f:	c3                   	ret    

f0101820 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101820:	55                   	push   %ebp
f0101821:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101823:	83 fa 01             	cmp    $0x1,%edx
f0101826:	7e 0e                	jle    f0101836 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101828:	8b 10                	mov    (%eax),%edx
f010182a:	8d 4a 08             	lea    0x8(%edx),%ecx
f010182d:	89 08                	mov    %ecx,(%eax)
f010182f:	8b 02                	mov    (%edx),%eax
f0101831:	8b 52 04             	mov    0x4(%edx),%edx
f0101834:	eb 22                	jmp    f0101858 <getuint+0x38>
	else if (lflag)
f0101836:	85 d2                	test   %edx,%edx
f0101838:	74 10                	je     f010184a <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010183a:	8b 10                	mov    (%eax),%edx
f010183c:	8d 4a 04             	lea    0x4(%edx),%ecx
f010183f:	89 08                	mov    %ecx,(%eax)
f0101841:	8b 02                	mov    (%edx),%eax
f0101843:	ba 00 00 00 00       	mov    $0x0,%edx
f0101848:	eb 0e                	jmp    f0101858 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010184a:	8b 10                	mov    (%eax),%edx
f010184c:	8d 4a 04             	lea    0x4(%edx),%ecx
f010184f:	89 08                	mov    %ecx,(%eax)
f0101851:	8b 02                	mov    (%edx),%eax
f0101853:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101858:	5d                   	pop    %ebp
f0101859:	c3                   	ret    

f010185a <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010185a:	55                   	push   %ebp
f010185b:	89 e5                	mov    %esp,%ebp
f010185d:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101860:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101864:	8b 10                	mov    (%eax),%edx
f0101866:	3b 50 04             	cmp    0x4(%eax),%edx
f0101869:	73 0a                	jae    f0101875 <sprintputch+0x1b>
		*b->buf++ = ch;
f010186b:	8d 4a 01             	lea    0x1(%edx),%ecx
f010186e:	89 08                	mov    %ecx,(%eax)
f0101870:	8b 45 08             	mov    0x8(%ebp),%eax
f0101873:	88 02                	mov    %al,(%edx)
}
f0101875:	5d                   	pop    %ebp
f0101876:	c3                   	ret    

f0101877 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101877:	55                   	push   %ebp
f0101878:	89 e5                	mov    %esp,%ebp
f010187a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010187d:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101880:	50                   	push   %eax
f0101881:	ff 75 10             	pushl  0x10(%ebp)
f0101884:	ff 75 0c             	pushl  0xc(%ebp)
f0101887:	ff 75 08             	pushl  0x8(%ebp)
f010188a:	e8 05 00 00 00       	call   f0101894 <vprintfmt>
	va_end(ap);
}
f010188f:	83 c4 10             	add    $0x10,%esp
f0101892:	c9                   	leave  
f0101893:	c3                   	ret    

f0101894 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101894:	55                   	push   %ebp
f0101895:	89 e5                	mov    %esp,%ebp
f0101897:	57                   	push   %edi
f0101898:	56                   	push   %esi
f0101899:	53                   	push   %ebx
f010189a:	83 ec 2c             	sub    $0x2c,%esp
f010189d:	8b 75 08             	mov    0x8(%ebp),%esi
f01018a0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01018a3:	8b 7d 10             	mov    0x10(%ebp),%edi
f01018a6:	eb 12                	jmp    f01018ba <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01018a8:	85 c0                	test   %eax,%eax
f01018aa:	0f 84 89 03 00 00    	je     f0101c39 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f01018b0:	83 ec 08             	sub    $0x8,%esp
f01018b3:	53                   	push   %ebx
f01018b4:	50                   	push   %eax
f01018b5:	ff d6                	call   *%esi
f01018b7:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01018ba:	83 c7 01             	add    $0x1,%edi
f01018bd:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01018c1:	83 f8 25             	cmp    $0x25,%eax
f01018c4:	75 e2                	jne    f01018a8 <vprintfmt+0x14>
f01018c6:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01018ca:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01018d1:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01018d8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01018df:	ba 00 00 00 00       	mov    $0x0,%edx
f01018e4:	eb 07                	jmp    f01018ed <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01018e6:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01018e9:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01018ed:	8d 47 01             	lea    0x1(%edi),%eax
f01018f0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01018f3:	0f b6 07             	movzbl (%edi),%eax
f01018f6:	0f b6 c8             	movzbl %al,%ecx
f01018f9:	83 e8 23             	sub    $0x23,%eax
f01018fc:	3c 55                	cmp    $0x55,%al
f01018fe:	0f 87 1a 03 00 00    	ja     f0101c1e <vprintfmt+0x38a>
f0101904:	0f b6 c0             	movzbl %al,%eax
f0101907:	ff 24 85 f0 2c 10 f0 	jmp    *-0xfefd310(,%eax,4)
f010190e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101911:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101915:	eb d6                	jmp    f01018ed <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101917:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010191a:	b8 00 00 00 00       	mov    $0x0,%eax
f010191f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101922:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101925:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101929:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f010192c:	8d 51 d0             	lea    -0x30(%ecx),%edx
f010192f:	83 fa 09             	cmp    $0x9,%edx
f0101932:	77 39                	ja     f010196d <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101934:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101937:	eb e9                	jmp    f0101922 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101939:	8b 45 14             	mov    0x14(%ebp),%eax
f010193c:	8d 48 04             	lea    0x4(%eax),%ecx
f010193f:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101942:	8b 00                	mov    (%eax),%eax
f0101944:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101947:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010194a:	eb 27                	jmp    f0101973 <vprintfmt+0xdf>
f010194c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010194f:	85 c0                	test   %eax,%eax
f0101951:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101956:	0f 49 c8             	cmovns %eax,%ecx
f0101959:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010195c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010195f:	eb 8c                	jmp    f01018ed <vprintfmt+0x59>
f0101961:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101964:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010196b:	eb 80                	jmp    f01018ed <vprintfmt+0x59>
f010196d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101970:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0101973:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101977:	0f 89 70 ff ff ff    	jns    f01018ed <vprintfmt+0x59>
				width = precision, precision = -1;
f010197d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101980:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101983:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010198a:	e9 5e ff ff ff       	jmp    f01018ed <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010198f:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101992:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101995:	e9 53 ff ff ff       	jmp    f01018ed <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010199a:	8b 45 14             	mov    0x14(%ebp),%eax
f010199d:	8d 50 04             	lea    0x4(%eax),%edx
f01019a0:	89 55 14             	mov    %edx,0x14(%ebp)
f01019a3:	83 ec 08             	sub    $0x8,%esp
f01019a6:	53                   	push   %ebx
f01019a7:	ff 30                	pushl  (%eax)
f01019a9:	ff d6                	call   *%esi
			break;
f01019ab:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01019b1:	e9 04 ff ff ff       	jmp    f01018ba <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01019b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01019b9:	8d 50 04             	lea    0x4(%eax),%edx
f01019bc:	89 55 14             	mov    %edx,0x14(%ebp)
f01019bf:	8b 00                	mov    (%eax),%eax
f01019c1:	99                   	cltd   
f01019c2:	31 d0                	xor    %edx,%eax
f01019c4:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01019c6:	83 f8 06             	cmp    $0x6,%eax
f01019c9:	7f 0b                	jg     f01019d6 <vprintfmt+0x142>
f01019cb:	8b 14 85 48 2e 10 f0 	mov    -0xfefd1b8(,%eax,4),%edx
f01019d2:	85 d2                	test   %edx,%edx
f01019d4:	75 18                	jne    f01019ee <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01019d6:	50                   	push   %eax
f01019d7:	68 7b 2c 10 f0       	push   $0xf0102c7b
f01019dc:	53                   	push   %ebx
f01019dd:	56                   	push   %esi
f01019de:	e8 94 fe ff ff       	call   f0101877 <printfmt>
f01019e3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019e6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01019e9:	e9 cc fe ff ff       	jmp    f01018ba <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01019ee:	52                   	push   %edx
f01019ef:	68 98 2a 10 f0       	push   $0xf0102a98
f01019f4:	53                   	push   %ebx
f01019f5:	56                   	push   %esi
f01019f6:	e8 7c fe ff ff       	call   f0101877 <printfmt>
f01019fb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a01:	e9 b4 fe ff ff       	jmp    f01018ba <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101a06:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a09:	8d 50 04             	lea    0x4(%eax),%edx
f0101a0c:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a0f:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101a11:	85 ff                	test   %edi,%edi
f0101a13:	b8 74 2c 10 f0       	mov    $0xf0102c74,%eax
f0101a18:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101a1b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101a1f:	0f 8e 94 00 00 00    	jle    f0101ab9 <vprintfmt+0x225>
f0101a25:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101a29:	0f 84 98 00 00 00    	je     f0101ac7 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101a2f:	83 ec 08             	sub    $0x8,%esp
f0101a32:	ff 75 d0             	pushl  -0x30(%ebp)
f0101a35:	57                   	push   %edi
f0101a36:	e8 5f 03 00 00       	call   f0101d9a <strnlen>
f0101a3b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101a3e:	29 c1                	sub    %eax,%ecx
f0101a40:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101a43:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101a46:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101a4a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101a4d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101a50:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101a52:	eb 0f                	jmp    f0101a63 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0101a54:	83 ec 08             	sub    $0x8,%esp
f0101a57:	53                   	push   %ebx
f0101a58:	ff 75 e0             	pushl  -0x20(%ebp)
f0101a5b:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101a5d:	83 ef 01             	sub    $0x1,%edi
f0101a60:	83 c4 10             	add    $0x10,%esp
f0101a63:	85 ff                	test   %edi,%edi
f0101a65:	7f ed                	jg     f0101a54 <vprintfmt+0x1c0>
f0101a67:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101a6a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101a6d:	85 c9                	test   %ecx,%ecx
f0101a6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a74:	0f 49 c1             	cmovns %ecx,%eax
f0101a77:	29 c1                	sub    %eax,%ecx
f0101a79:	89 75 08             	mov    %esi,0x8(%ebp)
f0101a7c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101a7f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101a82:	89 cb                	mov    %ecx,%ebx
f0101a84:	eb 4d                	jmp    f0101ad3 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101a86:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101a8a:	74 1b                	je     f0101aa7 <vprintfmt+0x213>
f0101a8c:	0f be c0             	movsbl %al,%eax
f0101a8f:	83 e8 20             	sub    $0x20,%eax
f0101a92:	83 f8 5e             	cmp    $0x5e,%eax
f0101a95:	76 10                	jbe    f0101aa7 <vprintfmt+0x213>
					putch('?', putdat);
f0101a97:	83 ec 08             	sub    $0x8,%esp
f0101a9a:	ff 75 0c             	pushl  0xc(%ebp)
f0101a9d:	6a 3f                	push   $0x3f
f0101a9f:	ff 55 08             	call   *0x8(%ebp)
f0101aa2:	83 c4 10             	add    $0x10,%esp
f0101aa5:	eb 0d                	jmp    f0101ab4 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101aa7:	83 ec 08             	sub    $0x8,%esp
f0101aaa:	ff 75 0c             	pushl  0xc(%ebp)
f0101aad:	52                   	push   %edx
f0101aae:	ff 55 08             	call   *0x8(%ebp)
f0101ab1:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101ab4:	83 eb 01             	sub    $0x1,%ebx
f0101ab7:	eb 1a                	jmp    f0101ad3 <vprintfmt+0x23f>
f0101ab9:	89 75 08             	mov    %esi,0x8(%ebp)
f0101abc:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101abf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101ac2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101ac5:	eb 0c                	jmp    f0101ad3 <vprintfmt+0x23f>
f0101ac7:	89 75 08             	mov    %esi,0x8(%ebp)
f0101aca:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101acd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101ad0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101ad3:	83 c7 01             	add    $0x1,%edi
f0101ad6:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101ada:	0f be d0             	movsbl %al,%edx
f0101add:	85 d2                	test   %edx,%edx
f0101adf:	74 23                	je     f0101b04 <vprintfmt+0x270>
f0101ae1:	85 f6                	test   %esi,%esi
f0101ae3:	78 a1                	js     f0101a86 <vprintfmt+0x1f2>
f0101ae5:	83 ee 01             	sub    $0x1,%esi
f0101ae8:	79 9c                	jns    f0101a86 <vprintfmt+0x1f2>
f0101aea:	89 df                	mov    %ebx,%edi
f0101aec:	8b 75 08             	mov    0x8(%ebp),%esi
f0101aef:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101af2:	eb 18                	jmp    f0101b0c <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101af4:	83 ec 08             	sub    $0x8,%esp
f0101af7:	53                   	push   %ebx
f0101af8:	6a 20                	push   $0x20
f0101afa:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101afc:	83 ef 01             	sub    $0x1,%edi
f0101aff:	83 c4 10             	add    $0x10,%esp
f0101b02:	eb 08                	jmp    f0101b0c <vprintfmt+0x278>
f0101b04:	89 df                	mov    %ebx,%edi
f0101b06:	8b 75 08             	mov    0x8(%ebp),%esi
f0101b09:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101b0c:	85 ff                	test   %edi,%edi
f0101b0e:	7f e4                	jg     f0101af4 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b10:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101b13:	e9 a2 fd ff ff       	jmp    f01018ba <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101b18:	83 fa 01             	cmp    $0x1,%edx
f0101b1b:	7e 16                	jle    f0101b33 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101b1d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b20:	8d 50 08             	lea    0x8(%eax),%edx
f0101b23:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b26:	8b 50 04             	mov    0x4(%eax),%edx
f0101b29:	8b 00                	mov    (%eax),%eax
f0101b2b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101b2e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101b31:	eb 32                	jmp    f0101b65 <vprintfmt+0x2d1>
	else if (lflag)
f0101b33:	85 d2                	test   %edx,%edx
f0101b35:	74 18                	je     f0101b4f <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101b37:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b3a:	8d 50 04             	lea    0x4(%eax),%edx
f0101b3d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b40:	8b 00                	mov    (%eax),%eax
f0101b42:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101b45:	89 c1                	mov    %eax,%ecx
f0101b47:	c1 f9 1f             	sar    $0x1f,%ecx
f0101b4a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101b4d:	eb 16                	jmp    f0101b65 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101b4f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b52:	8d 50 04             	lea    0x4(%eax),%edx
f0101b55:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b58:	8b 00                	mov    (%eax),%eax
f0101b5a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101b5d:	89 c1                	mov    %eax,%ecx
f0101b5f:	c1 f9 1f             	sar    $0x1f,%ecx
f0101b62:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101b65:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101b68:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101b6b:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101b70:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101b74:	79 74                	jns    f0101bea <vprintfmt+0x356>
				putch('-', putdat);
f0101b76:	83 ec 08             	sub    $0x8,%esp
f0101b79:	53                   	push   %ebx
f0101b7a:	6a 2d                	push   $0x2d
f0101b7c:	ff d6                	call   *%esi
				num = -(long long) num;
f0101b7e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101b81:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101b84:	f7 d8                	neg    %eax
f0101b86:	83 d2 00             	adc    $0x0,%edx
f0101b89:	f7 da                	neg    %edx
f0101b8b:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101b8e:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101b93:	eb 55                	jmp    f0101bea <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101b95:	8d 45 14             	lea    0x14(%ebp),%eax
f0101b98:	e8 83 fc ff ff       	call   f0101820 <getuint>
			base = 10;
f0101b9d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101ba2:	eb 46                	jmp    f0101bea <vprintfmt+0x356>
		case 'o':
			// Replace this with your code.
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap,lflag);
f0101ba4:	8d 45 14             	lea    0x14(%ebp),%eax
f0101ba7:	e8 74 fc ff ff       	call   f0101820 <getuint>
			base = 8;
f0101bac:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101bb1:	eb 37                	jmp    f0101bea <vprintfmt+0x356>
			//break;
		// pointer
		case 'p':
			putch('0', putdat);
f0101bb3:	83 ec 08             	sub    $0x8,%esp
f0101bb6:	53                   	push   %ebx
f0101bb7:	6a 30                	push   $0x30
f0101bb9:	ff d6                	call   *%esi
			putch('x', putdat);
f0101bbb:	83 c4 08             	add    $0x8,%esp
f0101bbe:	53                   	push   %ebx
f0101bbf:	6a 78                	push   $0x78
f0101bc1:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101bc3:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bc6:	8d 50 04             	lea    0x4(%eax),%edx
f0101bc9:	89 55 14             	mov    %edx,0x14(%ebp)
			//break;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101bcc:	8b 00                	mov    (%eax),%eax
f0101bce:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101bd3:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101bd6:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101bdb:	eb 0d                	jmp    f0101bea <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101bdd:	8d 45 14             	lea    0x14(%ebp),%eax
f0101be0:	e8 3b fc ff ff       	call   f0101820 <getuint>
			base = 16;
f0101be5:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101bea:	83 ec 0c             	sub    $0xc,%esp
f0101bed:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101bf1:	57                   	push   %edi
f0101bf2:	ff 75 e0             	pushl  -0x20(%ebp)
f0101bf5:	51                   	push   %ecx
f0101bf6:	52                   	push   %edx
f0101bf7:	50                   	push   %eax
f0101bf8:	89 da                	mov    %ebx,%edx
f0101bfa:	89 f0                	mov    %esi,%eax
f0101bfc:	e8 70 fb ff ff       	call   f0101771 <printnum>
			break;
f0101c01:	83 c4 20             	add    $0x20,%esp
f0101c04:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101c07:	e9 ae fc ff ff       	jmp    f01018ba <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101c0c:	83 ec 08             	sub    $0x8,%esp
f0101c0f:	53                   	push   %ebx
f0101c10:	51                   	push   %ecx
f0101c11:	ff d6                	call   *%esi
			break;
f0101c13:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101c16:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101c19:	e9 9c fc ff ff       	jmp    f01018ba <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101c1e:	83 ec 08             	sub    $0x8,%esp
f0101c21:	53                   	push   %ebx
f0101c22:	6a 25                	push   $0x25
f0101c24:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101c26:	83 c4 10             	add    $0x10,%esp
f0101c29:	eb 03                	jmp    f0101c2e <vprintfmt+0x39a>
f0101c2b:	83 ef 01             	sub    $0x1,%edi
f0101c2e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101c32:	75 f7                	jne    f0101c2b <vprintfmt+0x397>
f0101c34:	e9 81 fc ff ff       	jmp    f01018ba <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101c39:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101c3c:	5b                   	pop    %ebx
f0101c3d:	5e                   	pop    %esi
f0101c3e:	5f                   	pop    %edi
f0101c3f:	5d                   	pop    %ebp
f0101c40:	c3                   	ret    

f0101c41 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101c41:	55                   	push   %ebp
f0101c42:	89 e5                	mov    %esp,%ebp
f0101c44:	83 ec 18             	sub    $0x18,%esp
f0101c47:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c4a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101c4d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101c50:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101c54:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101c57:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101c5e:	85 c0                	test   %eax,%eax
f0101c60:	74 26                	je     f0101c88 <vsnprintf+0x47>
f0101c62:	85 d2                	test   %edx,%edx
f0101c64:	7e 22                	jle    f0101c88 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101c66:	ff 75 14             	pushl  0x14(%ebp)
f0101c69:	ff 75 10             	pushl  0x10(%ebp)
f0101c6c:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101c6f:	50                   	push   %eax
f0101c70:	68 5a 18 10 f0       	push   $0xf010185a
f0101c75:	e8 1a fc ff ff       	call   f0101894 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101c7a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c7d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101c80:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101c83:	83 c4 10             	add    $0x10,%esp
f0101c86:	eb 05                	jmp    f0101c8d <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101c88:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101c8d:	c9                   	leave  
f0101c8e:	c3                   	ret    

f0101c8f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101c8f:	55                   	push   %ebp
f0101c90:	89 e5                	mov    %esp,%ebp
f0101c92:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101c95:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101c98:	50                   	push   %eax
f0101c99:	ff 75 10             	pushl  0x10(%ebp)
f0101c9c:	ff 75 0c             	pushl  0xc(%ebp)
f0101c9f:	ff 75 08             	pushl  0x8(%ebp)
f0101ca2:	e8 9a ff ff ff       	call   f0101c41 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101ca7:	c9                   	leave  
f0101ca8:	c3                   	ret    

f0101ca9 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101ca9:	55                   	push   %ebp
f0101caa:	89 e5                	mov    %esp,%ebp
f0101cac:	57                   	push   %edi
f0101cad:	56                   	push   %esi
f0101cae:	53                   	push   %ebx
f0101caf:	83 ec 0c             	sub    $0xc,%esp
f0101cb2:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101cb5:	85 c0                	test   %eax,%eax
f0101cb7:	74 11                	je     f0101cca <readline+0x21>
		cprintf("%s", prompt);
f0101cb9:	83 ec 08             	sub    $0x8,%esp
f0101cbc:	50                   	push   %eax
f0101cbd:	68 98 2a 10 f0       	push   $0xf0102a98
f0101cc2:	e8 80 f7 ff ff       	call   f0101447 <cprintf>
f0101cc7:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101cca:	83 ec 0c             	sub    $0xc,%esp
f0101ccd:	6a 00                	push   $0x0
f0101ccf:	e8 4d e9 ff ff       	call   f0100621 <iscons>
f0101cd4:	89 c7                	mov    %eax,%edi
f0101cd6:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101cd9:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101cde:	e8 2d e9 ff ff       	call   f0100610 <getchar>
f0101ce3:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101ce5:	85 c0                	test   %eax,%eax
f0101ce7:	79 18                	jns    f0101d01 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101ce9:	83 ec 08             	sub    $0x8,%esp
f0101cec:	50                   	push   %eax
f0101ced:	68 64 2e 10 f0       	push   $0xf0102e64
f0101cf2:	e8 50 f7 ff ff       	call   f0101447 <cprintf>
			return NULL;
f0101cf7:	83 c4 10             	add    $0x10,%esp
f0101cfa:	b8 00 00 00 00       	mov    $0x0,%eax
f0101cff:	eb 79                	jmp    f0101d7a <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101d01:	83 f8 08             	cmp    $0x8,%eax
f0101d04:	0f 94 c2             	sete   %dl
f0101d07:	83 f8 7f             	cmp    $0x7f,%eax
f0101d0a:	0f 94 c0             	sete   %al
f0101d0d:	08 c2                	or     %al,%dl
f0101d0f:	74 1a                	je     f0101d2b <readline+0x82>
f0101d11:	85 f6                	test   %esi,%esi
f0101d13:	7e 16                	jle    f0101d2b <readline+0x82>
			if (echoing)
f0101d15:	85 ff                	test   %edi,%edi
f0101d17:	74 0d                	je     f0101d26 <readline+0x7d>
				cputchar('\b');
f0101d19:	83 ec 0c             	sub    $0xc,%esp
f0101d1c:	6a 08                	push   $0x8
f0101d1e:	e8 dd e8 ff ff       	call   f0100600 <cputchar>
f0101d23:	83 c4 10             	add    $0x10,%esp
			i--;
f0101d26:	83 ee 01             	sub    $0x1,%esi
f0101d29:	eb b3                	jmp    f0101cde <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101d2b:	83 fb 1f             	cmp    $0x1f,%ebx
f0101d2e:	7e 23                	jle    f0101d53 <readline+0xaa>
f0101d30:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101d36:	7f 1b                	jg     f0101d53 <readline+0xaa>
			if (echoing)
f0101d38:	85 ff                	test   %edi,%edi
f0101d3a:	74 0c                	je     f0101d48 <readline+0x9f>
				cputchar(c);
f0101d3c:	83 ec 0c             	sub    $0xc,%esp
f0101d3f:	53                   	push   %ebx
f0101d40:	e8 bb e8 ff ff       	call   f0100600 <cputchar>
f0101d45:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101d48:	88 9e 60 45 11 f0    	mov    %bl,-0xfeebaa0(%esi)
f0101d4e:	8d 76 01             	lea    0x1(%esi),%esi
f0101d51:	eb 8b                	jmp    f0101cde <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101d53:	83 fb 0a             	cmp    $0xa,%ebx
f0101d56:	74 05                	je     f0101d5d <readline+0xb4>
f0101d58:	83 fb 0d             	cmp    $0xd,%ebx
f0101d5b:	75 81                	jne    f0101cde <readline+0x35>
			if (echoing)
f0101d5d:	85 ff                	test   %edi,%edi
f0101d5f:	74 0d                	je     f0101d6e <readline+0xc5>
				cputchar('\n');
f0101d61:	83 ec 0c             	sub    $0xc,%esp
f0101d64:	6a 0a                	push   $0xa
f0101d66:	e8 95 e8 ff ff       	call   f0100600 <cputchar>
f0101d6b:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101d6e:	c6 86 60 45 11 f0 00 	movb   $0x0,-0xfeebaa0(%esi)
			return buf;
f0101d75:	b8 60 45 11 f0       	mov    $0xf0114560,%eax
		}
	}
}
f0101d7a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d7d:	5b                   	pop    %ebx
f0101d7e:	5e                   	pop    %esi
f0101d7f:	5f                   	pop    %edi
f0101d80:	5d                   	pop    %ebp
f0101d81:	c3                   	ret    

f0101d82 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101d82:	55                   	push   %ebp
f0101d83:	89 e5                	mov    %esp,%ebp
f0101d85:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101d88:	b8 00 00 00 00       	mov    $0x0,%eax
f0101d8d:	eb 03                	jmp    f0101d92 <strlen+0x10>
		n++;
f0101d8f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101d92:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101d96:	75 f7                	jne    f0101d8f <strlen+0xd>
		n++;
	return n;
}
f0101d98:	5d                   	pop    %ebp
f0101d99:	c3                   	ret    

f0101d9a <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101d9a:	55                   	push   %ebp
f0101d9b:	89 e5                	mov    %esp,%ebp
f0101d9d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101da0:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101da3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101da8:	eb 03                	jmp    f0101dad <strnlen+0x13>
		n++;
f0101daa:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101dad:	39 c2                	cmp    %eax,%edx
f0101daf:	74 08                	je     f0101db9 <strnlen+0x1f>
f0101db1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101db5:	75 f3                	jne    f0101daa <strnlen+0x10>
f0101db7:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101db9:	5d                   	pop    %ebp
f0101dba:	c3                   	ret    

f0101dbb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101dbb:	55                   	push   %ebp
f0101dbc:	89 e5                	mov    %esp,%ebp
f0101dbe:	53                   	push   %ebx
f0101dbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dc2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101dc5:	89 c2                	mov    %eax,%edx
f0101dc7:	83 c2 01             	add    $0x1,%edx
f0101dca:	83 c1 01             	add    $0x1,%ecx
f0101dcd:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101dd1:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101dd4:	84 db                	test   %bl,%bl
f0101dd6:	75 ef                	jne    f0101dc7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101dd8:	5b                   	pop    %ebx
f0101dd9:	5d                   	pop    %ebp
f0101dda:	c3                   	ret    

f0101ddb <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101ddb:	55                   	push   %ebp
f0101ddc:	89 e5                	mov    %esp,%ebp
f0101dde:	53                   	push   %ebx
f0101ddf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101de2:	53                   	push   %ebx
f0101de3:	e8 9a ff ff ff       	call   f0101d82 <strlen>
f0101de8:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101deb:	ff 75 0c             	pushl  0xc(%ebp)
f0101dee:	01 d8                	add    %ebx,%eax
f0101df0:	50                   	push   %eax
f0101df1:	e8 c5 ff ff ff       	call   f0101dbb <strcpy>
	return dst;
}
f0101df6:	89 d8                	mov    %ebx,%eax
f0101df8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101dfb:	c9                   	leave  
f0101dfc:	c3                   	ret    

f0101dfd <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101dfd:	55                   	push   %ebp
f0101dfe:	89 e5                	mov    %esp,%ebp
f0101e00:	56                   	push   %esi
f0101e01:	53                   	push   %ebx
f0101e02:	8b 75 08             	mov    0x8(%ebp),%esi
f0101e05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101e08:	89 f3                	mov    %esi,%ebx
f0101e0a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101e0d:	89 f2                	mov    %esi,%edx
f0101e0f:	eb 0f                	jmp    f0101e20 <strncpy+0x23>
		*dst++ = *src;
f0101e11:	83 c2 01             	add    $0x1,%edx
f0101e14:	0f b6 01             	movzbl (%ecx),%eax
f0101e17:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101e1a:	80 39 01             	cmpb   $0x1,(%ecx)
f0101e1d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101e20:	39 da                	cmp    %ebx,%edx
f0101e22:	75 ed                	jne    f0101e11 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101e24:	89 f0                	mov    %esi,%eax
f0101e26:	5b                   	pop    %ebx
f0101e27:	5e                   	pop    %esi
f0101e28:	5d                   	pop    %ebp
f0101e29:	c3                   	ret    

f0101e2a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101e2a:	55                   	push   %ebp
f0101e2b:	89 e5                	mov    %esp,%ebp
f0101e2d:	56                   	push   %esi
f0101e2e:	53                   	push   %ebx
f0101e2f:	8b 75 08             	mov    0x8(%ebp),%esi
f0101e32:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101e35:	8b 55 10             	mov    0x10(%ebp),%edx
f0101e38:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101e3a:	85 d2                	test   %edx,%edx
f0101e3c:	74 21                	je     f0101e5f <strlcpy+0x35>
f0101e3e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101e42:	89 f2                	mov    %esi,%edx
f0101e44:	eb 09                	jmp    f0101e4f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101e46:	83 c2 01             	add    $0x1,%edx
f0101e49:	83 c1 01             	add    $0x1,%ecx
f0101e4c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101e4f:	39 c2                	cmp    %eax,%edx
f0101e51:	74 09                	je     f0101e5c <strlcpy+0x32>
f0101e53:	0f b6 19             	movzbl (%ecx),%ebx
f0101e56:	84 db                	test   %bl,%bl
f0101e58:	75 ec                	jne    f0101e46 <strlcpy+0x1c>
f0101e5a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101e5c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101e5f:	29 f0                	sub    %esi,%eax
}
f0101e61:	5b                   	pop    %ebx
f0101e62:	5e                   	pop    %esi
f0101e63:	5d                   	pop    %ebp
f0101e64:	c3                   	ret    

f0101e65 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101e65:	55                   	push   %ebp
f0101e66:	89 e5                	mov    %esp,%ebp
f0101e68:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e6b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101e6e:	eb 06                	jmp    f0101e76 <strcmp+0x11>
		p++, q++;
f0101e70:	83 c1 01             	add    $0x1,%ecx
f0101e73:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101e76:	0f b6 01             	movzbl (%ecx),%eax
f0101e79:	84 c0                	test   %al,%al
f0101e7b:	74 04                	je     f0101e81 <strcmp+0x1c>
f0101e7d:	3a 02                	cmp    (%edx),%al
f0101e7f:	74 ef                	je     f0101e70 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101e81:	0f b6 c0             	movzbl %al,%eax
f0101e84:	0f b6 12             	movzbl (%edx),%edx
f0101e87:	29 d0                	sub    %edx,%eax
}
f0101e89:	5d                   	pop    %ebp
f0101e8a:	c3                   	ret    

f0101e8b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101e8b:	55                   	push   %ebp
f0101e8c:	89 e5                	mov    %esp,%ebp
f0101e8e:	53                   	push   %ebx
f0101e8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e92:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101e95:	89 c3                	mov    %eax,%ebx
f0101e97:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101e9a:	eb 06                	jmp    f0101ea2 <strncmp+0x17>
		n--, p++, q++;
f0101e9c:	83 c0 01             	add    $0x1,%eax
f0101e9f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101ea2:	39 d8                	cmp    %ebx,%eax
f0101ea4:	74 15                	je     f0101ebb <strncmp+0x30>
f0101ea6:	0f b6 08             	movzbl (%eax),%ecx
f0101ea9:	84 c9                	test   %cl,%cl
f0101eab:	74 04                	je     f0101eb1 <strncmp+0x26>
f0101ead:	3a 0a                	cmp    (%edx),%cl
f0101eaf:	74 eb                	je     f0101e9c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101eb1:	0f b6 00             	movzbl (%eax),%eax
f0101eb4:	0f b6 12             	movzbl (%edx),%edx
f0101eb7:	29 d0                	sub    %edx,%eax
f0101eb9:	eb 05                	jmp    f0101ec0 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101ebb:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101ec0:	5b                   	pop    %ebx
f0101ec1:	5d                   	pop    %ebp
f0101ec2:	c3                   	ret    

f0101ec3 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101ec3:	55                   	push   %ebp
f0101ec4:	89 e5                	mov    %esp,%ebp
f0101ec6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ec9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101ecd:	eb 07                	jmp    f0101ed6 <strchr+0x13>
		if (*s == c)
f0101ecf:	38 ca                	cmp    %cl,%dl
f0101ed1:	74 0f                	je     f0101ee2 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101ed3:	83 c0 01             	add    $0x1,%eax
f0101ed6:	0f b6 10             	movzbl (%eax),%edx
f0101ed9:	84 d2                	test   %dl,%dl
f0101edb:	75 f2                	jne    f0101ecf <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101edd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101ee2:	5d                   	pop    %ebp
f0101ee3:	c3                   	ret    

f0101ee4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101ee4:	55                   	push   %ebp
f0101ee5:	89 e5                	mov    %esp,%ebp
f0101ee7:	8b 45 08             	mov    0x8(%ebp),%eax
f0101eea:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101eee:	eb 03                	jmp    f0101ef3 <strfind+0xf>
f0101ef0:	83 c0 01             	add    $0x1,%eax
f0101ef3:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101ef6:	38 ca                	cmp    %cl,%dl
f0101ef8:	74 04                	je     f0101efe <strfind+0x1a>
f0101efa:	84 d2                	test   %dl,%dl
f0101efc:	75 f2                	jne    f0101ef0 <strfind+0xc>
			break;
	return (char *) s;
}
f0101efe:	5d                   	pop    %ebp
f0101eff:	c3                   	ret    

f0101f00 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101f00:	55                   	push   %ebp
f0101f01:	89 e5                	mov    %esp,%ebp
f0101f03:	57                   	push   %edi
f0101f04:	56                   	push   %esi
f0101f05:	53                   	push   %ebx
f0101f06:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101f09:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101f0c:	85 c9                	test   %ecx,%ecx
f0101f0e:	74 36                	je     f0101f46 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101f10:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101f16:	75 28                	jne    f0101f40 <memset+0x40>
f0101f18:	f6 c1 03             	test   $0x3,%cl
f0101f1b:	75 23                	jne    f0101f40 <memset+0x40>
		c &= 0xFF;
f0101f1d:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101f21:	89 d3                	mov    %edx,%ebx
f0101f23:	c1 e3 08             	shl    $0x8,%ebx
f0101f26:	89 d6                	mov    %edx,%esi
f0101f28:	c1 e6 18             	shl    $0x18,%esi
f0101f2b:	89 d0                	mov    %edx,%eax
f0101f2d:	c1 e0 10             	shl    $0x10,%eax
f0101f30:	09 f0                	or     %esi,%eax
f0101f32:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101f34:	89 d8                	mov    %ebx,%eax
f0101f36:	09 d0                	or     %edx,%eax
f0101f38:	c1 e9 02             	shr    $0x2,%ecx
f0101f3b:	fc                   	cld    
f0101f3c:	f3 ab                	rep stos %eax,%es:(%edi)
f0101f3e:	eb 06                	jmp    f0101f46 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101f40:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101f43:	fc                   	cld    
f0101f44:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101f46:	89 f8                	mov    %edi,%eax
f0101f48:	5b                   	pop    %ebx
f0101f49:	5e                   	pop    %esi
f0101f4a:	5f                   	pop    %edi
f0101f4b:	5d                   	pop    %ebp
f0101f4c:	c3                   	ret    

f0101f4d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101f4d:	55                   	push   %ebp
f0101f4e:	89 e5                	mov    %esp,%ebp
f0101f50:	57                   	push   %edi
f0101f51:	56                   	push   %esi
f0101f52:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f55:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101f58:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101f5b:	39 c6                	cmp    %eax,%esi
f0101f5d:	73 35                	jae    f0101f94 <memmove+0x47>
f0101f5f:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101f62:	39 d0                	cmp    %edx,%eax
f0101f64:	73 2e                	jae    f0101f94 <memmove+0x47>
		s += n;
		d += n;
f0101f66:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101f69:	89 d6                	mov    %edx,%esi
f0101f6b:	09 fe                	or     %edi,%esi
f0101f6d:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101f73:	75 13                	jne    f0101f88 <memmove+0x3b>
f0101f75:	f6 c1 03             	test   $0x3,%cl
f0101f78:	75 0e                	jne    f0101f88 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101f7a:	83 ef 04             	sub    $0x4,%edi
f0101f7d:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101f80:	c1 e9 02             	shr    $0x2,%ecx
f0101f83:	fd                   	std    
f0101f84:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101f86:	eb 09                	jmp    f0101f91 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101f88:	83 ef 01             	sub    $0x1,%edi
f0101f8b:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101f8e:	fd                   	std    
f0101f8f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101f91:	fc                   	cld    
f0101f92:	eb 1d                	jmp    f0101fb1 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101f94:	89 f2                	mov    %esi,%edx
f0101f96:	09 c2                	or     %eax,%edx
f0101f98:	f6 c2 03             	test   $0x3,%dl
f0101f9b:	75 0f                	jne    f0101fac <memmove+0x5f>
f0101f9d:	f6 c1 03             	test   $0x3,%cl
f0101fa0:	75 0a                	jne    f0101fac <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0101fa2:	c1 e9 02             	shr    $0x2,%ecx
f0101fa5:	89 c7                	mov    %eax,%edi
f0101fa7:	fc                   	cld    
f0101fa8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101faa:	eb 05                	jmp    f0101fb1 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101fac:	89 c7                	mov    %eax,%edi
f0101fae:	fc                   	cld    
f0101faf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101fb1:	5e                   	pop    %esi
f0101fb2:	5f                   	pop    %edi
f0101fb3:	5d                   	pop    %ebp
f0101fb4:	c3                   	ret    

f0101fb5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101fb5:	55                   	push   %ebp
f0101fb6:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101fb8:	ff 75 10             	pushl  0x10(%ebp)
f0101fbb:	ff 75 0c             	pushl  0xc(%ebp)
f0101fbe:	ff 75 08             	pushl  0x8(%ebp)
f0101fc1:	e8 87 ff ff ff       	call   f0101f4d <memmove>
}
f0101fc6:	c9                   	leave  
f0101fc7:	c3                   	ret    

f0101fc8 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101fc8:	55                   	push   %ebp
f0101fc9:	89 e5                	mov    %esp,%ebp
f0101fcb:	56                   	push   %esi
f0101fcc:	53                   	push   %ebx
f0101fcd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fd0:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101fd3:	89 c6                	mov    %eax,%esi
f0101fd5:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101fd8:	eb 1a                	jmp    f0101ff4 <memcmp+0x2c>
		if (*s1 != *s2)
f0101fda:	0f b6 08             	movzbl (%eax),%ecx
f0101fdd:	0f b6 1a             	movzbl (%edx),%ebx
f0101fe0:	38 d9                	cmp    %bl,%cl
f0101fe2:	74 0a                	je     f0101fee <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101fe4:	0f b6 c1             	movzbl %cl,%eax
f0101fe7:	0f b6 db             	movzbl %bl,%ebx
f0101fea:	29 d8                	sub    %ebx,%eax
f0101fec:	eb 0f                	jmp    f0101ffd <memcmp+0x35>
		s1++, s2++;
f0101fee:	83 c0 01             	add    $0x1,%eax
f0101ff1:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101ff4:	39 f0                	cmp    %esi,%eax
f0101ff6:	75 e2                	jne    f0101fda <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101ff8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101ffd:	5b                   	pop    %ebx
f0101ffe:	5e                   	pop    %esi
f0101fff:	5d                   	pop    %ebp
f0102000:	c3                   	ret    

f0102001 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102001:	55                   	push   %ebp
f0102002:	89 e5                	mov    %esp,%ebp
f0102004:	53                   	push   %ebx
f0102005:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0102008:	89 c1                	mov    %eax,%ecx
f010200a:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010200d:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0102011:	eb 0a                	jmp    f010201d <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102013:	0f b6 10             	movzbl (%eax),%edx
f0102016:	39 da                	cmp    %ebx,%edx
f0102018:	74 07                	je     f0102021 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010201a:	83 c0 01             	add    $0x1,%eax
f010201d:	39 c8                	cmp    %ecx,%eax
f010201f:	72 f2                	jb     f0102013 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0102021:	5b                   	pop    %ebx
f0102022:	5d                   	pop    %ebp
f0102023:	c3                   	ret    

f0102024 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102024:	55                   	push   %ebp
f0102025:	89 e5                	mov    %esp,%ebp
f0102027:	57                   	push   %edi
f0102028:	56                   	push   %esi
f0102029:	53                   	push   %ebx
f010202a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010202d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102030:	eb 03                	jmp    f0102035 <strtol+0x11>
		s++;
f0102032:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102035:	0f b6 01             	movzbl (%ecx),%eax
f0102038:	3c 20                	cmp    $0x20,%al
f010203a:	74 f6                	je     f0102032 <strtol+0xe>
f010203c:	3c 09                	cmp    $0x9,%al
f010203e:	74 f2                	je     f0102032 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0102040:	3c 2b                	cmp    $0x2b,%al
f0102042:	75 0a                	jne    f010204e <strtol+0x2a>
		s++;
f0102044:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102047:	bf 00 00 00 00       	mov    $0x0,%edi
f010204c:	eb 11                	jmp    f010205f <strtol+0x3b>
f010204e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0102053:	3c 2d                	cmp    $0x2d,%al
f0102055:	75 08                	jne    f010205f <strtol+0x3b>
		s++, neg = 1;
f0102057:	83 c1 01             	add    $0x1,%ecx
f010205a:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010205f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102065:	75 15                	jne    f010207c <strtol+0x58>
f0102067:	80 39 30             	cmpb   $0x30,(%ecx)
f010206a:	75 10                	jne    f010207c <strtol+0x58>
f010206c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0102070:	75 7c                	jne    f01020ee <strtol+0xca>
		s += 2, base = 16;
f0102072:	83 c1 02             	add    $0x2,%ecx
f0102075:	bb 10 00 00 00       	mov    $0x10,%ebx
f010207a:	eb 16                	jmp    f0102092 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010207c:	85 db                	test   %ebx,%ebx
f010207e:	75 12                	jne    f0102092 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102080:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102085:	80 39 30             	cmpb   $0x30,(%ecx)
f0102088:	75 08                	jne    f0102092 <strtol+0x6e>
		s++, base = 8;
f010208a:	83 c1 01             	add    $0x1,%ecx
f010208d:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0102092:	b8 00 00 00 00       	mov    $0x0,%eax
f0102097:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010209a:	0f b6 11             	movzbl (%ecx),%edx
f010209d:	8d 72 d0             	lea    -0x30(%edx),%esi
f01020a0:	89 f3                	mov    %esi,%ebx
f01020a2:	80 fb 09             	cmp    $0x9,%bl
f01020a5:	77 08                	ja     f01020af <strtol+0x8b>
			dig = *s - '0';
f01020a7:	0f be d2             	movsbl %dl,%edx
f01020aa:	83 ea 30             	sub    $0x30,%edx
f01020ad:	eb 22                	jmp    f01020d1 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01020af:	8d 72 9f             	lea    -0x61(%edx),%esi
f01020b2:	89 f3                	mov    %esi,%ebx
f01020b4:	80 fb 19             	cmp    $0x19,%bl
f01020b7:	77 08                	ja     f01020c1 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01020b9:	0f be d2             	movsbl %dl,%edx
f01020bc:	83 ea 57             	sub    $0x57,%edx
f01020bf:	eb 10                	jmp    f01020d1 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01020c1:	8d 72 bf             	lea    -0x41(%edx),%esi
f01020c4:	89 f3                	mov    %esi,%ebx
f01020c6:	80 fb 19             	cmp    $0x19,%bl
f01020c9:	77 16                	ja     f01020e1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01020cb:	0f be d2             	movsbl %dl,%edx
f01020ce:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01020d1:	3b 55 10             	cmp    0x10(%ebp),%edx
f01020d4:	7d 0b                	jge    f01020e1 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01020d6:	83 c1 01             	add    $0x1,%ecx
f01020d9:	0f af 45 10          	imul   0x10(%ebp),%eax
f01020dd:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01020df:	eb b9                	jmp    f010209a <strtol+0x76>

	if (endptr)
f01020e1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01020e5:	74 0d                	je     f01020f4 <strtol+0xd0>
		*endptr = (char *) s;
f01020e7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01020ea:	89 0e                	mov    %ecx,(%esi)
f01020ec:	eb 06                	jmp    f01020f4 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01020ee:	85 db                	test   %ebx,%ebx
f01020f0:	74 98                	je     f010208a <strtol+0x66>
f01020f2:	eb 9e                	jmp    f0102092 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01020f4:	89 c2                	mov    %eax,%edx
f01020f6:	f7 da                	neg    %edx
f01020f8:	85 ff                	test   %edi,%edi
f01020fa:	0f 45 c2             	cmovne %edx,%eax
}
f01020fd:	5b                   	pop    %ebx
f01020fe:	5e                   	pop    %esi
f01020ff:	5f                   	pop    %edi
f0102100:	5d                   	pop    %ebp
f0102101:	c3                   	ret    
f0102102:	66 90                	xchg   %ax,%ax
f0102104:	66 90                	xchg   %ax,%ax
f0102106:	66 90                	xchg   %ax,%ax
f0102108:	66 90                	xchg   %ax,%ax
f010210a:	66 90                	xchg   %ax,%ax
f010210c:	66 90                	xchg   %ax,%ax
f010210e:	66 90                	xchg   %ax,%ax

f0102110 <__udivdi3>:
f0102110:	55                   	push   %ebp
f0102111:	57                   	push   %edi
f0102112:	56                   	push   %esi
f0102113:	53                   	push   %ebx
f0102114:	83 ec 1c             	sub    $0x1c,%esp
f0102117:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010211b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010211f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0102123:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102127:	85 f6                	test   %esi,%esi
f0102129:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010212d:	89 ca                	mov    %ecx,%edx
f010212f:	89 f8                	mov    %edi,%eax
f0102131:	75 3d                	jne    f0102170 <__udivdi3+0x60>
f0102133:	39 cf                	cmp    %ecx,%edi
f0102135:	0f 87 c5 00 00 00    	ja     f0102200 <__udivdi3+0xf0>
f010213b:	85 ff                	test   %edi,%edi
f010213d:	89 fd                	mov    %edi,%ebp
f010213f:	75 0b                	jne    f010214c <__udivdi3+0x3c>
f0102141:	b8 01 00 00 00       	mov    $0x1,%eax
f0102146:	31 d2                	xor    %edx,%edx
f0102148:	f7 f7                	div    %edi
f010214a:	89 c5                	mov    %eax,%ebp
f010214c:	89 c8                	mov    %ecx,%eax
f010214e:	31 d2                	xor    %edx,%edx
f0102150:	f7 f5                	div    %ebp
f0102152:	89 c1                	mov    %eax,%ecx
f0102154:	89 d8                	mov    %ebx,%eax
f0102156:	89 cf                	mov    %ecx,%edi
f0102158:	f7 f5                	div    %ebp
f010215a:	89 c3                	mov    %eax,%ebx
f010215c:	89 d8                	mov    %ebx,%eax
f010215e:	89 fa                	mov    %edi,%edx
f0102160:	83 c4 1c             	add    $0x1c,%esp
f0102163:	5b                   	pop    %ebx
f0102164:	5e                   	pop    %esi
f0102165:	5f                   	pop    %edi
f0102166:	5d                   	pop    %ebp
f0102167:	c3                   	ret    
f0102168:	90                   	nop
f0102169:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102170:	39 ce                	cmp    %ecx,%esi
f0102172:	77 74                	ja     f01021e8 <__udivdi3+0xd8>
f0102174:	0f bd fe             	bsr    %esi,%edi
f0102177:	83 f7 1f             	xor    $0x1f,%edi
f010217a:	0f 84 98 00 00 00    	je     f0102218 <__udivdi3+0x108>
f0102180:	bb 20 00 00 00       	mov    $0x20,%ebx
f0102185:	89 f9                	mov    %edi,%ecx
f0102187:	89 c5                	mov    %eax,%ebp
f0102189:	29 fb                	sub    %edi,%ebx
f010218b:	d3 e6                	shl    %cl,%esi
f010218d:	89 d9                	mov    %ebx,%ecx
f010218f:	d3 ed                	shr    %cl,%ebp
f0102191:	89 f9                	mov    %edi,%ecx
f0102193:	d3 e0                	shl    %cl,%eax
f0102195:	09 ee                	or     %ebp,%esi
f0102197:	89 d9                	mov    %ebx,%ecx
f0102199:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010219d:	89 d5                	mov    %edx,%ebp
f010219f:	8b 44 24 08          	mov    0x8(%esp),%eax
f01021a3:	d3 ed                	shr    %cl,%ebp
f01021a5:	89 f9                	mov    %edi,%ecx
f01021a7:	d3 e2                	shl    %cl,%edx
f01021a9:	89 d9                	mov    %ebx,%ecx
f01021ab:	d3 e8                	shr    %cl,%eax
f01021ad:	09 c2                	or     %eax,%edx
f01021af:	89 d0                	mov    %edx,%eax
f01021b1:	89 ea                	mov    %ebp,%edx
f01021b3:	f7 f6                	div    %esi
f01021b5:	89 d5                	mov    %edx,%ebp
f01021b7:	89 c3                	mov    %eax,%ebx
f01021b9:	f7 64 24 0c          	mull   0xc(%esp)
f01021bd:	39 d5                	cmp    %edx,%ebp
f01021bf:	72 10                	jb     f01021d1 <__udivdi3+0xc1>
f01021c1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01021c5:	89 f9                	mov    %edi,%ecx
f01021c7:	d3 e6                	shl    %cl,%esi
f01021c9:	39 c6                	cmp    %eax,%esi
f01021cb:	73 07                	jae    f01021d4 <__udivdi3+0xc4>
f01021cd:	39 d5                	cmp    %edx,%ebp
f01021cf:	75 03                	jne    f01021d4 <__udivdi3+0xc4>
f01021d1:	83 eb 01             	sub    $0x1,%ebx
f01021d4:	31 ff                	xor    %edi,%edi
f01021d6:	89 d8                	mov    %ebx,%eax
f01021d8:	89 fa                	mov    %edi,%edx
f01021da:	83 c4 1c             	add    $0x1c,%esp
f01021dd:	5b                   	pop    %ebx
f01021de:	5e                   	pop    %esi
f01021df:	5f                   	pop    %edi
f01021e0:	5d                   	pop    %ebp
f01021e1:	c3                   	ret    
f01021e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01021e8:	31 ff                	xor    %edi,%edi
f01021ea:	31 db                	xor    %ebx,%ebx
f01021ec:	89 d8                	mov    %ebx,%eax
f01021ee:	89 fa                	mov    %edi,%edx
f01021f0:	83 c4 1c             	add    $0x1c,%esp
f01021f3:	5b                   	pop    %ebx
f01021f4:	5e                   	pop    %esi
f01021f5:	5f                   	pop    %edi
f01021f6:	5d                   	pop    %ebp
f01021f7:	c3                   	ret    
f01021f8:	90                   	nop
f01021f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102200:	89 d8                	mov    %ebx,%eax
f0102202:	f7 f7                	div    %edi
f0102204:	31 ff                	xor    %edi,%edi
f0102206:	89 c3                	mov    %eax,%ebx
f0102208:	89 d8                	mov    %ebx,%eax
f010220a:	89 fa                	mov    %edi,%edx
f010220c:	83 c4 1c             	add    $0x1c,%esp
f010220f:	5b                   	pop    %ebx
f0102210:	5e                   	pop    %esi
f0102211:	5f                   	pop    %edi
f0102212:	5d                   	pop    %ebp
f0102213:	c3                   	ret    
f0102214:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102218:	39 ce                	cmp    %ecx,%esi
f010221a:	72 0c                	jb     f0102228 <__udivdi3+0x118>
f010221c:	31 db                	xor    %ebx,%ebx
f010221e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0102222:	0f 87 34 ff ff ff    	ja     f010215c <__udivdi3+0x4c>
f0102228:	bb 01 00 00 00       	mov    $0x1,%ebx
f010222d:	e9 2a ff ff ff       	jmp    f010215c <__udivdi3+0x4c>
f0102232:	66 90                	xchg   %ax,%ax
f0102234:	66 90                	xchg   %ax,%ax
f0102236:	66 90                	xchg   %ax,%ax
f0102238:	66 90                	xchg   %ax,%ax
f010223a:	66 90                	xchg   %ax,%ax
f010223c:	66 90                	xchg   %ax,%ax
f010223e:	66 90                	xchg   %ax,%ax

f0102240 <__umoddi3>:
f0102240:	55                   	push   %ebp
f0102241:	57                   	push   %edi
f0102242:	56                   	push   %esi
f0102243:	53                   	push   %ebx
f0102244:	83 ec 1c             	sub    $0x1c,%esp
f0102247:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010224b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010224f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102253:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102257:	85 d2                	test   %edx,%edx
f0102259:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010225d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102261:	89 f3                	mov    %esi,%ebx
f0102263:	89 3c 24             	mov    %edi,(%esp)
f0102266:	89 74 24 04          	mov    %esi,0x4(%esp)
f010226a:	75 1c                	jne    f0102288 <__umoddi3+0x48>
f010226c:	39 f7                	cmp    %esi,%edi
f010226e:	76 50                	jbe    f01022c0 <__umoddi3+0x80>
f0102270:	89 c8                	mov    %ecx,%eax
f0102272:	89 f2                	mov    %esi,%edx
f0102274:	f7 f7                	div    %edi
f0102276:	89 d0                	mov    %edx,%eax
f0102278:	31 d2                	xor    %edx,%edx
f010227a:	83 c4 1c             	add    $0x1c,%esp
f010227d:	5b                   	pop    %ebx
f010227e:	5e                   	pop    %esi
f010227f:	5f                   	pop    %edi
f0102280:	5d                   	pop    %ebp
f0102281:	c3                   	ret    
f0102282:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102288:	39 f2                	cmp    %esi,%edx
f010228a:	89 d0                	mov    %edx,%eax
f010228c:	77 52                	ja     f01022e0 <__umoddi3+0xa0>
f010228e:	0f bd ea             	bsr    %edx,%ebp
f0102291:	83 f5 1f             	xor    $0x1f,%ebp
f0102294:	75 5a                	jne    f01022f0 <__umoddi3+0xb0>
f0102296:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010229a:	0f 82 e0 00 00 00    	jb     f0102380 <__umoddi3+0x140>
f01022a0:	39 0c 24             	cmp    %ecx,(%esp)
f01022a3:	0f 86 d7 00 00 00    	jbe    f0102380 <__umoddi3+0x140>
f01022a9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01022ad:	8b 54 24 04          	mov    0x4(%esp),%edx
f01022b1:	83 c4 1c             	add    $0x1c,%esp
f01022b4:	5b                   	pop    %ebx
f01022b5:	5e                   	pop    %esi
f01022b6:	5f                   	pop    %edi
f01022b7:	5d                   	pop    %ebp
f01022b8:	c3                   	ret    
f01022b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01022c0:	85 ff                	test   %edi,%edi
f01022c2:	89 fd                	mov    %edi,%ebp
f01022c4:	75 0b                	jne    f01022d1 <__umoddi3+0x91>
f01022c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01022cb:	31 d2                	xor    %edx,%edx
f01022cd:	f7 f7                	div    %edi
f01022cf:	89 c5                	mov    %eax,%ebp
f01022d1:	89 f0                	mov    %esi,%eax
f01022d3:	31 d2                	xor    %edx,%edx
f01022d5:	f7 f5                	div    %ebp
f01022d7:	89 c8                	mov    %ecx,%eax
f01022d9:	f7 f5                	div    %ebp
f01022db:	89 d0                	mov    %edx,%eax
f01022dd:	eb 99                	jmp    f0102278 <__umoddi3+0x38>
f01022df:	90                   	nop
f01022e0:	89 c8                	mov    %ecx,%eax
f01022e2:	89 f2                	mov    %esi,%edx
f01022e4:	83 c4 1c             	add    $0x1c,%esp
f01022e7:	5b                   	pop    %ebx
f01022e8:	5e                   	pop    %esi
f01022e9:	5f                   	pop    %edi
f01022ea:	5d                   	pop    %ebp
f01022eb:	c3                   	ret    
f01022ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01022f0:	8b 34 24             	mov    (%esp),%esi
f01022f3:	bf 20 00 00 00       	mov    $0x20,%edi
f01022f8:	89 e9                	mov    %ebp,%ecx
f01022fa:	29 ef                	sub    %ebp,%edi
f01022fc:	d3 e0                	shl    %cl,%eax
f01022fe:	89 f9                	mov    %edi,%ecx
f0102300:	89 f2                	mov    %esi,%edx
f0102302:	d3 ea                	shr    %cl,%edx
f0102304:	89 e9                	mov    %ebp,%ecx
f0102306:	09 c2                	or     %eax,%edx
f0102308:	89 d8                	mov    %ebx,%eax
f010230a:	89 14 24             	mov    %edx,(%esp)
f010230d:	89 f2                	mov    %esi,%edx
f010230f:	d3 e2                	shl    %cl,%edx
f0102311:	89 f9                	mov    %edi,%ecx
f0102313:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102317:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010231b:	d3 e8                	shr    %cl,%eax
f010231d:	89 e9                	mov    %ebp,%ecx
f010231f:	89 c6                	mov    %eax,%esi
f0102321:	d3 e3                	shl    %cl,%ebx
f0102323:	89 f9                	mov    %edi,%ecx
f0102325:	89 d0                	mov    %edx,%eax
f0102327:	d3 e8                	shr    %cl,%eax
f0102329:	89 e9                	mov    %ebp,%ecx
f010232b:	09 d8                	or     %ebx,%eax
f010232d:	89 d3                	mov    %edx,%ebx
f010232f:	89 f2                	mov    %esi,%edx
f0102331:	f7 34 24             	divl   (%esp)
f0102334:	89 d6                	mov    %edx,%esi
f0102336:	d3 e3                	shl    %cl,%ebx
f0102338:	f7 64 24 04          	mull   0x4(%esp)
f010233c:	39 d6                	cmp    %edx,%esi
f010233e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102342:	89 d1                	mov    %edx,%ecx
f0102344:	89 c3                	mov    %eax,%ebx
f0102346:	72 08                	jb     f0102350 <__umoddi3+0x110>
f0102348:	75 11                	jne    f010235b <__umoddi3+0x11b>
f010234a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010234e:	73 0b                	jae    f010235b <__umoddi3+0x11b>
f0102350:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102354:	1b 14 24             	sbb    (%esp),%edx
f0102357:	89 d1                	mov    %edx,%ecx
f0102359:	89 c3                	mov    %eax,%ebx
f010235b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010235f:	29 da                	sub    %ebx,%edx
f0102361:	19 ce                	sbb    %ecx,%esi
f0102363:	89 f9                	mov    %edi,%ecx
f0102365:	89 f0                	mov    %esi,%eax
f0102367:	d3 e0                	shl    %cl,%eax
f0102369:	89 e9                	mov    %ebp,%ecx
f010236b:	d3 ea                	shr    %cl,%edx
f010236d:	89 e9                	mov    %ebp,%ecx
f010236f:	d3 ee                	shr    %cl,%esi
f0102371:	09 d0                	or     %edx,%eax
f0102373:	89 f2                	mov    %esi,%edx
f0102375:	83 c4 1c             	add    $0x1c,%esp
f0102378:	5b                   	pop    %ebx
f0102379:	5e                   	pop    %esi
f010237a:	5f                   	pop    %edi
f010237b:	5d                   	pop    %ebp
f010237c:	c3                   	ret    
f010237d:	8d 76 00             	lea    0x0(%esi),%esi
f0102380:	29 f9                	sub    %edi,%ecx
f0102382:	19 d6                	sbb    %edx,%esi
f0102384:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102388:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010238c:	e9 18 ff ff ff       	jmp    f01022a9 <__umoddi3+0x69>
