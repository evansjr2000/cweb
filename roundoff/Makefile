# Makefile for roundoff CWEB program

PROG = roundoff
SRC = $(PROG).w
CFILE = $(PROG).c
TEXFILE = $(PROG).tex

CC = cc
CFLAGS = -O2

.PHONY: all binary doc clean

all: binary doc

binary: $(PROG)

$(CFILE): $(SRC)
	./cweb.sh ctangle $(SRC)

$(PROG): $(CFILE)
	$(CC) $(CFLAGS) -o $(PROG) $(CFILE)

doc: $(PROG).pdf

$(TEXFILE): $(SRC)
	./cweb.sh cweave $(SRC)

$(PROG).pdf: $(TEXFILE)
	pdftex $(TEXFILE)
	pdftex $(TEXFILE)

clean:
	rm -f $(CFILE) $(PROG) $(TEXFILE) $(PROG).pdf
	rm -f $(PROG).log $(PROG).toc $(PROG).idx $(PROG).scn $(PROG).aux
