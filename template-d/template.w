% CWEB Literate Programming Template
% Author: Your Name
% Date: January 2026

@* Introduction.
This is a CWEB literate programming template. CWEB combines \CEE/ code
with \TeX\ documentation, allowing you to write programs that are
meant to be read by humans.

The ``\.{@@*}'' marker begins a new major section (starred section),
which will appear in the table of contents.

@* Program Structure.
Our program follows the standard C structure with includes,
definitions, and a main function.

@c
@<Include files@>@;
@<Global definitions@>@;
@<Function prototypes@>@;
@<Main program@>@;
@<Helper functions@>@;

@ @<Include files@>=
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

@ @<Global definitions@>=
#define VERSION "1.0.0"
#define BUFFER_SIZE 1024

@ @<Function prototypes@>=
void print_greeting(const char *name);
int process_data(int value);

@* The Main Program.
The main function serves as the entry point. It demonstrates
basic program flow and calls our helper functions.

@<Main program@>=
int main(int argc, char *argv[])
{
    @<Initialize variables@>@;
    @<Process command line arguments@>@;
    @<Execute main logic@>@;
    return 0;
}

@ We declare local variables at the start of main.
@<Initialize variables@>=
    int result = 0;
    char buffer[BUFFER_SIZE];

@ Command line argument processing is straightforward.
@<Process command line arguments@>=
    if (argc > 1) {
        printf("Program: %s\n", argv[0]);
        printf("First argument: %s\n", argv[1]);
    }

@ The main logic of our program.
@<Execute main logic@>=
    print_greeting("World");
    result = process_data(42);
    printf("Result: %d\n", result);

@* Helper Functions.
These functions provide supporting functionality for the main program.

@ The |print_greeting| function outputs a friendly message.
@<Helper functions@>=
void print_greeting(const char *name)
{
    printf("Hello, %s!\n", name);
    printf("CWEB Template Version %s\n", VERSION);
}

@ The |process_data| function performs a simple calculation.
This is where you would implement your core algorithm.
@<Helper functions@>=
int process_data(int value)
{
    /* Perform some meaningful computation */
    return value * 2 + 1;
}

@* Index.
This section will automatically contain an index of all
identifiers used in the program when processed by CWEAVE.
