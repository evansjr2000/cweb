# Makefile for sunrise CWEB literate programming project
#
# Targets:
#   all      - Build everything (C code, executable, and PDF documentation)
#   code     - Extract C code from CWEB source
#   doc      - Generate PDF documentation
#   exe      - Compile the executable
#   install  - Install the executable into /usr/local/bin
#   commit   - Commit the CWEB source (sunrise.w) to git
#   clean    - Remove generated files
#   cleanall - Remove all generated files including PDF

PROG = sunrise
CWEB_SRC = $(PROG).w
C_SRC = $(PROG).c
TEX_SRC = $(PROG).tex
PDF_DOC = $(PROG).pdf
EXE = $(PROG)

# Docker image for CWEB tools
IMAGE_NAME = evansjr/cweb:latest
DOCKER_RUN = docker run --rm -v "$(PWD):/work" $(IMAGE_NAME)

# C compiler settings
CC = cc
CFLAGS = -O2 -Wall

# Installation directory
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin

# Commit message for `make commit` (override with: make commit MSG="...")
MSG = Update sunrise.w

.PHONY: all code doc exe install commit clean cleanall

all: code exe doc

# Extract C code from CWEB source using ctangle
code: $(C_SRC)

$(C_SRC): $(CWEB_SRC)
	$(DOCKER_RUN) -c "ctangle $(CWEB_SRC)"

# Generate TeX documentation using cweave, then compile to PDF
doc: $(PDF_DOC)

$(TEX_SRC): $(CWEB_SRC)
	$(DOCKER_RUN) -c "cweave $(CWEB_SRC)"

$(PDF_DOC): $(TEX_SRC)
	-rm -f $(PROG).xrf
	$(DOCKER_RUN) -c "pdftex $(TEX_SRC) && pdftex $(TEX_SRC)"

# Compile the C code into an executable
exe: $(EXE)

$(EXE): $(C_SRC)
	$(CC) $(CFLAGS) -o $(EXE) $(C_SRC) -lm

# Install the executable into $(BINDIR) (default /usr/local/bin)
install: $(EXE)
	mkdir -p $(BINDIR)
	install -m 755 $(EXE) $(BINDIR)/$(EXE)

# Commit the CWEB source to git (single source of truth)
commit:
	git add $(CWEB_SRC)
	git commit -m "$(MSG)"

clean:
	rm -f $(C_SRC) $(TEX_SRC) $(EXE)
	rm -f $(PROG).idx $(PROG).scn $(PROG).toc $(PROG).log

cleanall: clean
	rm -f $(PDF_DOC)
