stage1: stage1.asm
	nasm stage1.asm

run:    stage1
	bochs -f bochs.cfg

dist:   stage1
	mkdir demo512 || true
	cp stage1.asm bochs.cfg Makefile stage1 demo512
	tar czf demo512.tgz demo512
	 
 
