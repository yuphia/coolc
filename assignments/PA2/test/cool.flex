/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Dont remove anything that was here initially
 */
%{

#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int curr_line_len = 0;
bool should_tokenize = true;

int nested_depth = 0;

%}

/* Define names for regular expressions here.*/

/* Multi-symbol operators */
DARROW          =>
ASSIGN          <-

/* Whitespace */
WHITESPACE [ \t\f\r\v]

/* Numbers */
DIGIT   [0-9]
INTEGER {DIGIT}+ 

/* Objects */
UNDERSCORE _
TYPEID   [A-Z][a-zA-Z0-9_]*
OBJECTID [a-z][a-zA-Z0-9_]*

/* Error */ 
ERROR    .

/* Keywords */
CLASS    ?i:class    
ELSE     ?i:else     
FI       ?i:fi       
IF       ?i:if       
IN       ?i:in       
INHERITS ?i:inherits 
ISVOID   ?i:isvoid   
LET      ?i:let      
LOOP     ?i:loop     
POOL     ?i:pool     
THEN     ?i:then     
WHILE    ?i:while    
CASE     ?i:case     
ESAC     ?i:esac     
NEW      ?i:new      
OF       ?i:of       
NOT      ?i:not      
LE       <=

ALSE     ?i:alse
FALSE    f{ALSE}
RUE      ?i:rue
TRUE     t{RUE}

/* Comment */

SIMPLE_COMMENT_START "--"

NESTED_COMMENT_START "(*"
NESTED_COMMENT_END   "*)"

%x NESTED_COMMENT
%x SIMPLE_COMMENT

/* String */

STRING_START "\""
STRING_END   "\""

%x STRING
%x STRING_ERRONEOUS

%%

 /*
  *  Nested comments
  */

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{ASSIGN}        { return (ASSIGN); }
{LE}        { return         (LE); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}     { return      (CLASS); }
{ELSE}      { return       (ELSE); }
{FI}        { return         (FI); }
{IF}        { return         (IF); }
{IN}        { return         (IN); }
{INHERITS}  { return   (INHERITS); }
{ISVOID}    { return     (ISVOID); }
{LET}       { return        (LET); }
{LOOP}      { return       (LOOP); }
{POOL}      { return       (POOL); }
{THEN}      { return       (THEN); }
{WHILE}     { return      (WHILE); }
{CASE}      { return       (CASE); }
{ESAC}      { return       (ESAC); }
{NEW}       { return        (NEW); }
{OF}        { return         (OF); }
{NOT}       { return        (NOT); }

{FALSE}         { 
                    cool_yylval.boolean = false;
                    return (BOOL_CONST); 
                }

{TRUE}          {
                    cool_yylval.boolean = true;
                    return (BOOL_CONST); 
                }


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  */ 

{STRING_START}  { 
                    BEGIN (STRING); 
                    for (curr_line_len = 0; curr_line_len < MAX_STR_CONST; curr_line_len++)
                        string_buf[curr_line_len] = '\0';    

                    curr_line_len = 0;
                }

<STRING><<EOF>> {
                    if (!should_tokenize)
                        yyterminate();

                    cool_yylval.error_msg = "EOF in string constant";
                    should_tokenize = false;
                    return (ERROR);
                    BEGIN (INITIAL);
                }

<STRING>[\0]   {
                    cool_yylval.error_msg = "String contains null character";
                    curr_line_len = 0;
                    BEGIN (STRING_ERRONEOUS);
                    return (ERROR);
                }

<STRING>[\n]        {
                        cool_yylval.error_msg = "Unterminated string constant";
                        curr_line_len = 0;
                        BEGIN (INITIAL);
                        return (ERROR);
                    }

<STRING>"\\n"  { 
                    if (curr_line_len < MAX_STR_CONST-1)
                    {
                        string_buf[curr_line_len] = '\n';
                        curr_line_len++;
                    }
                    else
                    {
                        cool_yylval.error_msg = "String constant too long";
                        BEGIN (STRING_ERRONEOUS);
                        return (ERROR);
                    }
                }

<STRING>"\\b"  { 
                    if (curr_line_len < MAX_STR_CONST-1)
                    {
                        string_buf[curr_line_len] = '\b';
                        curr_line_len++;
                    }
                    else
                    {
                        cool_yylval.error_msg = "String constant too long";
                        BEGIN (STRING_ERRONEOUS);
                        return (ERROR);
                    }
                }

<STRING>"\\t"  { 
                    if (curr_line_len < MAX_STR_CONST-1)
                    {
                        string_buf[curr_line_len] = '\t';
                        curr_line_len++;
                    }
                    else
                    {
                        cool_yylval.error_msg = "String constant too long";
                        BEGIN (STRING_ERRONEOUS);
                        return (ERROR);
                    }
                }

<STRING>"\\f"  { 
                    if (curr_line_len < MAX_STR_CONST-1)
                    {
                        string_buf[curr_line_len] = '\f';
                        curr_line_len++;
                    }
                    else
                    {
                        cool_yylval.error_msg = "String constant too long";
                        BEGIN (STRING_ERRONEOUS);
                        return (ERROR);
                    }
                }

<STRING>"\\"[^\0]  { 
                        if (curr_line_len < MAX_STR_CONST-1)
                        {
                            string_buf[curr_line_len] = yytext[1];
                            curr_line_len++;
                        }
                        else
                        {
                            cool_yylval.error_msg = "String constant too long";
                            BEGIN (STRING_ERRONEOUS);
                            return (ERROR);
                        }
                    }

<STRING>{STRING_END}    { 
                            BEGIN (INITIAL); 

                            string_buf_ptr = string_buf;
                            cool_yylval.symbol = idtable.add_string (string_buf_ptr, curr_line_len);

                            if (should_tokenize)
                            {
                                curr_line_len = 0;
                                return (STR_CONST);
                            }

                            should_tokenize = true;

                        } 

<STRING>.       { 
                    if (curr_line_len < MAX_STR_CONST-1)
                    {
                        string_buf[curr_line_len] = yytext[0];
                        curr_line_len++;
                    }
                    else
                    {
                        cool_yylval.error_msg = "String constant too long";
                        BEGIN (STRING_ERRONEOUS);
                        return (ERROR);
                    }
                }


<STRING_ERRONEOUS>[\n"] {
                            BEGIN (INITIAL);
                            if (yytext[0] != '\"')
                            {
                                curr_lineno++;
                            }
                        }
<STRING_ERRONEOUS>. {}

 /*
  * End of string stuff
  */

 /*
  * Simple Comments
  */

{SIMPLE_COMMENT_START} { BEGIN(SIMPLE_COMMENT); }

<SIMPLE_COMMENT>[^\n]   {}

<SIMPLE_COMMENT>[\n]  {
                            curr_lineno++;
                            BEGIN (INITIAL);
                        }

<SIMPLE_COMMENT><<EOF>>    {
                                if (!should_tokenize)
                                    yyterminate();

                                cool_yylval.error_msg = "EOF in comment";
                                should_tokenize = false;
                            }

 /*
  * End of simple comments stuff
  */

 /*
  * Nested comments
  */

{NESTED_COMMENT_START}  { 
                            BEGIN (NESTED_COMMENT); 
                            nested_depth++;
                        }

<NESTED_COMMENT>[\n] { curr_lineno++; }

<NESTED_COMMENT>{NESTED_COMMENT_START} {nested_depth++;}
<NESTED_COMMENT>{NESTED_COMMENT_END}    {
                                            if (--nested_depth <= 0)
                                                BEGIN (INITIAL);
                                        }
<NESTED_COMMENT><<EOF>>     {
                                if (!should_tokenize)
                                    yyterminate();

                                cool_yylval.error_msg = "EOF in comment";                                
                                should_tokenize = false;

                                return (ERROR);
                            }

<NESTED_COMMENT>. {}                            

{NESTED_COMMENT_END}    { 
                            cool_yylval.error_msg = "Unmatched *)"; 
                            return (ERROR);    
                        }
 /*
  * End of Nested comments
  */

 /*
  * Symbols
  */
"+"     { return '+'; }
"-"     { return '-'; }
"*"     { return '*'; }
"/"     { return '/'; }
"~"     { return '~'; }
"<"     { return '<'; }
"="     { return '='; }
"("     { return '('; }
")"     { return ')'; }
"."     { return '.'; }
"@"     { return '@'; }
";"     { return ';'; }
":"     { return ':'; }
","     { return ','; }
"{"     { return '{'; }
"}"     { return '}'; }
 /*
  * Objects
  */
{TYPEID}    {
                cool_yylval.symbol = idtable.add_string (yytext);
                return   (TYPEID); 
            }

{OBJECTID}  { 
                cool_yylval.symbol = idtable.add_string (yytext);
                return (OBJECTID); 
            }

 /*
  * Numbers
  */

{INTEGER}   {
                cool_yylval.symbol = inttable.add_string (yytext);
                return (INT_CONST);
            }

 /*
  * Whitespace
  */

{WHITESPACE}+ {}

\n { curr_lineno++; }

{ERROR} { 
            cool_yylval.error_msg = yytext;
            return ERROR;
        }

%%
