/* -------------------------------------------------------------------------------------------------

    MthToken - tokenize Ascii text using default or specified token table
    Copyright (C) 2016, Gunther Strube, gstrube@gmail.com

    MthToken is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by the Free Software Foundation;
    either version 2, or (at your option) any later version.
    MthToken is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU General Public License for more details.
    You should have received a copy of the GNU General Public License along with MthToken;
    see the file COPYING.  If not, write to the
    Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.



    ==============================================================================
    compile with
        gcc -o mthtoken mthtoken.c
    ==============================================================================



    ==============================================================================
    Tokens may be embedded in the help text or within the text for topic and command names.
    The first token has a code of $80 and subsequent tokens count up from here. Recursive
    tokens may contain tokens in their text. Tokens above the boundary level set by the
    'first recursive token' may contain tokens themselves, providing those tokens are below
    the boundary. The example below is in assembly format to improve clarity:

    .tok_base   defb $04                              ; recursive token boundary
                defb $05                              ; number of tokens
                defw tok0 - tok_base
                defw tok1 - tok_base
                defw tok2 - tok_base
                defw tok3 - tok_base
                defw tok4 - tok_base
                defw end - tok_base

    .tok0       defm "file"
    .tok1       defm " the "
    .tok2       defm "EPROM"
    .tok3       defb $01, 'T'                         ; Tiny text token
    .tok4       defm ' ', $80, "s "
    .end
    ==============================================================================

 -------------------------------------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#if MSDOS
#define OS_ID "MSDOS"
#define DIRSEP 0x5C         /* "\" */
#define ENVPATHSEP 0x3B     /* ";" */
#else
#define OS_ID "UNIX"
#define DIRSEP 0x2F         /* "/" */
#define ENVPATHSEP 0x3A     /* ":" */
#endif

typedef
struct token {
    int id;                         /* 0x80 - 0xFF */
    int len;                        /* length of token string */
    unsigned char *str;             /* pointer to token string */
} token_t;

typedef
struct tokentable {
    int recursivetokenboundary;
    int totaltokens;                /* total tokens in table */
    unsigned char *tokens;          /* the raw token table */
} tokentable_t;


/* variables */
char copyrightmsg[] = "MthToken V0.1";
int totalerrors = 0, errornumber;


typedef enum {
    Err_FileIO,                     /* 0,  "File open/read error" */
    Err_Syntax,                     /* 1,  "Syntax error" */
    Err_SymNotDefined,              /* 2,  "symbol not defined" */
    Err_Memory,                     /* 3,  "Not enough memory" */
    Err_IntegerRange,               /* 4,  "Integer out of range" */
    Err_ExprSyntax,                 /* 5,  "Syntax error in expression" */
    Err_ExprBracket,                /* 6,  "Right bracket missing" */
    Err_ExprOutOfRange,             /* 7,  "Out of range" */
    Err_SrcfileMissing,             /* 8,  "Source filename missing" */
    Err_IllegalOption,              /* 9,  "Illegal option" */
    Err_UnknownIdent,               /* 10, "Unknown identifier" */
    Err_IllegalIdent,               /* 11, "Illegal label/identifier" */
    Err_NoTokenTable,               /* 12, "Token table structure not recognized" */
    Err_Status,                     /* 13, "errors occurred during processing" */
    Err_TokenNotFound,              /* 14, "Token ID not available" */
    Err_SymDeclLocal,               /* 18, "symbol already declared local" */
    Err_SymDeclGlobal,              /* 19, "symbol already declared global" */
    Err_SymDeclExtern,              /* 20, "symbol already declared external" */
    Err_NoArguments,                /* 21, "No command line arguments" */
    Err_IllegalSrcfile,             /* 22, "Illegal source filename" */
    Err_SymDeclGlobalModule,        /* 23, "symbol declared global in another module" */
    Err_SymRedeclaration,           /* 24, "Re-declaration not allowed" */
    Err_SymResvName,                /* 28, "Reserved name" */
    Err_EnvVariable,                /* 31, "Environment variable not defined" */
    Err_IncludeFile,                /* 32, "Cannot include file recursively" */
    Err_ExprTooBig,                 /* 34, "Expression > 255 characters" */
    Err_totalMessages
} error_t;

char *errmsg[] = {
    "File open/read error",
    "Syntax error",
    "symbol not defined",
    "Not enough memory",
    "Integer out of range",
    "Syntax error in expression",
    "Right bracket missing",
    "Expression out of range",
    "Source filename missing",
    "Illegal option",
    "Unknown identifier",
    "Illegal identifier",
    "Token table structure not recognized",
    "errors occurred during processing",
    "Token ID not available",
    "Symbol already declared local",
    "Symbol already declared global",
    "Symbol already declared external",
    "No command line arguments",
    "Illegal source filename",
    "Symbol declared global in another module",
    "Re-declaration not allowed",
    "Reserved name",
    "Environment variable not defined",
    "Cannot include file recursively",
    "Expression > 255 characters",
};


/* ------------------------------------------------------------------------------------------ */
void
ReportIOError (char *filename)
{
    fprintf (stderr,"File '%s' couldn't be opened or created\n", filename);

    ++totalerrors;
}


/* ------------------------------------------------------------------------------------------ */
void
ReportError (char *filename, error_t errnum)
{
    char  errstr[256], errflnmstr[128];
    char  *errline = NULL;

    errornumber = errnum;      /* set the global error variable for general error trapping */

    errflnmstr[0] = '\0';
    errstr[0] = '\0';

    if (filename != NULL) {
        sprintf (errflnmstr,"In file '%s', ", filename);
    }

    strcpy(errstr, errflnmstr);
    strcat(errstr, errmsg[errnum]);

    switch(errnum) {
        case Err_Status:
            fprintf (stderr, "%d %s\n", totalerrors, errmsg[errnum]);
            break;

        default:
            /* copy the error to stderr for immediate view */
            fprintf (stderr, "%s\n", errstr);
    }

    ++totalerrors;
}


/* ------------------------------------------------------------------------------------------
    char *AdjustPlatformFilename(char *filename)

    Adjust filename to use the platform specific directory specifier, which is defined as
    DIRSEP. Adjusting the filename at runtime enables the freedom to not worry
    about paths in filenames when porting Z80 projects to Windows or Unix platforms.

    Example: if a filename contains a '/' (Unix directory separator) it will be converted
    to a '\' if mpm currently is compiling on Windows (or Dos).

    Returns:
    same pointer as argument (beginning of filename)
   ------------------------------------------------------------------------------------------ */
char *
AdjustPlatformFilename(char *filename)
{
    char *flnmptr = filename;

    if (filename == NULL) {
        return NULL;
    }

    while(*flnmptr != '\0') {
        if (*flnmptr == '/' || *flnmptr == '\\') {
            *flnmptr = DIRSEP;
        }

        flnmptr++;
    }

    return filename;
}


/* ------------------------------------------------------------------------------------------
    unsigned char *AllocBuffer (size_t size)

    Allocate dynamic memory on heap of <size> bytes

    Returns:
    pointer to allcoated memory, or NULL (no space)
   ------------------------------------------------------------------------------------------ */
unsigned char *
AllocBuffer (size_t size)
{
    return (unsigned char *) malloc (size);
}


/* ------------------------------------------------------------------------------------------ */
tokentable_t *
AllocTokenTable(void)
{
    return (tokentable_t *) malloc (sizeof(tokentable_t));
}


/* ------------------------------------------------------------------------------------------
    token_t *AllocRawToken(tokentable_t *tkt, int tkid)

    Grab an allocated copy of the raw token from the table and return a pointer to it
    NULL is returned if no memory on heap
   ------------------------------------------------------------------------------------------ */
token_t *
AllocRawToken(tokentable_t *tkt, int tkid)
{
    token_t *rawtoken = (token_t *) malloc (sizeof(token_t));
    unsigned char *tokenoffsetptr = tkt->tokens+2+(tkid*2); /* point to token ID offset */
    unsigned char *nexttokenoffsetptr = tokenoffsetptr+2;
    int tokenoffset = tokenoffsetptr[0]+tokenoffsetptr[1]*256;
    int nexttokenoffset = nexttokenoffsetptr[0]+nexttokenoffsetptr[1]*256;

    if (rawtoken != NULL) {
        rawtoken->id = 0x80 | tkid;
        rawtoken->len = nexttokenoffset-tokenoffset;
        rawtoken->str = AllocBuffer (rawtoken->len);
        if (rawtoken->str != NULL) {
            memcpy(rawtoken->str, tkt->tokens + tokenoffset, rawtoken->len);
        } else {
            free(rawtoken);
            rawtoken = NULL;
        }
    }

    if (rawtoken == NULL) {
        ReportError (NULL, Err_Memory);
    }

    return rawtoken;
}


/* ------------------------------------------------------------------------------------------ */
token_t *
AllocExpandedToken(tokentable_t *tkt, int tkid)
{
    int i;
    token_t *exptoken = AllocRawToken(tkt, (tkid & 0x7f)); /* internal token ID is 0 - 127 */

    /* TO DO: scan raw token string for recursive tokens and expand them inline, before returning */
    if (exptoken != NULL) {
        for (i=0; i<exptoken->len; i++) {
            if (exptoken->str[i] >= 0x80) {
                /* this token string contains a recursive token ID */
            }
        }

    }

    return exptoken;
}


/* ------------------------------------------------------------------------------------------
    token_t *AllocTokenInstance(tokentable_t *tkt, int tkid)

    Return an instance of a token, fully expanded. NULL is returned if illegal ID or no memory
   ------------------------------------------------------------------------------------------ */
token_t *
AllocTokenInstance(tokentable_t *tkt, int tkid)
{
    tkid &= 0x7f; /* internal token ID is 0 - 127 */
    token_t *token = NULL;;

    if (tkid > (tkt->totaltokens-1)) {
        ReportError (NULL, Err_TokenNotFound);
    } else {
        token = AllocExpandedToken(tkt, tkid);
    }

    return token;
}


/* ------------------------------------------------------------------------------------------ */
void
ReleaseTokenTable(tokentable_t *tkt)
{
    if (tkt != NULL) {
        if ( tkt->tokens ) {
            free(tkt->tokens);
        }

        free(tkt);
    }
}


/* ------------------------------------------------------------------------------------------ */
size_t
LengthOfFile(char *filename)
{
    FILE *binfile;
    size_t filesize = 0;

    if ((binfile = fopen (AdjustPlatformFilename(filename), "rb")) == NULL) {
        ReportIOError (filename);
    } else {
        fseek(binfile, 0L, SEEK_END); /* file pointer to end of file */
        filesize = ftell(binfile);
        fclose (binfile);
    }

    return filesize;
}


/* ------------------------------------------------------------------------------------------
    unsigned char *LoadFile (char *tokenfilename)

    Load (binary) file into allocated heap memory

    Returns:
    pointer to allocated memory, or NULL (if no space in system or file I/O)
   ------------------------------------------------------------------------------------------ */
unsigned char *
LoadFile (char *filename)
{
    FILE *binfile;
    size_t filesize = LengthOfFile(filename);
    unsigned char *bufptr = NULL;

    if (filesize > 0) {
        binfile = fopen (AdjustPlatformFilename(filename), "rb");
        bufptr = AllocBuffer(filesize);
        if (bufptr == NULL) {
            ReportError (NULL, Err_Memory);
        } else {
            if (fread (bufptr, sizeof (char), filesize, binfile) != filesize) {    /* read binary code */
                ReportError (filename, Err_FileIO);
                free(bufptr);
                bufptr = NULL;
            }
        }

        fclose (binfile);
    }

    return bufptr;
}


/* ------------------------------------------------------------------------------------------
    token_t **LoadTokenTable (char *filename)

    Load the specified token table binary into memory, validated.

    Returns pointer to the loaded token table.
   ------------------------------------------------------------------------------------------ */
tokentable_t *
LoadTokenTable (char *filename)
{
    size_t tktsize = LengthOfFile(filename);
    unsigned char *tokentablefile = NULL, *tokenptr, *nexttokenptr;
    token_t *newtoken;
    tokentable_t *tokentable = NULL;

    int i,tokenidx = 0, totaltokens, recursivetokenboundary, tokenoffset, nexttokenoffset;
    int sizeoftokenstr;

    if (tktsize < 5 || tktsize > 16384) {
        /* no offsets available, or too big (bank boundary is crossed) */
        ReportError(filename, Err_NoTokenTable);
        return NULL;
    }

    tokentablefile = LoadFile (filename);
    if ( tokentablefile == NULL ) {
        /* problems loading the complete binary, or file not found */
        return NULL;
    }

    recursivetokenboundary = tokentablefile[0];
    totaltokens = tokentablefile[1];
    if ( recursivetokenboundary > 128 || totaltokens > 128) {
        /* recursive token number and total tokens cannot be > 128 */
        ReportError(filename, Err_NoTokenTable);
        free(tokentablefile);
        return NULL;
    }

    /* iterate the token table, to validate all offsets */
    tokenptr = tokentablefile+2; /* point at first token offset */
    nexttokenptr = tokenptr+2;   /* point to the following token offset */

    for (i=0; i<totaltokens; i++) {
        tokenoffset = tokenptr[0] + tokenptr[1]*256;
        nexttokenoffset = nexttokenptr[0] + nexttokenptr[1]*256;
        if ( (tokenoffset > tktsize) || (nexttokenoffset > tktsize) ) {
            /*  one of the offsets points beyond the end of the token table binary block size! */
            ReportError(filename, Err_NoTokenTable);
            free(tokentablefile);
            return NULL;
        }

        tokenptr += 2;
        nexttokenptr += 2;
    }

    tokentable = AllocTokenTable();
    if ( tokentable == NULL ) {
        ReportError(filename, Err_NoTokenTable);
        free(tokentablefile);
    } else {
        tokentable->recursivetokenboundary = recursivetokenboundary;
        tokentable->totaltokens = totaltokens;
        tokentable->tokens = tokentablefile;
    }

    return tokentable;
}


/* ------------------------------------------------------------------------------------------ */
void
ListExpandedTokens(tokentable_t *tkt)
{
    int i,l;
    token_t *token;

    for (i=0; i < tkt->totaltokens; i++) {
        token = AllocTokenInstance(tkt, i);
        if (token != NULL) {
            fprintf(stdout,"Token $%02X (Length %d) = ", token->id, token->len);
            for (l=0; l<token->len; l++) {
                if (token->str[l] < 32 || token->str[l] > 127) {
                    fprintf(stdout,"$%02X", token->str[l]);
                } else {
                    fputc(token->str[l],stdout);
                }
            }
            fputc('\n',stdout);
            free(token); /* expanded token can now be discarded */
        } else {
            return;
        }
    }
}


/* ------------------------------------------------------------------------------------------ */
void
Prompt(void)
{
    puts(copyrightmsg);
    puts("mthtoken -tkt tokentablefile [<textfile>]\n");
    puts("Tokenize specified textfile, using default 'systokens.bin' token table,");
    puts("or using specified tokens using -tkt option.");
    puts("If <textfile> is omitted, expanded tokens are listed to stdout.");
    puts("Tokenized text is sent to stdout in assembler DEFM format.");
    puts("Redirect to file using:");
    puts("  mthtoken textfile > output.asm.");
}


/* ------------------------------------------------------------------------------------------ */
bool
ProcessCommandline(int argc, char *argv[])
{
    int argidx = 1;
    tokentable_t *tokentable = NULL;

    /* Get command line arguments, if any... */
    if (argc == 1) {
        puts(copyrightmsg);
        puts("Try -h for more information.");
    } else if ((argc == 2 && strcmp(argv[1],"-h") == 0)) {
        Prompt();
    } else {
        /* command line is specified, parse it.. */

        if (strcmp(argv[argidx],"-tkt") == 0) {
            /* load specified token table file */
            argidx++;
            if (argidx < argc) {
                tokentable = LoadTokenTable(argv[argidx]);
                if (tokentable == NULL) {
                    return false;
                } else {
                    fprintf(stderr,"Specified '%s' table were loaded\n", argv[argidx]);
                }
                argidx++;
            } else {
                fprintf (stderr, "Token table filename not specified\n");
                return false;
            }
        }

        if (tokentable == NULL) {
            /* explicit token table was not specified, try to load default "systokens.bin" token table file */
            tokentable = LoadTokenTable("systokens.bin");
            if (tokentable == NULL) {
                return false;
            } else {
                fprintf(stderr,"Default 'systokens.bin' table were loaded\n");
            }
        }

        if (argidx < argc) {
            /* text file specified, tokenized it... */
            fprintf(stderr,"Tokenize '%s' text file...\n", argv[argidx]);
        } else {
            /* just output the token table to stdout */
            puts("Contents of Token Table:");
            ListExpandedTokens(tokentable);
        }

        ReleaseTokenTable(tokentable);
    }

    return true;
}


/* ------------------------------------------------------------------------------------------
    int main(int argc, char *argv[])

    MthToken command line entry

    Returns:
        0, text file tokenized
        1, an error occurred during tokenization
   ------------------------------------------------------------------------------------------ */
int
main(int argc, char *argv[])
{
    if (ProcessCommandline(argc, argv) == true) {
        return 0; // mission completed..
    }
    else
        return 1; // signal error to command line
}
