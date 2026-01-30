@x Change 1: Add stdlib.h for malloc and exit, plus function prototypes
@<Global include files@>@;
@<Global declarations@>@;
@y
@<Global include files@>@;
#include <stdlib.h>
#include <string.h>
@<Global declarations@>@;

/* Function prototypes */
void read_tree(FILE *fp, struct tnode **rootptr);
void add_tree(struct tnode **rootptr, char *p);
void print_node(FILE *fp, char *indent_string, struct tnode *node);
@z

@x Change 2: Fix main function to use ANSI C prototype
@#
main(argc, argv)
     int argc;
     char **argv;
@y
@#
int main(int argc, char **argv)
@z

@x Change 3: Fix read_tree function to use ANSI C prototype
@c
read_tree (fp, rootptr)
   FILE *fp;
   struct tnode **rootptr;
@y
@c
void read_tree(FILE *fp, struct tnode **rootptr)
@z

@x Change 4: Fix add_tree function to use ANSI C prototype
@c
add_tree(rootptr, p)
     struct tnode **rootptr;
     char *p;
@y
@c
void add_tree(struct tnode **rootptr, char *p)
@z

@x Change 5: Remove old malloc declaration
@
@<Global decl...@>= char *malloc();
@y
@ We use |malloc| from |<stdlib.h>|, so no declaration is needed here.
@<Global decl...@>=
@z

@x Change 6: Fix print_node function to use ANSI C prototype
@c
print_node(fp, indent_string, node)
     FILE *fp;
     char *indent_string;
     struct tnode *node;
@y
@c
void print_node(FILE *fp, char *indent_string, struct tnode *node)
@z
