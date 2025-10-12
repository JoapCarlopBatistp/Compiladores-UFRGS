
%{
//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS


//Espaço reservado para código C
#include "parser.tab.h"
%}

%option noyywrap yylineno

%%
    //ESpaço reservado para Expressões Regulares
\/\/.*\n                                        //Isso ignora duas barras até um \n (quebra de linha). .* é o fechamento de kleene dos próximos valores.
[ \t\r\n]                                       //Ignora todo tipo de espaço e o \n

[0-9]+ {return TK_LI_INTEIRO;}                  //Exige pelo menos 1 valor seguido de n digitos
[0-9]*\.[0-9]+ {return TK_LI_DECIMAL;}          //Primeiro inteiro é opcional (fechamento de kleene). Dígitos após a vírgula são obrigatórios (pelo menos 1)


tipo return TK_TIPO;                            //Tipo
var return TK_VAR;                              //Var
senao return TK_SENAO;                          //Senão
decimal return TK_DECIMAL;                      //Decimal
se return TK_SE;                                //Se
inteiro return TK_INTEIRO;                      //Inteiro
retorna return TK_RETORNA;                      //Retorna
enquanto return TK_ENQUANTO;                    //Enquanto
com return TK_COM;                              //Com

[!*\/%\+\-\>\<\[\]\(\)=,;&\|] return yytext[0];  //Retorna o decimal de cada um dos caracteres do afabeto listado



"<=" return TK_OC_LE;                            //Menor igual
">=" return TK_OC_GE;                             //Maior igual
"==" return TK_OC_EQ;                             //Igual
"!=" return TK_OC_NE;                             //Diferente
":=" return TK_ATRIB;                             //Atribuição
"->" return TK_SETA;                              //Seta

[a-z_][a-z0-9_]* return TK_ID;                  //Token de Identificador (minusculos, digitos e underline)

. return TK_ER;                                 //Retorna erro caso alguma cadeia que não está na linguagem apareça

%% //Espaço reservado para funções

int get_line_number(void){                      //Função que retorna o numero da linha
	return yylineno;
}