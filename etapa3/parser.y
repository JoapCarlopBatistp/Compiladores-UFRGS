%{
//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asd.h"
#include "valor_token.h"

int yylex(void);
void yyerror (char const *mensagem);
extern int get_line_number();

extern asd_tree_t *arvore;
%}

%code requires {
    #include "valor_token.h"
    #include "asd.h"
}

%union {
 	asd_tree_t *no;
 	valor_t *valor_lexico;
}

%define parse.error verbose

%token TK_TIPO        // "tipo"
%token TK_VAR         // "var"
%token TK_SENAO       // "senao"
//%token TK_DECIMAL     // "decimal"
%token TK_SE          // "se"
//%token TK_INTEIRO     // "inteiro"
%token TK_ATRIB       // ":="
%token TK_RETORNA     // "retorna"
%token TK_SETA        // "->"
%token TK_ENQUANTO    // "enquanto"
%token TK_COM         // "com"
%token TK_OC_LE       // "<="
%token TK_OC_GE       // ">="
%token TK_OC_EQ       // "=="
%token TK_OC_NE       // "!="
//%token TK_ID          // identificador
//%token TK_LI_INTEIRO  // literal inteiro
//%token TK_LI_DECIMAL  // literal decimal
%token TK_ER          // erro léxico

//Tipos nós da árvore

%type<no> programa
%type<no> lista
%type<no> elemento
%type<no> declaracao_variavel_global
%type<no> tipo
%type<no> definicao_funcao
%type<no> corpo
%type<no> cabecalho
%type<no> lista_parametros
%type<no> lista_parametros_opcionais
%type<no> parametro
%type<no> comando_simples
%type<no> bloco_comando
%type<no> sequencia_comando_simples
%type<no> declaracao_variavel_local
%type<no> comando_atribuicao
%type<no> chamada_funcao
%type<no> argumentos
%type<no> argumento
%type<no> comando_retorno
%type<no> construcao_fluxo_controle
%type<no> construcao_condicional
%type<no> construcao_iterativa
%type<no> expressao
%type<no> expressao_or
%type<no> expressao_and
%type<no> expressao_igual_desigual
%type<no> expressao_relacional
%type<no> expressao_soma_subtracao
%type<no> expressao_mult_div_mod
%type<no> expressao_unitario
%type<no> expressao_pos_fixado
%type<no> expressao_primario
%type<no> literal

//Tipo valor_lexico

%token<valor_lexico> TK_ID
%token<valor_lexico> TK_LI_INTEIRO
%token<valor_lexico> TK_LI_DECIMAL
%token<valor_lexico> TK_DECIMAL
%token<valor_lexico> TK_INTEIRO

%%

// Deve-se realizar a remoção de conflitos Reduce/Reduce e Shift/Reduce de todas as regras
// gramaticais. Estes conflitos devem ser resolvidos através da reescrita da gramática de 
// maneira a evitá-los.

// A LINGUAGEM
// Um programa na linguagem é composto por uma lista opcional de elementos. Os elementos da lista
// são separados pelo operador vírgula e a lista é terminada pelo operador ponto-e-vírgula.
// Cada elemento dessa lista é ou uma definição de função ou uma declaração de variável.

programa: %empty {arvore = NULL;} 					//Caso do programa vazio
		| lista ';'{arvore = $1;};					//Primeiro elemento

lista: %empty {$$ = NULL;}									//Obs: verificar o que fazer nesse caso
	 | elemento {$$ = $1;}
	 | elemento ',' lista {
		if($1 != NULL){								//Caso o primeiro elemento não foi vazio cai no caso de lista
			$$ = $1;
			if($3 != NULL){							//Se há elemento na lista
				asd_add_child($$, $3);				//Cria o filho
			}
		}
		else {$$ = $3;}								//Se primeiro elemento for vazio cai no caso de elemento
	};


elemento: declaracao_variavel_global {if($1 != NULL) asd_free($1); $$ = NULL;}
		| definicao_funcao {$$ = $1;};

// DECLARAÇÃO DE VARIÁVEL GLOBAL
// Esta declaração é idêntica ao comando simples de declaração de variável que 
// consiste no token TK_VAR seguido do token TK_ID, que é por sua vez seguido do token TK_ATRIB e 
// enfim seguido do tipo. O tipo pode ser ou o token TK_DECIMAL ou o token TK_INTEIRO.
// A única e importante diferença é que esse elemento não pode receber valores de inicialização.

declaracao_variavel_global: TK_VAR TK_ID TK_ATRIB tipo{
	$$ = asd_new($2->lexema);
	free($2->lexema);
    if ($4 != NULL) asd_free($4); 
	free($2);
}; 

tipo: TK_DECIMAL {$$ = NULL;}       
 	| TK_INTEIRO {$$ = NULL;};		

// DEFINIÇÃO DE FUNÇÃO
// Ela possui um cabeçalho e um corpo. O cabeçalho consiste no token TK_ID
// seguido do token TK_SETA seguido ou do token TK_DECIMAL ou do token TK_INTEIRO, seguido
// por uma lista opcional de parâmetros seguido do token TK_ATRIB. A lista de parâmetros, quando
// presente, consiste no token opcional TK_COM seguido de uma lista, separada por vírgula, de parâmetros.
// Cada parâmetro consiste no token TK_ID seguido do token TK_ATRIB seguido ou do token TK_INTEIRO 
// ou do token TK_DECIMAL. O corpo de uma função é um bloco de comandos

definicao_funcao: cabecalho corpo {
	$$ = $1;						//Cabeçalho
    if ($2 != NULL) {				//Se corpo não for nulo
        asd_add_child($1, $2);    
    }
};

cabecalho: TK_ID TK_SETA tipo lista_parametros_opcionais TK_ATRIB {
	$$ = asd_new($1->lexema); 
    if ($3 != NULL) asd_free($3);
    if ($4 != NULL) asd_free($4);
	free($1->lexema);
    free($1);
};
corpo: bloco_comando {$$ = $1;};

lista_parametros_opcionais: %empty {$$ = NULL;}
						  | lista_parametros {$$ = $1;}
						  | TK_COM lista_parametros {$$ = $2;};

lista_parametros: parametro {$$ = $1;}
				| parametro ',' lista_parametros {
					 if ($1 != NULL) {
        				asd_add_child($1, $3); 
        				$$ = $1; // Propaga a cabeça da lista
    				} else {
        				$$ = $3;
    				}
				};

parametro: TK_ID TK_ATRIB tipo{
	free($1->lexema);
	free($1);
	if ($3 != NULL) asd_free($3);
    $$ = NULL;
};

// COMANDOS SIMPLES:
// Os comandos simples da linguagem podem ser: bloco de comandos, declaração de variável,
// comando de atribuição, chamada de função, comando de retorno, e construções de fluxo de controle.

comando_simples: bloco_comando {$$ = $1;}
			   | declaracao_variavel_local {$$ = $1;}
			   | comando_atribuicao {$$ = $1;}
			   | chamada_funcao {$$ = $1;}
			   | comando_retorno {$$ = $1;}
			   | construcao_fluxo_controle {$$ = $1;};

// BLOCO DE COMANDO
// Definido entre colchetes, e consiste em uma sequência, possivelmente vazia, de comandos simples.
// Um bloco de comandos é considerado como um comando único simples e pode ser utilizado em qualquer
// construção que aceite um comando simples.

bloco_comando: '[' sequencia_comando_simples ']' {$$ = $2;}; //Apenas a sequencia de comando simples

sequencia_comando_simples: %empty {$$ = NULL;}
						 | comando_simples sequencia_comando_simples {
							if ($1 != NULL){					//Se sequencia não for nula
								$$ = $1;						//Sequencia comando simples
								if ($2 != NULL) {				//Se comando simples não for nulo
									asd_add_child($$, $2);		//Adiciona filho
								}
							}
							else {$$ = $2;}						//Se sequencia for nula vai para o caso do comando simples
						 };

// DECLARAÇÃO DE VARIÁVEL LOCAL
// Consiste no token TK_VAR seguido do token TK_ID, que é por sua vez seguido do token TK_ATRIB e 
// enfim seguido do tipo. O tipo pode ser ou o token TK_DECIMAL ou o token TK_INTEIRO. Uma variável
// pode ser opcionalmente inicializada caso sua declaração seja seguida do token TK_COM e de um literal.
// Um literal pode ser ou o token TK_LI_INTEIRO ou o token TK_LI_DECIMAL.

declaracao_variavel_local: declaracao_variavel_global{asd_free($1); $$ = NULL;}
			| declaracao_variavel_global TK_COM literal{
				$$ = asd_new("com"); 
            	asd_add_child($$, $1);
            	asd_add_child($$, $3);
			};

literal: TK_LI_INTEIRO {$$ = asd_new($1->lexema); free($1->lexema); free($1);}; //Lexema do literal no rótulo + associação do valor lexico
literal: TK_LI_DECIMAL {$$ = asd_new($1->lexema); free($1->lexema); free($1);};

// COMANDO DE ATRIBUIÇÃO
// O comando de atribuição consiste em um token TK_ID, seguido do token TK_ATRIB e enfim seguido por
// uma expressão.

comando_atribuicao: TK_ID TK_ATRIB expressao{
	$$ = asd_new(":=");
	asd_tree_t *aux = asd_new($1->lexema);
	free($1->lexema);
	asd_add_child($$, aux); //Filho 1
	asd_add_child($$, $3);  //Filho 2
	//asd_free(aux);
	free($1);
};

// CHAMADA DE FUNÇÃO
// Uma chamada de função consiste no token TK_ID, seguida de argumentos
// entre parênteses, sendo que cada argumento é separado do outro por vírgula. Um argumento é
// uma expressão. Uma chamada de função pode existir sem argumentos.

chamada_funcao: TK_ID '(' argumentos ')'{
	char* node_label = (char*) calloc(strlen($1->lexema)+6, sizeof(char)); //Para o lexema da chamada de função
	if (node_label == NULL) exit(1);
	strncpy(node_label, "call ", 6);										
	strcat(node_label, $1->lexema);
	free($1->lexema);
	$$ = asd_new(node_label);											//Nodo com chamada
	free(node_label);													//free
	if ($3 != NULL) {													//Lista de argumentos se torna filho, se houver
        asd_add_child($$, $3);
    }
	free($1);
};

argumentos: %empty {$$ = NULL;}
		  | argumento {$$ = $1;};
		  | argumento ',' argumentos{
			$$ = $1;
			asd_add_child($$, $3);
		  } 
		  

argumento: expressao {$$ = $1;};

// COMANDO DE RETORNO
// Trata-se do token TK_RETORNA seguido de uma expressão, seguido do token TK_ATRIB
// e terminado ou pelo token TK_DECIMAL ou pelo token TK_INTEIRO.

comando_retorno: TK_RETORNA expressao TK_ATRIB tipo {$$ = asd_new("retorna"); asd_add_child($$, $2); if($4 != NULL) asd_free($4);};

// CONSTRUÇÃO DE CONTROLE DE FLUXO
// A linguagem possui uma construção condicional e uma construção iterativa para controle estruturado de fluxo.

construcao_fluxo_controle: construcao_iterativa {$$ = $1;}
						 | construcao_condicional {$$ = $1;};

// A condicional consiste no token TK_SE seguido de uma expressão entre parênteses e então por um 
// bloco de comandos obrigatório. Após este bloco, podemos opcionalmente ter o token TK_SENAO que,
// quando aparece, é seguido obrigatoriamente por um bloco de comandos.

construcao_condicional: TK_SE '(' expressao ')' bloco_comando {
    // Caso IF simples (sem ELSE)
	$$ = asd_new("se"); // Usa o lexema do TK_SE como nome
	asd_add_child($$, $3); // Expressão (Condição)
	asd_add_child($$, $5); // Bloco THEN
	}
	| TK_SE '(' expressao ')' bloco_comando TK_SENAO bloco_comando{
    // Caso IF-ELSE (com ELSE)
	$$ = asd_new("se"); // Usa o lexema do TK_SE como nome
	asd_add_child($$, $3); // Expressão (Condição)
	asd_add_child($$, $5); // Bloco THEN
	asd_add_child($$, $7); // Bloco ELSE
};

// Temos apenas uma construção de repetição que é o token TK_ENQUANTO seguido de uma expressão entre
// parênteses e de um bloco de comandos.

construcao_iterativa: TK_ENQUANTO '(' expressao ')' bloco_comando{
	$$ = asd_new("enquanto");					//Lexema que o professor pediu
	asd_add_child($$, $3); 					//Caso da expressão
	
	asd_add_child($$, $5); 				//Bloco de comando (não há check de NULL pois o bloco de comando é obrigatóro na gramática)
};

// EXPRESSÃO
// Expressões envolvem operandos e operadores, sendo este opcional. Os operandos podem ser
// identificadores, literais e chamada de função ou outras expressões, podendo portanto ser formadas
// recursivamente pelo emprego de operadores. Elas também permitem o uso de parênteses para forçar
// uma associatividade ou precedência diferente daquela tradicional. A associatividade é à esquerda
// (portanto implemente recursão à esquerda nas regras gramaticais).

// Raiz
expressao: expressao_or {$$ = $1;};

// Nível 7: binário infixado or (|) 
expressao_or: expressao_and '|' expressao_or {$$ = asd_new("|"); asd_add_child($$, $1); asd_add_child($$, $3);}
  			| expressao_and {$$ = $1;};

// Nível 6: binário infixado and (&)
expressao_and: expressao_igual_desigual '&' expressao_and {$$ = asd_new("&"); asd_add_child($$, $1); asd_add_child($$, $3);}
   			 | expressao_igual_desigual {$$ = $1;};

// Nível 5: binário infixados igualdade e desiqualdade (==, !=)
expressao_igual_desigual: expressao_relacional TK_OC_EQ expressao_igual_desigual {$$ = asd_new("=="); asd_add_child($$, $1); asd_add_child($$, $3);}
			  			| expressao_relacional TK_OC_NE expressao_igual_desigual {$$ = asd_new("!="); asd_add_child($$, $1); asd_add_child($$, $3);}
			  			| expressao_relacional {$$ = $1;};

// Nível 4: binário infixados relacionais maior, menor, menor igual e maior igual (<, >, <=, >=)
expressao_relacional: expressao_soma_subtracao '<' expressao_relacional {$$ = asd_new("<"); asd_add_child($$, $1); asd_add_child($$, $3);}
  		  			| expressao_soma_subtracao '>' expressao_relacional {$$ = asd_new(">"); asd_add_child($$, $1); asd_add_child($$, $3);}
  		  			| expressao_soma_subtracao TK_OC_LE  expressao_relacional {$$ = asd_new("<="); asd_add_child($$, $1); asd_add_child($$, $3);}
		  			| expressao_soma_subtracao TK_OC_GE  expressao_relacional {$$ = asd_new(">="); asd_add_child($$, $1); asd_add_child($$, $3);}
  		  			| expressao_soma_subtracao {$$ = $1;};

// Nível 3: binário infixados soma e subtração (associativo à esquerda)
expressao_soma_subtracao: expressao_mult_div_mod '+' expressao_soma_subtracao {$$ = asd_new("+"); asd_add_child($$, $1); asd_add_child($$, $3);}
  			  			| expressao_mult_div_mod '-' expressao_soma_subtracao {$$ = asd_new("-"); asd_add_child($$, $1); asd_add_child($$, $3);}
  			  			| expressao_mult_div_mod {$$ = $1;};

// Nível 2: binário infixados multiplicação, divisão e mod (associativo à esquerda)
expressao_mult_div_mod: expressao_unitario '*' expressao_mult_div_mod {$$ = asd_new("*"); asd_add_child($$, $1); asd_add_child($$, $3);}
  					  | expressao_unitario '/' expressao_mult_div_mod {$$ = asd_new("/"); asd_add_child($$, $1); asd_add_child($$, $3);}
  					  | expressao_unitario '%' expressao_mult_div_mod {$$ = asd_new("%"); asd_add_child($$, $1); asd_add_child($$, $3);}
  					  | expressao_unitario {$$ = $1;};

// Nível 1: unários pré-fixados soma, subtração e negação (+, -, !) (associação natural à direita - liguangem C)
expressao_unitario: '+' expressao_unitario {$$ = asd_new("+"); asd_add_child($$, $2);}
  				  | '-' expressao_unitario {$$ = asd_new("-"); asd_add_child($$, $2);}
  				  | '!' expressao_unitario {$$ = asd_new("!"); asd_add_child($$, $2);}
  				  | expressao_pos_fixado {$$ = $1;};

// Nível 0: pós-fixados primários e chamada de função
expressao_pos_fixado: expressao_primario {$$ = $1;}
  		             | chamada_funcao {$$ = $1;};

// primários: identificadores, literais e parênteses
expressao_primario: TK_ID {$$ = asd_new($1->lexema); free($1->lexema); free($1);}
  		 		   | literal {$$ = $1;}
  		 		   | '(' expressao ')'{$$ = $2;};
%%

void yyerror (char const *mensagem)
{
	printf("[ERRO]\nNa linha %d, com mensagem:\n%s\n", get_line_number(), mensagem);
}