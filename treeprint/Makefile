# Makefile for treeprint
# CWEB literate program

CWEB_SH = $(HOME)/bin/cweb.sh
CC = gcc
CFLAGS = -std=c89 -Wall

.PHONY: all clean doc

all: treeprint

treeprint: treeprint.c
	$(CC) $(CFLAGS) -o treeprint treeprint.c

treeprint.c: treeprint.w treeprint.ch
	$(CWEB_SH) ctangle treeprint.w treeprint.ch

doc: treeprint.pdf

treeprint.tex: treeprint.w treeprint.ch
	$(CWEB_SH) cweave treeprint.w treeprint.ch

treeprint.pdf: treeprint.tex
	pdftex treeprint.tex

clean:
	rm -f treeprint treeprint.c treeprint.tex treeprint.pdf
	rm -f treeprint.idx treeprint.scn treeprint.toc treeprint.log
