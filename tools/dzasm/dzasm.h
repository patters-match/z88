
/*
    DDDDDDDDDDDDD            ZZZZZZZZZZZZZZZZ
    DDDDDDDDDDDDDDD        ZZZZZZZZZZZZZZZZ
    DDDD         DDDD               ZZZZZ
    DDDD         DDDD             ZZZZZ
    DDDD         DDDD           ZZZZZ             AAAAAA         SSSSSSSSSSS   MMMM       MMMM
    DDDD         DDDD         ZZZZZ              AAAAAAAA      SSSS            MMMMMM   MMMMMM
    DDDD         DDDD       ZZZZZ               AAAA  AAAA     SSSSSSSSSSS     MMMMMMMMMMMMMMM
    DDDD         DDDD     ZZZZZ                AAAAAAAAAAAA      SSSSSSSSSSS   MMMM MMMMM MMMM
    DDDDDDDDDDDDDDD     ZZZZZZZZZZZZZZZZZ     AAAA      AAAA           SSSSS   MMMM       MMMM
    DDDDDDDDDDDDD     ZZZZZZZZZZZZZZZZZ      AAAA        AAAA  SSSSSSSSSSS     MMMM       MMMM

Copyright (C) Gunther Strube, InterLogic 1996-99

*/

/* $Id$ */

enum atype              {
				vacuum, program, addrtable, defp, defw, defb, defs, string, nop,
				romhdr, frontdor, appldor, hlpdor, apltpc, inftpc, mthcmd, mthhlp, mthtkn,
				notfound
			};
                        	/* NB: remember to update gAreaTypes table in 'areas.c' */
enum files              {
				none, stdio, fileio, director, memory, dor, syspar, saverestore,
              	                floatp, integer, serinterface, screen, timedate, chars, error, map,
              	                alarm, filter, tokens, intrrupt, printer, handle
                        };

enum symbols		{
				space, strconq, dquote, squote, semicolon, comma, fullstop, lparen, lcurly, rcurly, rparen,
				plus, minus, multiply, divi, mod, power, assign, bin_and, bin_or, bin_xor, less,
				greater, log_not, constexpr, newline, lessequal, greatequal, notequal, name, number,
				decmconst, hexconst, binconst, charconst, negated, nil
			};

enum truefalse          { false, true };

typedef struct area {
        long  			start;
        long  			end;
        enum atype     	areatype;
        enum truefalse  parsed;
        struct area     *prevarea;
        struct area     *nextarea;
        void 			*attributes;		/* Pointer to area specific attributes */
} DZarea;

struct  PrsAddrStack {
        long          		labeladdr;
        struct PrsAddrStack *previtem;
};

typedef struct address {
	long			addr;		/* the recorded parsing address */
	unsigned short		visited;	/* number of times this address has been visited */
} ParsedAddress;

typedef struct Label {
        long			addr;
	char			*name;
        enum truefalse  	referenced;
        enum truefalse  	local;          /* is label inside local area? */
        enum truefalse  	xref;		/* is data reference declared as XREF (external) by user? */
        enum truefalse  	xdef;		/* is data reference declared as XDEF (global) by user? */
        enum truefalse		addrref;	/* is this label a call reference (= true) */
} LabelRef;

typedef struct expr {
    long		    addr;		/* entry point to replace mnemonic constant */
	char			*expr;		/* with ASCII expression (or just a string mnemonic representation) */
} Expression;

typedef struct constant {
    long		    constantval;	/* global constant value of matching mnemonic constants */
	char			*constname;	/* to be replaced with ASCII name */
} GlobalConstant;

typedef struct remline {
	char			*line;		/* pointer to comment line text */
	struct remline	*next;		/* next line of comment in list */
} Commentline;

typedef struct rem {
	long  			addr;		/* address of printing comment */
	char			position;	/* are comments to be printed before ('<') or after ('>') mnemonics? */
	Commentline		*comments;	/* single list of comment lines */
} Remark;

typedef struct incf {
	char			*filename;	/* pointer to explicit include filename */
	struct incf		*next;		/* next include file item */
} IncludeFile;

typedef void 	(*ptrfunc) ();	/* ptr to function returning void */
typedef int 	(*fptr) (const void *, const void *);

struct dzcmd {
	char *cmd;
    ptrfunc dzcmd;
};

#define MAXCODESIZE 65536
