# CWEB Makefile
# Usage:
#   make program   - Generate C code and compile
#   make doc       - Generate TeX documentation
#   make all       - Build both program and documentation
#   make clean     - Remove generated files
#   make push      - Commit and push changes to GitHub
#   make pull      - Pull latest changes from GitHub

PROG = template
CFLAGS = -Wall -Wextra -O2

.PHONY: all program doc clean push pull

all: program doc

# Generate C code from CWEB source and compile
program: $(PROG)

$(PROG): $(PROG).c
	$(CC) $(CFLAGS) -o $@ $<

$(PROG).c: $(PROG).w
	cweb.sh ctangle $(PROG).w

# Generate TeX documentation
doc: $(PROG).pdf

$(PROG).tex: $(PROG).w
	cweb.sh cweave $(PROG).w

$(PROG).pdf: $(PROG).tex
	pdftex $(PROG).tex

# Clean up generated files
clean:
	rm -f $(PROG) $(PROG).c $(PROG).tex $(PROG).pdf
	rm -f $(PROG).idx $(PROG).log $(PROG).scn $(PROG).toc

# Git operations
push:
	git add -A
	git commit -m "Update CWEB files"
	git push

pull:
	git pull
