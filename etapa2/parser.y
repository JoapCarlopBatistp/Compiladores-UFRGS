%{
#include <stdio.h>
int yylex(void);
void yyerror (char const *mensagem);
%}

%token TK_TIPO
%token TK_VAR
%token TK_SENAO
%token TK_DECIMAL
%token TK_SE
%token TK_INTEIRO
%token TK_ATRIB
%token TK_RETORNA
%token TK_SETA
%token TK_ENQUANTO
%token TK_COM
%token TK_OC_LE
%token TK_OC_GE
%token TK_OC_EQ
%token TK_OC_NE
%token TK_ID
%token TK_LI_INTEIRO
%token TK_LI_DECIMAL
%token TK_ER

%%
//Definição de Programa



//Definição de Função



//Outras definições posteriores


%%

void yyerror (char const *mensagem)
{
	printf("[ERRO]\nNa linha %d, com mensagem:\n%s\n", get_line_number(), mensagem);
}