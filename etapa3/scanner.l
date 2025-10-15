
%{
//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS


//Espaço reservado para código C
#include "parser.tab.h"
#include "valor_token.h"
#include "asd.h"

valor_t* alocar_valor(tipo_token_t type);
%}

%option noyywrap yylineno nounput noinput

%%
    //ESpaço reservado para Expressões Regulares
\/\/.*\n                                        //Isso ignora duas barras até um \n (quebra de linha). .* é o fechamento de kleene dos próximos valores.
[ \t\r\n]                                       //Ignora todo tipo de espaço e o \n

[0-9]+ 	{                						//Exige pelo menos 1 valor seguido de n digitos
    yylval.valor_lexico = alocar_valor(LITERAL); return TK_LI_INTEIRO;  //yylval é var global para passar os valores de token para o bison
}
[0-9]*\.[0-9]+ {        						//Primeiro inteiro é opcional (fechamento de kleene). Dígitos após a vírgula são obrigatórios (pelo menos 1)
    yylval.valor_lexico = alocar_valor(LITERAL); return TK_LI_DECIMAL;  //yylval é var global para passar os valores de token para o bison
}

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

[a-z_][a-z0-9_]* {                					//Token de Identificador (minusculos, digitos e underline)
    yylval.valor_lexico = alocar_valor(IDENTIFICADOR); 
	return TK_ID; //yylval é var global para passar os valores de token para o bison
}

. return TK_ER;                                 //Retorna erro caso alguma cadeia que não está na linguagem apareça

%% //Espaço reservado para funções

int get_line_number(void){                      //Função que retorna o numero da linha
	return yylineno;
}

valor_t* alocar_valor(tipo_token_t type){       //Função que dá malloc para os structs de valores de token
 	valor_t *aux = NULL;                                //Cria a variável e inicializa ela em NULL
 	
 	aux = (valor_t*) malloc (sizeof(valor_t));          //Aloca o valor na memória (lembrar de dar free)
 	if (aux == NULL){                                   //Checa se houve alocação
  		exit(1);                                        //Caso memória não alocada dá exit
 	}
 	
 	aux->linha_token = get_line_number();                      //Valor inteiro da linha é colocado no struct de valor do token
 	aux->tipo = type;                                   //Valor token_type_t é colocado no struct de valor do token
 	aux->lexema = strdup(yytext);                       //Lexema do struct de valor do token recebe o strdup
 	if (aux->lexema == NULL){                           //Checa se foi bem sucedido
  		exit(1);                                        //Caso não alocado dá exit
 	}
 	
 	return aux;                                         //Retorna o struct auxilixar com todos os valores preenchidos
}