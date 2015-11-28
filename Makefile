

debug:	dlib	
	@echo "Building test executable with debug information for GDB"
	gcc -ggdb -fpack-struct=1 -I. -L. test.c -lann -o dtest -lm 
	@echo



dlib:	
	@echo
	@echo "Compiling the ANN library"
	fasm libann.asm libann.o
	ar -cr libann.a libann.o 
	@echo
	
release:	lib
	@echo "Building the final executable with full optimization"
	gcc -g0 -O3 -fpack-struct=1 -I. -L. test.c -lann -o test -lm
	@echo



lib:	
	@echo
	@echo "Compiling the ANN library"
	fasm libann.asm libann.o
	ar -cr libann.a libann.o 
	@echo
	
clean:
	rm -vf libann.o
	rm -vf net.o
	rm -vf test
	rm -vf dtest
	rm -vf *.a

all:	debug release
