
/* definitions */


%{
#include <stdio.h>
#include <string.h>
#include "tokendef.h"

int scancol = 1;
int yycol = 1;
int scanlineno = 1;
int current_col = 1;

char* yyerror;
char* string_value;

void updateCol(); 
void countLines(); 
int processString(); 
%}

newline (\r\n|\r|\n) /* Revised */
whitespace [\t ]
integer  (0|[1-9][0-9]*)
integerlead0 (0[0-9]+)
character (\'[a-zA-Z]\')

/* String can contain any characters between the double quotes other than a newline or unescaped doublequotes. Valid escapes: \n \t \" \\ */
/* This has been revised */
string (\"([^"\\\n]|\\.)*\")

/* multiline string has \n somewhere in the middle */
/* Not revised, causing issues */
multlnstring (\"([^"\\\n]|\\.)*\n([^"\\\n]|\\.)*\")

/* Unterminated: " without closing " */
/* Not revised, causing issues */
untermstring (\"([^"\\\n]|\\.)*)  

comment (\/\*([^*]|\*+[^\*])*\*+\/)
multlncomment   (\/\*([^*]|\*+[^\*])*\*+\/)
untermcomment   (\/\*[a-zA-Z0-9]*\*|\/\*[a-zA-Z0-9]*\/|\/\*[a-zA-Z0-9]*|\/\/[a-zA-Z0-9]*)

identifier      ([a-zA-Z][a-zA-Z0-9]*)
illidentifier   ([0-9][a-zA-Z0-9]*)

yylineno = 1;

%%

 /* rules */

 /* Keywords */
"if" {updateCol(); return KWD_IF;}
"else" {updateCol(); return KWD_ELSE;}
"while" {updateCol(); return KWD_WHILE;}
"int" {updateCol(); return KWD_INT;}
"string" {updateCol(); return KWD_STRING;}
"char" {updateCol(); return KWD_CHAR;}
"return" {updateCol(); return KWD_RETURN;}
"void" {updateCol(); return KWD_VOID;}
 /* Operators */

"+" {updateCol(); return OPER_ADD;}
"*" {updateCol(); return OPER_MUL;} 
"/" {updateCol(); return OPER_DIV;}
"%" {updateCol(); return OPER_MOD;}
"<" {updateCol(); return OPER_LT;}
">" {updateCol(); return OPER_GT;}
"<=" {updateCol(); return OPER_LTE;}
">=" {updateCol(); return OPER_GTE;}
"==" {updateCol(); return OPER_EQ;}
"!=" {updateCol(); return OPER_NEQ;}
"=" {updateCol(); return OPER_ASGN;}
"[" {updateCol(); return LSQ_BRKT;}
"]" {updateCol(); return RSQ_BRKT;}
"{" {updateCol(); return LCRLY_BRKT;}
"}" {updateCol(); return RCRLY_BRKT;}
"(" {updateCol(); return LPAREN;}
")" {updateCol(); return RPAREN;}
"," {updateCol(); return COMMA;}
";" {updateCol(); return SEMICLN;}
"@" {updateCol(); return OPER_AT;}
"++" {updateCol(); return OPER_INC;}
"--" {updateCol(); return OPER_DEC;}
"&&" {updateCol(); return OPER_AND;}
"||" {updateCol(); return OPER_OR;}
"!" {updateCol(); return OPER_NOT;}


 /* Identifiers */
{identifier} {updateCol(); return ID;}
{illidentifier} {updateCol(); return ILLEGAL_TOK;}

 /* Constants */
{integer}       {updateCol(); return INTCONST;}
{integerlead0}  {updateCol(); return ILLEGAL_TOK;}
{character}     {updateCol(); return CHARCONST;}
{string}        {updateCol(); return processString();}
{untermstring}  {updateCol(); yyerror = "Unterminated string"; return ERROR;}
{multlnstring}  {updateCol(); countLines(); yyerror = "String spans multiple lines"; return ERROR;} /* Catching a multi-line string */

 /* Comments - skip (no token) */
{comment}       {updateCol(); return COMMENT;}
{untermcomment} { updateCol(); yyerror = "Unterminated comment"; return ERROR; }
{multlncomment} { updateCol(); countLines(); return MULTLNCOMMENT;}

\n|\r\n|\r    { yylineno++; current_col = 1;}
[ \t]+         { current_col += yyleng;}
.               {return ILLEGAL_TOK;}

%%

/* user routines */

void updateCol(){
    yycol = current_col; 
    current_col += yyleng;
}

void countLines(){
	for (char *current = yytext; *current; current++){
        if (*current == '\n') {
            yylineno++;
            current_col = 1;
        }
        else {
            current_col += yyleng;
        }
    }
}


int processString(void) {
    static char buffer[4096]; /* static buffer to store processed characters */
    const char *current = yytext + 1; /* pointer to the current character being processed. Starting at the first character after the opening double quote. */
    const char *end = yytext + strlen(yytext) - 1; /* pointer the the last character before the closing double quote */
    char *out = buffer; /* pointer to the buffer to load processed characters */

    while (current < end) { /* while the current character is not the memory address of the last character */
        if (*current == '\\') {
            current++;
            if (current >= end) {
                yyerror = "Unrecognized escape character in String";
                return ERROR;
            }
            switch (*current++) {
                case 'n':  *out++ = '\n'; break;
                case 't':  *out++ = '\t'; break;
                case '"':  *out++ = '\"'; break;
                case '\\': *out++ = '\\'; break;
                default:
                    yycol = yycol + (current - 1 - yytext);
                    yyerror = "Unrecognized escape character in String";
                    return ERROR;
            }
        } else {
            *out++ = *current++;
        }
    }
    *out = '\0';
    string_value = buffer;
    return STRCONST;
}
