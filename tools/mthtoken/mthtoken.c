/* -------------------------------------------------------------------------------------------------

    MthToken - Tokenize Z80 Assembler DEFM Ascii text using default or specified token table
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
    MthToken is developed in Ansi C. Compile with GCC or similar:
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

#include <errno.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>



/* ------------------------------------------------------------------------------------------
    Constant and data structure declarations
   ------------------------------------------------------------------------------------------ */

#if MSDOS
#define OS_ID "MSDOS"
#define DIRSEP 0x5C         /* "\" */
#define ENVPATHSEP 0x3B     /* ";" */
#else
#define OS_ID "UNIX"
#define DIRSEP 0x2F         /* "/" */
#define ENVPATHSEP 0x3A     /* ":" */
#endif

#define MAX_NAME_SIZE 254
#define MAX_LINE_BUFFER_SIZE 4096


struct sourcefile;

typedef
struct usedfile     {
    struct usedfile    *nextusedfile;
    struct sourcefile  *ownedsourcefile;
} usedsrcfile_t;

typedef
struct sourcefile   {
    struct sourcefile  *prevsourcefile;     /* pointer to previously parsed source file */
    struct sourcefile  *newsourcefile;      /* pointer to new source file to be parsed */
    usedsrcfile_t      *usedsourcefile;     /* list of pointers to used files owned by this file */
    unsigned char      *lineptr;            /* pointer to beginning of current line being parsed */
    int                lineno;              /* current line number of current source file */
    char               *fname;              /* pointer to file name of current source file */
    FILE               *stream;             /* stream handle of opened file (optional) */
    long               filesize;            /* size of file in bytes */
    unsigned char      *filedata;           /* pointer to complete copy of file content */
    unsigned char      *memfileptr;         /* pointer to current character in memory file */
    bool               eol;                 /* indicate if End Of Line has been reached */
    bool               eof;                 /* indicate if End Of File has been reached */
    bool               includedfile;        /* if this is an INCLUDE'd file or not */
} sourcefile_t;

typedef
struct defm {
    int len;                                /* length of DEFM string */
    unsigned char *str;                     /* pointer to DEFM string */
    struct defm   *nextline;                /* pointer to next line */
} defm_t;

typedef
struct sourcelines     {
    defm_t              *firstline;         /* header of list of DEFM lines */
    defm_t              *currentline;       /* point at current DEFM line */
} sourcelines_t;

typedef
struct token {
    int id;                                 /* 0x80 - 0xFF */
    int len;                                /* length of token string */
    unsigned char *str;                     /* pointer to token string */
} token_t;

typedef
struct tokentable {
    int recursivetokenboundary;
    int totaltokens;                        /* total tokens in table */
    unsigned char *tokens;                  /* the raw token table */
} tokentable_t;

typedef enum {
    Err_FileIO,                             /* 0,  "File open/read error" */
    Err_Syntax,                             /* 1,  "Syntax error" */
    Err_SymNotDefined,                      /* 2,  "symbol not defined" */
    Err_Memory,                             /* 3,  "Not enough memory" */
    Err_IntegerRange,                       /* 4,  "Integer out of range" */
    Err_ConstSyntax,                        /* 5,  "Syntax error in constant" */
    Err_ExprBracket,                        /* 6,  "Right bracket missing" */
    Err_ConstOutOfRange,                    /* 7,  "Constant Out of range" */
    Err_SrcfileMissing,                     /* 8,  "Source filename missing" */
    Err_IllegalOption,                      /* 9,  "Illegal option" */
    Err_UnknownIdent,                       /* 10, "Unknown identifier" */
    Err_IllegalIdent,                       /* 11, "Illegal label/identifier" */
    Err_NoTokenTable,                       /* 12, "Token table structure not recognized" */
    Err_Status,                             /* 13, "errors occurred during processing" */
    Err_TokenNotFound,                      /* 14, "Token ID not available" */
    Err_SymDeclLocal,                       /* 18, "symbol already declared local" */
    Err_SymDeclGlobal,                      /* 19, "symbol already declared global" */
    Err_SymDeclExtern,                      /* 20, "symbol already declared external" */
    Err_NoArguments,                        /* 21, "No command line arguments" */
    Err_IllegalSrcfile,                     /* 22, "Illegal source filename" */
    Err_SymDeclGlobalModule,                /* 23, "symbol declared global in another module" */
    Err_SymRedeclaration,                   /* 24, "Re-declaration not allowed" */
    Err_SymResvName,                        /* 28, "Reserved name" */
    Err_EnvVariable,                        /* 31, "Environment variable not defined" */
    Err_IncludeFile,                        /* 32, "Cannot include file recursively" */
    Err_ExprTooBig,                         /* 34, "Expression > 255 characters" */
    Err_totalMessages
} error_t;

enum symbols {
    space, bin_and, dquote, squote, semicolon, comma, fullstop, strconq = fullstop, lparen, lcurly, lexpr, backslash,
    rexpr, rcurly, rparen, plus, minus, multiply, divi, mod, bin_xor, assign, bin_or, bin_nor, colon = bin_nor,
    bin_not, less, greater, log_not, cnstexpr, newline, power, lshift, rshift,
    lessequal, greatequal, notequal, name, number, decmconst, hexconst, binconst, charconst, registerid,
    negated, mod256, div256, nil, ifstatm, elsestatm, endifstatm, enddefstatm, colonlabel, asmfnname
};

enum symbols sym, ssym[] = {
    space, bin_and, dquote, squote, semicolon, comma, fullstop,
    lparen, lcurly, lexpr, backslash, rexpr, rcurly, rparen, plus, minus, multiply, divi, mod, bin_xor,
    assign, bin_or, bin_nor, bin_not,less, greater, log_not, cnstexpr
};

const char copyrightmsg[] = "MthToken V0.3";
const char separators[] = " &\"\';,.({[\\]})+-*/%^=|:~<>!#";

/* Global text buffers and data structures, allocated by AllocateTextFileStructures() during startup of MthToken */
char *ident = NULL;
unsigned char *line = NULL;
unsigned char *codeptr = NULL;
sourcelines_t *sourcelines = NULL;

int totalerrors = 0, errornumber;
bool cstyle_comment = false;

char *errmsg[] = {
    "File open/read error",
    "Syntax error",
    "symbol not defined",
    "Not enough memory",
    "Integer out of range",
    "Syntax error in constant",
    "Right bracket missing",
    "Constant out of range",
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
ReportError (char *filename, int lineno, error_t errnum)
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

    if (lineno > 0) {
        sprintf (errflnmstr,"at line %d, ", lineno);
        strcat(errstr, errflnmstr);
    }

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


/* ------------------------------------------------------------------------------------------ */
sourcefile_t *
AllocFile (void)
{
    return (sourcefile_t *) malloc (sizeof (sourcefile_t));
}


/* ------------------------------------------------------------------------------------------ */
void
ReleaseToken(token_t *tk)
{
    if (tk != NULL) {
        if ( tk->str != NULL) {
            free(tk->str);
        }

        free(tk);
    }
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
void
ReleaseSourceLine (defm_t *srcline)
{
    if (srcline == NULL) {
        return;
    } else {
        if (srcline->str != NULL) {
            free (srcline->str);
        }

        free (srcline);
    }
}


/* ------------------------------------------------------------------------------------------ */
void
ReleaseSourceLines (sourcelines_t *srclines)
{
    defm_t *tmpline, *curline;

    curline = srclines->firstline;
    while (curline != NULL) {
        tmpline = curline->nextline;
        ReleaseSourceLine (curline);
        curline = tmpline;
    }

    free (srclines);
}


/* ------------------------------------------------------------------------------------------ */
sourcelines_t *
AllocSourceLineHdr (void)
{
    return (sourcelines_t *) malloc (sizeof (sourcelines_t));
}


/* ------------------------------------------------------------------------------------------ */
defm_t *
AllocSourceLine (void)
{
    return (defm_t *) malloc (sizeof (defm_t));
}


/* ------------------------------------------------------------------------------------------
    void AddSourceLine(defm_t *srcline)

    Add (append) a source line to the linked list of source code lines. Adjust
    the pointer to the first node and current (end of list) when necessary.

    The linked list contains all found DEFM entries in parsed source code file
   ------------------------------------------------------------------------------------------ */
void
AddSourceLine(defm_t *srcline)
{
    if (sourcelines->firstline == NULL) {
        sourcelines->firstline = srcline;
        sourcelines->currentline = srcline;              /* header points at first source line */
    } else {
        sourcelines->currentline->nextline = srcline;    /* Current node points to new source line node */
        sourcelines->currentline = srcline;              /* Pointer to current source line node updated */
    }
}


/* ------------------------------------------------------------------------------------------
    defm_t *srcline CopySourceLine(unsigned char *linebuf, int length)

    Copy the current parsed DEFM source line from the buffer to a dynamically allocated line.
    Returns NULL if heap memory allocation failed.
   ------------------------------------------------------------------------------------------ */
defm_t *
CopySourceLine(unsigned char *linebuf, int length)
{
    defm_t *srcline = AllocSourceLine();

    if (srcline != NULL) {
        srcline->len = length;
        srcline->str = AllocBuffer(length);
        srcline->nextline = NULL;

        if (srcline->str != NULL) {
            memcpy(srcline->str, linebuf, length);
        } else {
            ReportError (NULL, 0, Err_Memory);
            ReleaseSourceLine(srcline);
            srcline = NULL;
        }
    }

    return srcline;
}


/* ---------------------------------------------------------------------------
   void FreeTextFileStructures()

   Release previously allocated dynamic memory for source file structures
   --------------------------------------------------------------------------- */
void FreeTextFileStructures()
{
    if ( ident != NULL ) {
        free(ident);
        ident = NULL;
    }

    if ( line != NULL ) {
        free(line);
        line = NULL;
    }

    if (sourcelines != NULL) {
        ReleaseSourceLines(sourcelines);
        sourcelines = NULL;
    }
}


/* ---------------------------------------------------------------------------
   int AllocateTextFileStructures()

   Allocate dynamic memory for line, identifier buffers and source file structures.

   Return 1 if allocated, or 0 if no room in system
   --------------------------------------------------------------------------- */
int AllocateTextFileStructures()
{
    if ( (ident = (char *) AllocBuffer(MAX_NAME_SIZE+1)) == NULL ) {
        ReportError (NULL, 0, Err_Memory);
        return 0;
    }

    if ( (line = AllocBuffer(MAX_LINE_BUFFER_SIZE+1)) == NULL ) {
        ReportError (NULL, 0, Err_Memory);
        FreeTextFileStructures();
        return 0;
    }

    if ((sourcelines = AllocSourceLineHdr()) != NULL) {
        sourcelines->firstline = NULL;
        sourcelines->currentline = NULL;
    } else {
        ReportError (NULL, 0, Err_Memory);
        FreeTextFileStructures();
        return 0;
    }

    return 1;
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
            ReportError (NULL, 0, Err_Memory);
        } else {
            if (fread (bufptr, sizeof (char), filesize, binfile) != filesize) {    /* read binary code */
                ReportError (filename, 0, Err_FileIO);
                free(bufptr);
                bufptr = NULL;
            }
        }

        fclose (binfile);
    }

    return bufptr;
}


/* ------------------------------------------------------------------------------------------
    void ReleaseFileData (sourcefile_t *srcfile)

        Release previously allocated file data ressource and reset variables to indicate
        that no file data is cached.

        srcfile->filedata = NULL
        srcfile->memfileptr = NULL
        srcfile->filesize = 0
   ------------------------------------------------------------------------------------------ */
void
ReleaseFileData (sourcefile_t *srcfile)
{
    if (srcfile != NULL) {
        srcfile->filesize = 0;
        srcfile->eof = false;

        if ( (srcfile->filedata != NULL) && (srcfile->includedfile == false) ) {
            /* this memory file is not part of Include File Cache, so release ressource directly */
            free (srcfile->filedata);

            srcfile->filedata = NULL;
            srcfile->memfileptr = NULL;
        }
    }
}


/* ------------------------------------------------------------------------------------------ */
void ReleaseFile (sourcefile_t *srcfile);

void
ReleaseOwnedFile (usedsrcfile_t *ownedfile)
{
    /* Release first other files called by this file */
    if (ownedfile->nextusedfile != NULL) {
        ReleaseOwnedFile (ownedfile->nextusedfile);
    }

    /* Release first file owned by this file */
    if (ownedfile->ownedsourcefile != NULL) {
        ReleaseFile (ownedfile->ownedsourcefile);
    }

    free (ownedfile);             /* Then release this owned file */
}


/* ------------------------------------------------------------------------------------------
    void ReleaseFile (sourcefile_t *srcfile)

    Release all previously allocated ressources of file.
   ------------------------------------------------------------------------------------------ */
void
ReleaseFile (sourcefile_t *srcfile)
{
    if (srcfile != NULL) {
        if (srcfile->usedsourcefile != NULL) {
            ReleaseOwnedFile (srcfile->usedsourcefile);
        }

        if (srcfile->stream != NULL) {
            fclose(srcfile->stream);    /* In case a file wasn't closed in a abort situation */
        }

        ReleaseFileData(srcfile);

        if (srcfile->fname != NULL) {
            free (srcfile->fname);      /* Release allocated area for filename */
        }

        free (srcfile);                 /* Release file information record for this file */
    }
}


/* ------------------------------------------------------------------------------------------
    unsigned char *CacheFileData (sourcefile_t *srcfile, FILE *fd, size_t datasize)

        Load the data of current file pointer of opened file stream <fd> of <datasize> into
        specified source file <srcfile> as allocated ressource into srcfile->filedata.

        srcfile->filedata is set to point to beginning of loaded ressource.
        srcfile->memfileptr = srcfile->filedata
        srcfile->filesize = <datasize> (used for EOF management)

    Returns:
        NULL if file was not found or contents could not be loaded (I/O error)
        pointer to start of file data, if file contents was successfully loaded into buffer
   ------------------------------------------------------------------------------------------ */
unsigned char *
CacheFileData (sourcefile_t *srcfile, FILE *fd, size_t datasize)
{
    unsigned char *fdbuffer = NULL;

    if (srcfile == NULL) {
        /* Nothing to do here... */
        return NULL;
    }

    if (fd == NULL || srcfile->filedata != NULL) {
        /* report error if file couldnt be opened or data has already been loaded */
        ReportIOError (srcfile->fname);
        return NULL;
    }

    if (datasize == 0) {
        srcfile->filesize = 0;
        srcfile->filedata = NULL;
        srcfile->memfileptr = NULL;
        srcfile->eof = false;
    } else {
        fdbuffer = (unsigned char *) calloc (datasize + 1, sizeof (char));
        if (fdbuffer == NULL) {
            ReportError (srcfile->fname, 0, Err_Memory);
        } else {
            if (fread (fdbuffer, sizeof (char), datasize, fd) != datasize) {    /* read file data into buffer */
                ReportError (srcfile->fname, 0, Err_FileIO);
                free (fdbuffer);
                fdbuffer = NULL;
            } else {
                srcfile->filesize = (long) datasize;
                srcfile->filedata = fdbuffer;
                srcfile->memfileptr = fdbuffer;
                srcfile->eof = false;
            }
        }
    }

    return fdbuffer;
}


/* ------------------------------------------------------------------------------------------
    unsigned char *CacheFile (sourcefile_t *srcfile, FILE *fd)

        Read the contents of specified source file <srcfile> into memory.

        srcfile->filedata is set to point to beginning of loaded ressource.
        srcfile->memfileptr = srcfile->filedata
        srcfile->filesize = size of file (used for EOF management)

    Returns:
        NULL if file was not found or contents could not be loaded (I/O error)
        pointer to start of file data, if file contents was successfully loaded into buffer
   ------------------------------------------------------------------------------------------ */
unsigned char *
CacheFile (sourcefile_t *srcfile, FILE *fd)
{
    size_t filesize;

    if (srcfile == NULL) {
        /* Nothing to do here... */
        return NULL;
    }

    if (fd == NULL || srcfile->filedata != NULL) {
        /* report error if file couldnt be opened or data has already been loaded */
        ReportIOError (srcfile->fname);
        return NULL;
    }

    fseek(fd, 0L, SEEK_END); /* file pointer to end of file */
    filesize = ftell(fd);
    fseek(fd, 0L, SEEK_SET); /* file pointer back to start of file */

    return CacheFileData (srcfile, fd, filesize);
}


sourcefile_t *
Setfile (sourcefile_t *curfile,    /* pointer to record of current source file */
         sourcefile_t *nfile,      /* pointer to record of new source file */
         char *filename)           /* pointer to filename string */
{
    if (filename != NULL) {
        if ((nfile->fname = (char *) AllocBuffer (strlen (filename) + 1)) == NULL) {
            ReportError (NULL, 0, Err_Memory);
            return nfile;
        }

        nfile->fname = strcpy (nfile->fname, filename);
    } else {
        nfile->fname = NULL;
    }

    nfile->prevsourcefile = curfile;
    nfile->newsourcefile = NULL;
    nfile->usedsourcefile = NULL;
    nfile->lineptr = NULL;
    nfile->lineno = 0;              /* Reset to 0 as line counter during parsing */
    nfile->stream = NULL;
    nfile->filesize = 0;
    nfile->eol = false;
    nfile->eof = false;
    nfile->includedfile = false;
    nfile->filedata = NULL;

    return nfile;
}


sourcefile_t *
Newfile (sourcefile_t *curfile, char *fname)
{
    sourcefile_t *nfile;

    if (fname == NULL) {
        /* Don't do anything ... */
        return NULL;
    }

    if (curfile == NULL) {
        /* file record has not yet been created */
        if ((curfile = AllocFile ()) == NULL) {
            ReportError (NULL, 0, Err_Memory);
            return NULL;
        } else {
            return Setfile (NULL, curfile, fname);
        }
    } else if ((nfile = AllocFile ()) == NULL) {
        ReportError (NULL, 0, Err_Memory);
        return curfile;
    } else {
        return Setfile (curfile, nfile, fname);
    }
}


/* ----------------------------------------------------------------
    int MfTell(sourcefile_t *file)

    returns
        The current file pointer of memory file
   ---------------------------------------------------------------- */
unsigned char *
MfTell(sourcefile_t *file)
{
    if (file == NULL) {
        /* file not specified! */
        return NULL;
    } else {
        if (file->filedata == NULL) {
            return NULL;
        } else {
            return file->memfileptr;
        }
    }
}


/* ----------------------------------------------------------------
    int MfGetc(sourcefile_t *file)

        Reads the character from current memory file pointer
        (auto-increased) and returns it as an unsigned char cast
        to an int, or EOF on end of file.
   ---------------------------------------------------------------- */
int
MfGetc(sourcefile_t *file)
{
    int memchar;
    long boundsize = file->memfileptr - file->filedata;

    if (file == NULL) {
        /* file not specified! */
        return EOF;
    } else {
        if (file->filedata == NULL || file->eof == true) {
            return EOF;
        } else {
            if ( (boundsize >= file->filesize) || (boundsize < 0) ) {
                /* memory pointer protection: ensure bounds-check before accessing memory... */
                file->eof = true;
                return EOF;
            } else {
                memchar = *file->memfileptr++;

                if ( (++boundsize) >= file->filesize) {
                    /* signal EOF - last character was just returned */
                    file->eof = true;
                }
            }
        }
    }

    return memchar;
}


/* ----------------------------------------------------------------
    void MfUngetc(sourcefile_t *file)

        "Push back" character in memory file; simply step-back
        the memory file pointer one character.

        If character is successfully pushed-back, the end-of-file
        indicator for the memory file stream is cleared.
        The file-position indicator of <file> is also decremented.
   ---------------------------------------------------------------- */
void
MfUngetc(sourcefile_t *file)
{
    if (file != NULL) {
        if (file->filedata != NULL) {
            if (file->memfileptr > file->filedata) {
                /* decrease character file pointer in memory file */
                file->memfileptr--;
                file->eof = false;
            }
        }
    }
}


/* ----------------------------------------------------------------
    int MfEof(sourcefile_t *file)

    returns
        End of File status (EOF, otherwise 0) of memory file
   ---------------------------------------------------------------- */
int
MfEof(sourcefile_t *file)
{
    if (file == NULL) {
        /* file not specified! */
        return EOF;
    } else {
        if (file->filedata == NULL || file->eof == true) {
            return EOF;
        } else {
            return 0;
        }
    }
}


/* ---------------------------------------------------------------------------
   Evaluate the current [ident] buffer for integer constant. The following
   type specifiers are recognized:

        0xhhh , $hhhh   hex constant
        @bbbb           binary constant

        constant is evaluated by default as decimal, if no type specifier is used.

   The evaluated constant is returned as a long integer.

   *evalerr byref argument is set to 0 when constant was successfully evaluated,
   otherwise 1.
   --------------------------------------------------------------------------- */
long
GetConstant (char *evalerr)
{
    short size;
    char *temp = NULL;
    long lv;

    errno = 0;            /* reset global error number */
    lv = 0;
    *evalerr = 0;         /* preset evaluation return code to no errors */
    size = strlen (ident);

    if ((sym != hexconst) && (sym != binconst) && (sym != decmconst)) {
        *evalerr = 1;
        return lv;       /* syntax error - illegal constant definition */
    }

    if ( ident[0] == '0' && toupper(ident[1]) == 'X') {
        /* fetch hex constant specified as 0x... */
        lv = (long) strtoll((ident + 2), &temp, 16);
        if (*temp != '\0' || errno == ERANGE) {
            *evalerr = 1;
        }

        return lv; /* returns 0 on error */
    }

    if ( ident[0] == '0' && toupper(ident[1]) == 'B' && toupper(ident[size-1] == 'H')) {
        /* fetch hex constant specified as 0b..H (truncate 'H' specifier) */
        ident[size-1] = '\0';
        lv = (long) strtoll(ident, &temp, 16);
        if (*temp != '\0' || errno == ERANGE) {
            *evalerr = 1;
        }

        return lv; /* returns 0 on error */
    }

    if ( ident[0] == '0' && toupper(ident[1]) == 'B' && toupper(ident[size-1] != 'H')) {
        /* fetch binary constant specified as 0b... */
        lv = (long) strtoll((ident + 2), &temp, 2);
        if (*temp != '\0' || errno == ERANGE) {
            *evalerr = 1;
        }

        return lv; /* returns 0 on error */
    }

    if (sym != decmconst) {
        if ((--size) == 0) { /* adjust size of non decimal constants without leading type specifier */
            *evalerr = 1;
            return lv;     /* syntax error - no constant specified */
        }
    }

    switch (ident[0]) {
    case '@':
        /* Binary integer are identified with leading @ */
        lv = (long) strtoll((ident + 1), &temp, 2);
        if (*temp != '\0' || errno == ERANGE) {
            *evalerr = 1;
        }

        return lv; /* returns 0 on error */

    case '$':
        /* Hexadecimal integers may be specified with leading $ */
        lv = (long) strtoll((ident + 1), &temp, 16);
        if (*temp != '\0' || errno == ERANGE) {
            *evalerr = 1;
        }

        return lv; /* returns 0 on error */

        /* Parse default decimal integers */
    default:
        lv = (long) strtoll(ident, &temp, 10);
        if (*temp != '\0' || errno == ERANGE) {
            *evalerr = 1;
        }

        return lv; /* returns 0 on error */
    }
}


/* ----------------------------------------------------------------
    int GetChar (sourcefile_t *file)

    Return a character from current (cached) memory file with
    CR/LF/CRLF parsing capability.

    Handles continuous line '\' marker (skip physical EOL)
    and returns value of escape sequences (\n, \\, \r, \t, \a, \b, \f, \', \")

    '\n' byte is returned if a CR/LF/CRLF variation line feed is found.
   ---------------------------------------------------------------- */
int
__gcLf (sourcefile_t *file) {
    int c = MfGetc (file);
    if (c == 13) {
        /* Mac line feed found, poll for MSDOS line feed */
        if ( MfGetc (file) != 10) {
            MfUngetc (file);  /* push non-line-feed character back into file */
        }
        c = '\n';    /* always return UNIX line feed for CR or CRLF */
    }

    return c;
}


/* ------------------------------------------------------------------------------------------ */
void
SkipLine (sourcefile_t *file)
{
    int c;

    if (file->eol == false) {
        while (!MfEof (file)) {

            c = MfGetc (file);
            if (c == 13) {
                /* Mac line feed found, poll for MSDOS line feed */
                c = MfGetc (file);
                if (c != 10) {
                    MfUngetc(file);  /* push non-line-feed character back into file */
                }

                c = '\n'; /* always return the symbolic '\n' for line feed */
            } else if (c == 10) {
                c = '\n';    /* UNIX line feed */
            }

            if ((c == '\n') || (c == EOF)) {
                break;    /* get to beginning of next line... */
            }
            if ( c == '*' ) {
                c = MfGetc (file);
                if ( c == '/' ) {
                    if (cstyle_comment == true) {
                        cstyle_comment = false;
                        return;
                    }
                } else {
                    MfUngetc (file);    /* puch character back for next read */
                }
            }
        }

        file->eol = true;
    }
}


/* ------------------------------------------------------------------------------------------ */
int
GetChar (sourcefile_t *file)
{
    int c = __gcLf(file);

    /* continuous line or escape sequence? */
    if ( c == '\\' ) {
            c = __gcLf(file);

            /* Also handle escape sequences, http://en.wikipedia.org/wiki/Escape_sequences_in_C  */
            switch(c) {
                case '\n':
                    /* There was an EOL just after the \, return a space and update line counter */
                    c = 0x20;
                    file->eol = false;
                    break;
                case '\\':
                    c = '\\'; /* interpret \\ as \ */
                    break;
                case 'n':
                    c = 0x0a; /* interpret as Ascii Line feed */
                    break;
                case 'r':
                    c = 0x0d; /* interpret as Ascii Carriage return */
                    break;
                case 't':
                    c = 0x09; /* interpret as Ascii horisontal tab */
                    break;
                case 'a':
                    c = 0x07; /* interpret as Ascii Alarm */
                    break;
                case 'b':
                    c = 0x08; /* interpret as Ascii Backspace */
                    break;
                case 'f':
                    c = 0x0c; /* interpret as Ascii Formfeed */
                    break;
                case '\'':
                    c = '\''; /* ' */
                    break;
                case '\"':
                    c = '\"'; /* " */
                    break;
                default:
                    /* continuous line marker, skip until EOL */
                    MfUngetc(file);
                    SkipLine(file);
                    if (file->eol == true) {
                        file->eol = false;
                    }
            }
    }

    return c; /* return all other characters */
}


/* ------------------------------------------------------------------------------------------ */
void
CharToIdent(const char c, const int index)
{
    if (index <= MAX_NAME_SIZE) {
        ident[index] = c;
    }
}


/* ---------------------------------------------------------------------------
    char *substr(char *s, char *find)

    Compare no more than N characters of S1 and S2,
    returning less than, equal to or greater than zero
    if S1 is lexicographically less than, equal to or
    greater than S2.

    Original algorithm, Copyright GNU LIBC, adapted with toupper()
   --------------------------------------------------------------------------- */
int
strnicmp (const char *s1, const char *s2, size_t n)
{
  unsigned char c1 = '\0';
  unsigned char c2 = '\0';

  if (n >= 4)
    {
      size_t n4 = n >> 2;
      do
      {
        c1 = toupper((unsigned char) *s1++);
        c2 = toupper((unsigned char) *s2++);
        if (c1 == '\0' || c1 != c2)
          return c1 - c2;
        c1 = toupper((unsigned char) *s1++);
        c2 = toupper((unsigned char) *s2++);
        if (c1 == '\0' || c1 != c2)
          return c1 - c2;
        c1 = toupper((unsigned char) *s1++);
        c2 = toupper((unsigned char) *s2++);
        if (c1 == '\0' || c1 != c2)
          return c1 - c2;
        c1 = toupper((unsigned char) *s1++);
        c2 = toupper((unsigned char) *s2++);
        if (c1 == '\0' || c1 != c2)
          return c1 - c2;
      } while (--n4 > 0);
      n &= 3;
    }

  while (n > 0)
    {
      c1 = toupper((unsigned char) *s1++);
      c2 = toupper((unsigned char) *s2++);
      if (c1 == '\0' || c1 != c2)
        return c1 - c2;
      n--;
    }

  return c1 - c2;
}


/* ------------------------------------------------------------------------------------------
    int CheckBaseType(int chcount)

    Identify Hex-, binary and decimal constants in [ident] of
        $xxxx or 0x or xxxxH (hex format)
        0Bxxxxx or xxxxB     (binary format)
        xxxxD                (decimal format)

        and

    Identify assembler functions as $ (converted to $PC) or $name
    (which is not a legal hex constant)
   ------------------------------------------------------------------------------------------ */
int
CheckBaseType(int chcount)
{
    int   i;

    if (ident[0] == '$') {
        if (strlen(ident) > 1) {
            for (i = 1; i < chcount; i++) {
                if (isxdigit (ident[i]) == 0) {
                    sym = asmfnname;
                    return chcount;
                }
            }

            sym = hexconst;
            return chcount;
        }
    }

    /* If it's not a hex digit straight off then reject it */
    if ( !isxdigit(ident[0]) || chcount < 2 ) {
        return chcount;
    }

    /* C style hex number */
    if ( chcount > 2 && strnicmp(ident,"0x",2) == 0 ) {
        /* 0x hex constants are evaluated by GetConstant() */
        sym = hexconst;
        return chcount;
    }

    /* C style hex number, ambiguous constant 0bxxxH! */
    if ( chcount > 2 && strnicmp(ident,"0b",2) == 0 && ident[chcount-1] == 'H') {
        /* hex constants are evaluated by GetConstant() */
        sym = hexconst;
        return chcount;
    }

    /* C style binary number */
    if ( chcount > 2 && strnicmp(ident,"0b",2) == 0 ) {
        /* 0b binary constants are evaluated by GetConstant() */
        sym = binconst;
        return chcount;
    }

    /* Check for this to be a hex constant here */
    for ( i=0; i < chcount; i++ ) {
        if ( !isxdigit(ident[i])  ) {
            break;
        }
    }

    if ( i == (chcount-1) ) {
        /* Convert xxxxH hex constants to $xxxxx */
        if ( toupper(ident[i]) == 'H' ) {
            for ( i = (chcount-1); i >= 0 ; i-- ) {
                ident[i+1] = ident[i];
            }
            ident[0] = '$';
            sym = hexconst;
            return chcount;
        } else {
            /* If we reached end of hex digits and the last one wasn't a 'h', then something is wrong */
            return chcount;
        }
    }

    /* Check for binary constant (ends in b) */
    for ( i = 0; i <  chcount ; i++ ) {
        if ( ident[i] != '0' && ident[i] != '1'  ) {
            break;
        }
    }

    if ( i == (chcount-1) && toupper(ident[i]) == 'B' ) {
        /* Convert xxxxB binary constants to @xxxx constants */
        for ( i = (chcount-1); i >= 0 ; i-- ) {
            ident[i+1] = ident[i];
        }
        ident[0] = '@';
        sym = binconst;
        return chcount;
    }

    /* Check for decimal (we default to it in anycase.. but */
    for ( i = 0; i <  chcount ; i++ ) {
        if ( !isdigit(ident[i]) ) {
            break;
        }
    }
    if ( i == (chcount-1) && toupper(ident[i]) == 'D' ) {
        sym = decmconst;
        return chcount-1; /* chop off the 'D' trailing specifier for decimals */
    }

    /* No hex, binary or decimal base types were recognized, return without change */
    return chcount;
}


/* ------------------------------------------------------------------------------------------ */
enum symbols
GetSym (sourcefile_t *file)
{
    char *instr;
    int c, chcount = 0, endbracket = 0;
    unsigned char *ptr;

    ident[0] = '\0';

    if (file->eol == true) {
        sym = newline;
        return sym;
    }

    for (;;) {
        /* Ignore leading white spaces, if any... */
        if (MfEof (file)) {
            sym = newline;
            file->eol = true;
            return newline;
        } else {
            c = GetChar (file);
            if ((c == '\n') || (c == EOF) || (c == '\x1A')) {
                sym = newline;
                file->eol = true;
                return newline;
            } else if (!isspace (c)) {
                break;
            }
        }
    }

    instr = strchr (separators, c);
    if (instr != NULL) {
        sym = ssym[instr - separators]; /* index of found char in separators[] */
        if (sym == semicolon) {
            SkipLine (file);        /* ';' or '#', ignore comment line, prepare for next line */
            sym = newline;
        }

        switch (sym) {
        case multiply:
            c = GetChar (file);
            if (c == '*') {
                sym = power;    /* '**' */
            } else if (c == '/') {
                /* c-style end-comment, continue parsing after this marker */
                cstyle_comment = false;
                GetSym(file);
            } else {
                /* push this character back for next read */
                MfUngetc(file);
            }
            break;

        case divi:         /* c-style comment begin */
            c = GetChar (file);
            if (c == '*') {
                cstyle_comment = true;
                SkipLine (file);    /* ignore comment block */
                GetSym(file);
            } else {
                /* push this character back for next read */
                MfUngetc(file);
            }
            break;

        case less:         /* '<' */
            c = GetChar (file);
            switch (c) {
            case '<':
                sym = lshift;       /* '<<' */
                break;

            case '>':
                sym = notequal;    /* '<>' */
                break;

            case '=':
                sym = lessequal;       /* '<=' */
                break;

            default:
                /* '<' was found, push this character back for next read */
                MfUngetc(file);
                break;
            }
            break;

        case greater:          /* '>' */
            c = GetChar (file);
            switch (c) {
            case '>':
                sym = rshift;       /* '>>' */
                break;

            case '=':
                sym = greatequal;      /* '>=' */
                break;

            default:
                /* '>' was found, push this character back for next read */
                MfUngetc(file);
                break;
            }
            break;

        default:
            break;
        }

        if (cstyle_comment == true) {
            SkipLine (file);
            return GetSym(file);
        } else {
            return sym;
        }
    }

    /* before going deeper into symbol parsing, check if we're in a c-style comment block... */
    if (cstyle_comment == true) {
        SkipLine (file);
        return GetSym(file);
    }

    CharToIdent((char) toupper (c), chcount++);
    switch (c) {
    case '$':
        sym = hexconst;
        break;

    case '@':
        sym = binconst;
        break;

    case '_':                   /* leading '_' allowed for name definitions */
        sym = name;
        break;

    case '#':
        sym = name;
        break;

    default:
        if (isdigit (c)) {
            sym = decmconst;  /* a decimal number found */
        } else {
            if (isalpha (c)) {
                sym = name;   /* an identifier found */
            } else {
                sym = nil;    /* rubbish ... */
            }
        }
        break;
    }

    /* Read identifier until space or legal separator is found */
    if (sym == name) {
        for (;;) {
            if (MfEof (file)) {
                break;
            } else {
                c = GetChar (file);
                if ((c != EOF) && (!iscntrl (c)) && (strchr (separators, c) == NULL)) {
                    if (!isalnum (c)) {
                        if (c != '_') {
                            sym = nil;
                            break;
                        } else {
                            /* underscore in identifier */
                            CharToIdent('_', chcount++);
                        }
                    } else {
                        CharToIdent((char) toupper (c), chcount++);
                    }
                } else {
                    if ( c != ':' ) {
                        MfUngetc(file);   /* puch character back for next read */
                    } else {
                        sym = colonlabel;
                    }
                    break;
                }
            }
        }
    } else {
        for (;;) {
            if (MfEof (file)) {
                break;
            } else {
                c = GetChar (file);
                if ((c != EOF) && !iscntrl (c) && (strchr (separators, c) == NULL)) {
                    CharToIdent((char) toupper (c), chcount++);
                } else {
                    MfUngetc(file);   /* puch character back for next read */

                    CharToIdent(0, chcount);
                    /* validate if ident might be a number constant as with a trailing h, d or b */
                    chcount = CheckBaseType(chcount);
                    break;
                }
            }
        }
    }

    ident[chcount] = '\0';
    return sym;
}


/* ------------------------------------------------------------------------------------------ */
void
defm(sourcefile_t *file)
{
    long constant;
    char evalerr;

    do {
        if (GetSym (file) == dquote) {
            while (!MfEof (file)) {

                constant = GetChar (file);
                if (constant == EOF) {
                    sym = newline;
                    file->eol = true;
                    ReportError (file->fname, file->lineno, Err_Syntax);
                    return;
                } else {
                    if (constant != '\"') {
                        *codeptr++ = (unsigned char) constant;
                    } else {
                        GetSym (file);

                        if (sym != strconq && sym != comma && sym != newline && sym != semicolon) {
                            ReportError (file->fname, file->lineno, Err_Syntax);
                            return;
                        }
                        break;    /* get out of loop */
                    }
                }
            }
        } else {

            constant = GetConstant(&evalerr);
            if (evalerr == 0) {
                if ( (constant >= 0) && (constant <= 255) ) {
                    *codeptr++ = (unsigned char) constant;
                } else {
                    ReportError (file->fname, file->lineno, Err_ConstOutOfRange);   /* out of range */
                }
                GetSym (file);
            } else {
                ReportError (file->fname, file->lineno, Err_ConstOutOfRange);   /* the constant was not evaluable */
            }

            if (sym != strconq && sym != comma && sym != newline && sym != semicolon) {
                ReportError (file->fname, file->lineno, Err_Syntax);   /* expression separator not found */
                break;
            }
        }
    } while (sym != newline && sym != semicolon);
}


/* ------------------------------------------------------------------------------------------ */
void
ParseLine (sourcefile_t *asmfile, bool interpret)
{
    line[0] = '\0';     /* preset line buffer to being empty */
    codeptr = line;     /* prepare the pointer that collects fetched charecters from DEFM directive */
    defm_t *newsrcline;

    asmfile->lineptr = MfTell (asmfile); /* preserve the beginning of the current line, for reference */
    ++asmfile->lineno;

    asmfile->eol = false; /* reset END OF LINE flag */
    GetSym (asmfile);     /* and fetch first symbol on line */

    switch (sym) {
        case name:
            /* only DEFM directive is identified and parsed... */
            if (strcmp(ident, "DEFM") == 0) {
                defm(asmfile);

                if (totalerrors == 0) {
                    /* DEFM directive successfully parsed, copy line and add to linked list of parsed source lines */
                    newsrcline = CopySourceLine(line, codeptr-line);
                    if (newsrcline != NULL) {
                        AddSourceLine(newsrcline);
                    }
                }
            }

        default:
            /* ignore other constructs of source line... get next line */
            SkipLine (asmfile);
            break;
    }
}


/* ------------------------------------------------------------------------------------------ */
bool
ParseAsmTextFile (sourcefile_t *asmfile)
{
    while (!MfEof (asmfile)) {
        ParseLine (asmfile, true);

        /* If errors, return immediatly... */
        if (totalerrors > 0) {
            return false;
        }
    }

    return true;
}


/* ------------------------------------------------------------------------------------------ */
void
OutputString(unsigned char *str, int len)
{
    int l;
    bool ascii=false, hex=false;

    for (l=0; l<len; l++) {
        if (str[l] < 32 || str[l] >= 127) {
            if (ascii == true) {
                ascii = false;
                /* terminate Ascii string, before outputting the hex constant */
                fprintf(stdout,"\",");
            }
            if (hex == true) {
                /* a hex byte was previously written, separate with comma for this one */
                fprintf(stdout,",");
            }

            hex = true;
            fprintf(stdout,"$%02X", str[l]);
        } else {
            if (hex == true) {
                hex = false;
                /* a hex byte was prev. output, prepare for Ascii string, before outputting the char(s) */
                fprintf(stdout,",\"");
            } else if (ascii == false) {
                /* this is first byte of output and it is part of a string */
                fprintf(stdout,"\"");
            }

            ascii = true;
            fputc(str[l],stdout);
        }
    }

    if (ascii == true) {
        /* terminate ascii string */
        fprintf(stdout,"\"");
    }
}


/* ------------------------------------------------------------------------------------------ */
void
OutputTokenizedTextFile(void)
{
    defm_t *curline = sourcelines->firstline;

    while (curline != NULL) {
        fprintf(stdout,"defm ");
        OutputString(curline->str, curline->len);
        fputc('\n',stdout);

        curline = curline->nextline;
    }
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
        ReportError (NULL, 0, Err_Memory);
    }

    return rawtoken;
}


/* ------------------------------------------------------------------------------------------ */
token_t *
AllocExpandedToken(tokentable_t *tkt, int tkid)
{
    int i;
    token_t *exptoken = AllocRawToken(tkt, (tkid & 0x7f)); /* internal token ID is 0 - 127 */
    token_t *inserttoken;

    if (exptoken != NULL) {
        for (i=0; i<exptoken->len; i++) {
            if (exptoken->str[i] >= 0x80) {
                /* this token string contains a recursive token ID, fetch it and replace it in the raw string */
                inserttoken = AllocExpandedToken(tkt, exptoken->str[i]);
                if (inserttoken != NULL) {
                    /* make space for expanded token length - 1 (the token code already occupies 1 byte) */
                    exptoken->str = realloc( exptoken->str, exptoken->len + inserttoken->len );
                    if (exptoken->str != NULL) {
                        /* insert space at token code - move right side of current raw string of len of new token, rightwards */
                        memmove( exptoken->str + i + inserttoken->len, exptoken->str + i + 1, exptoken->len-i );
                        /* replace token code with expanded text of it self */
                        memcpy(exptoken->str+i, inserttoken->str, inserttoken->len);
                        /* update the new length of the current token */
                        exptoken->len = exptoken->len + inserttoken->len - 1;
                        /* temporary token usage completed, discard it */
                        ReleaseToken(inserttoken);
                    } else {
                        /* re-allocation failed, release allocated ressources here.. */
                        ReleaseToken(inserttoken);
                        ReleaseToken(exptoken);
                        exptoken = NULL;
                        break;
                    }
                } else {
                    /* abort, no room */
                    ReleaseToken(exptoken);
                    exptoken = NULL;
                    break;
                }
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
        ReportError (NULL, 0, Err_TokenNotFound);
    } else {
        token = AllocExpandedToken(tkt, tkid);
    }

    return token;
}


/* ------------------------------------------------------------------------------------------
    void InsertTokenId(defm_t *line, token_t *tk, unsigned char *position)

    Replace expanded token text in line at <position> with token ID
   ------------------------------------------------------------------------------------------ */
void
InsertTokenId(defm_t *line, token_t *tk, unsigned char *position)
{
    int lenRightStr = (line->str + line->len) - (position + tk->len);

    *position = tk->id; /* apply token ID at first byte of found token text */

    /* left-shift rest of line next to token ID */
    memmove( position + 1, position + tk->len, lenRightStr);

    /* update total (reduced length of line) */
    line->len -= tk->len - 1;
}


/* ------------------------------------------------------------------------------------------
    unsigned char *MatchToken(defm_t *line, token_t *tk)

    Try to match an expanded string token in the specified line (left to right scan)

    Return pointer to first byte of string match in line, or NULL if not found.
   ------------------------------------------------------------------------------------------ */
unsigned char *
MatchToken(defm_t *line, token_t *tk)
{
    int q = 0, c = 0;
    int limit = line->len - tk->len;

    while ( q < limit ) {
        while ( line->str[q+c] == tk->str[c] ) {
            if ( ++c == tk->len )
                return line->str+q;
        }

        q += c+1;
        c=0;
    }

    return NULL;
}


/* ------------------------------------------------------------------------------------------ */
void
TokenizeLine(defm_t *line, token_t *tk)
{
    unsigned char *foundtoken;

    while ( (foundtoken = MatchToken(line,tk)) ) {
        /* expanded token string found in line, replace it with token ID */
        InsertTokenId(line, tk, foundtoken);
    }
}


/* ------------------------------------------------------------------------------------------
    void TokenizeTextFile(tokentable_t *tkt)

    Brute-force tokenize the text file with all tokens, sequentially from $80 onwards..
   ------------------------------------------------------------------------------------------ */
void
TokenizeTextFile(tokentable_t *tkt)
{
    token_t *exptoken;
    defm_t *curline;
    int i;

    for (i=0; i<tkt->totaltokens; i++) {
        token_t *exptoken = AllocTokenInstance(tkt, i);
        defm_t *curline = sourcelines->firstline;

        while (curline != NULL) {
            TokenizeLine(curline, exptoken);
            curline = curline->nextline;
        }

        ReleaseToken(exptoken);
    }
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
        ReportError(filename, 0, Err_NoTokenTable);
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
        ReportError(filename, 0, Err_NoTokenTable);
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
            ReportError(filename, 0, Err_NoTokenTable);
            free(tokentablefile);
            return NULL;
        }

        tokenptr += 2;
        nexttokenptr += 2;
    }

    tokentable = AllocTokenTable();
    if ( tokentable == NULL ) {
        ReportError(filename, 0, Err_NoTokenTable);
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
    token_t *rawtoken, *exptoken;

    for (i=0; i < tkt->totaltokens; i++) {
        rawtoken = AllocRawToken(tkt, i);
        exptoken = AllocTokenInstance(tkt, i);

        if (rawtoken != NULL && exptoken != NULL) {
            fprintf(stdout,"Token $%02X (Length %d) = ", exptoken->id, exptoken->len);
            OutputString(exptoken->str, exptoken->len);
            if (exptoken->len > rawtoken->len) {
                fprintf(stdout," (original token, length = %d: ", rawtoken->len);
                OutputString(rawtoken->str, rawtoken->len);
                fputc(')',stdout);
            }

            fputc('\n',stdout);
        }

        ReleaseToken(rawtoken);
        ReleaseToken(exptoken);
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
    sourcefile_t *asmfile;
    FILE *fd;
    bool processedStatus = true;

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
            /* text file specified */
            asmfile = Newfile (NULL, argv[argidx]);   /* Allocate new file into memory */
            if (asmfile != NULL) {
                fd = fopen (AdjustPlatformFilename(argv[argidx]), "rb");
                if (fd != NULL) {
                    if (CacheFile (asmfile, fd) != NULL) {
                        /* source code successfully loaded, start tokenizing... */
                        fprintf(stderr,"Tokenize '%s' text file...\n", argv[argidx]);
                        processedStatus = ParseAsmTextFile (asmfile);
                        if (processedStatus == true) {
                            TokenizeTextFile(tokentable);
                            OutputTokenizedTextFile();
                        }

                        ReleaseFile(asmfile);
                    } else {
                        /* problems caching the file... */
                        processedStatus = false;
                    }
                    fclose(fd);
                } else {
                    ReportIOError(argv[argidx]);
                    processedStatus = false;
                }
            } else {
                processedStatus = false;
            }
        } else {
            /* just output the token table to stdout */
            fprintf(stderr,"Contents of Token Table:\n");
            ListExpandedTokens(tokentable);
        }

        ReleaseTokenTable(tokentable);
    }

    return processedStatus;
}


/* ------------------------------------------------------------------------------------------
    int main(int argc, char *argv[])

    MthToken command line entry

    Returns:
        0, text file tokenized and sent to stdout
        1, an error occurred during tokenization
   ------------------------------------------------------------------------------------------ */
int
main(int argc, char *argv[])
{
    int status = 1; /* default as error status */

    if ( AllocateTextFileStructures() ) {
        if (ProcessCommandline(argc, argv) == true) {
            status = 0; // mission completed..
        }
    }
    FreeTextFileStructures();

    return status;
}
