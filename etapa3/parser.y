%{
//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS
#include <stdio.h>
int yylex(void);
void yyerror (char const *mensagem);
extern int get_line_number();
%}

%define parse.error verbose

%token TK_TIPO        // "tipo"
%token TK_VAR         // "var"
%token TK_SENAO       // "senao"
%token TK_DECIMAL     // "decimal"
%token TK_SE          // "se"
%token TK_INTEIRO     // "inteiro"
%token TK_ATRIB       // ":="
%token TK_RETORNA     // "retorna"
%token TK_SETA        // "->"
%token TK_ENQUANTO    // "enquanto"
%token TK_COM         // "com"
%token TK_OC_LE       // "<="
%token TK_OC_GE       // ">="
%token TK_OC_EQ       // "=="
%token TK_OC_NE       // "!="
%token TK_ID          // identificador
%token TK_LI_INTEIRO  // literal inteiro
%token TK_LI_DECIMAL  // literal decimal
%token TK_ER          // erro léxico

%%

// Deve-se realizar a remoção de conflitos Reduce/Reduce e Shift/Reduce de todas as regras
// gramaticais. Estes conflitos devem ser resolvidos através da reescrita da gramática de 
// maneira a evitá-los.

// A LINGUAGEM
// Um programa na linguagem é composto por uma lista opcional de elementos. Os elementos da lista
// são separados pelo operador vírgula e a lista é terminada pelo operador ponto-e-vírgula.
// Cada elemento dessa lista é ou uma definição de função ou uma declaração de variável.

programa: %empty
		| lista ';';

lista: %empty
	 | elemento
	 | lista ',' elemento;

elemento: declaracao_variavel_global
		| definicao_funcao;

// DECLARAÇÃO DE VARIÁVEL GLOBAL
// Esta declaração é idêntica ao comando simples de declaração de variável que 
// consiste no token TK_VAR seguido do token TK_ID, que é por sua vez seguido do token TK_ATRIB e 
// enfim seguido do tipo. O tipo pode ser ou o token TK_DECIMAL ou o token TK_INTEIRO.
// A única e importante diferença é que esse elemento não pode receber valores de inicialização.

declaracao_variavel_global: TK_VAR TK_ID TK_ATRIB tipo;

tipo: TK_DECIMAL
 	| TK_INTEIRO;

// DEFINIÇÃO DE FUNÇÃO
// Ela possui um cabeçalho e um corpo. O cabeçalho consiste no token TK_ID
// seguido do token TK_SETA seguido ou do token TK_DECIMAL ou do token TK_INTEIRO, seguido
// por uma lista opcional de parâmetros seguido do token TK_ATRIB. A lista de parâmetros, quando
// presente, consiste no token opcional TK_COM seguido de uma lista, separada por vírgula, de parâmetros.
// Cada parâmetro consiste no token TK_ID seguido do token TK_ATRIB seguido ou do token TK_INTEIRO 
// ou do token TK_DECIMAL. O corpo de uma função é um bloco de comandos

definicao_funcao: cabecalho corpo;

cabecalho: TK_ID TK_SETA tipo lista_parametros_opcionais TK_ATRIB;
corpo: bloco_comando;

lista_parametros_opcionais: %empty
						  | lista_parametros
						  | TK_COM lista_parametros;

lista_parametros: parametro
				| lista_parametros ',' parametro;

parametro: TK_ID TK_ATRIB tipo;

// COMANDOS SIMPLES:
// Os comandos simples da linguagem podem ser: bloco de comandos, declaração de variável,
// comando de atribuição, chamada de função, comando de retorno, e construções de fluxo de controle.

comando_simples: bloco_comando
			   | declaracao_variavel_local
			   | comando_atribuicao
			   | chamada_funcao
			   | comando_retorno
			   | construcao_fluxo_controle;

// BLOCO DE COMANDO
// Definido entre colchetes, e consiste em uma sequência, possivelmente vazia, de comandos simples.
// Um bloco de comandos é considerado como um comando único simples e pode ser utilizado em qualquer
// construção que aceite um comando simples.

bloco_comando: '[' sequencia_comando_simples ']';

sequencia_comando_simples: %empty
						 | sequencia_comando_simples comando_simples;

// DECLARAÇÃO DE VARIÁVEL LOCAL
// Consiste no token TK_VAR seguido do token TK_ID, que é por sua vez seguido do token TK_ATRIB e 
// enfim seguido do tipo. O tipo pode ser ou o token TK_DECIMAL ou o token TK_INTEIRO. Uma variável
// pode ser opcionalmente inicializada caso sua declaração seja seguida do token TK_COM e de um literal.
// Um literal pode ser ou o token TK_LI_INTEIRO ou o token TK_LI_DECIMAL.

declaracao_variavel_local: TK_VAR TK_ID TK_ATRIB tipo inicializacao;

inicializacao: %empty
			 | TK_COM literal;

literal: TK_LI_INTEIRO;
literal: TK_LI_DECIMAL;

// COMANDO DE ATRIBUIÇÃO
// O comando de atribuição consiste em um token TK_ID, seguido do token TK_ATRIB e enfim seguido por
// uma expressão.

comando_atribuicao: TK_ID TK_ATRIB expressao;

// CHAMADA DE FUNÇÃO
// Uma chamada de função consiste no token TK_ID, seguida de argumentos
// entre parênteses, sendo que cada argumento é separado do outro por vírgula. Um argumento é
// uma expressão. Uma chamada de função pode existir sem argumentos.

chamada_funcao: TK_ID '(' argumentos ')';

argumentos: %empty
		  | argumentos ',' argumento
		  | argumento;

argumento: expressao;

// COMANDO DE RETORNO
// Trata-se do token TK_RETORNA seguido de uma expressão, seguido do token TK_ATRIB
// e terminado ou pelo token TK_DECIMAL ou pelo token TK_INTEIRO.

comando_retorno: TK_RETORNA expressao TK_ATRIB tipo;

// CONSTRUÇÃO DE CONTROLE DE FLUXO
// A linguagem possui uma construção condicional e uma construção iterativa para controle estruturado de fluxo.

construcao_fluxo_controle: construcao_iterativa
						 | construcao_condicional;

// A condicional consiste no token TK_SE seguido de uma expressão entre parênteses e então por um 
// bloco de comandos obrigatório. Após este bloco, podemos opcionalmente ter o token TK_SENAO que,
// quando aparece, é seguido obrigatoriamente por um bloco de comandos.

construcao_condicional: TK_SE '(' expressao ')' bloco_comando bloco_comando_opcional;

bloco_comando_opcional: %empty
					  | TK_SENAO bloco_comando;

// Temos apenas uma construção de repetição que é o token TK_ENQUANTO seguido de uma expressão entre
// parênteses e de um bloco de comandos.

construcao_iterativa: TK_ENQUANTO '(' expressao ')' bloco_comando;

// EXPRESSÃO
// Expressões envolvem operandos e operadores, sendo este opcional. Os operandos podem ser
// identificadores, literais e chamada de função ou outras expressões, podendo portanto ser formadas
// recursivamente pelo emprego de operadores. Elas também permitem o uso de parênteses para forçar
// uma associatividade ou precedência diferente daquela tradicional. A associatividade é à esquerda
// (portanto implemente recursão à esquerda nas regras gramaticais).

// Raiz
expressao: expressao_or;

// Nível 7: binário infixado or (|) 
expressao_or: expressao_or '|' expressao_and
  			| expressao_and;

// Nível 6: binário infixado and (&)
expressao_and: expressao_and '&' expressao_igual_desigual
   			 | expressao_igual_desigual;

// Nível 5: binário infixados igualdade e desiqualdade (==, !=)
expressao_igual_desigual: expressao_igual_desigual TK_OC_EQ expressao_relacional
			  			| expressao_igual_desigual TK_OC_NE expressao_relacional
			  			| expressao_relacional;

// Nível 4: binário infixados relacionais maior, menor, menor igual e maior igual (<, >, <=, >=)
expressao_relacional: expressao_relacional '<' expressao_soma_subtracao
  		  			| expressao_relacional '>' expressao_soma_subtracao
  		  			| expressao_relacional TK_OC_LE  expressao_soma_subtracao
		  			| expressao_relacional TK_OC_GE  expressao_soma_subtracao
  		  			| expressao_soma_subtracao;

// Nível 3: binário infixados soma e subtração (associativo à esquerda)
expressao_soma_subtracao: expressao_soma_subtracao '+' expressao_mult_div_mod
  			  			| expressao_soma_subtracao '-' expressao_mult_div_mod
  			  			| expressao_mult_div_mod;

// Nível 2: binário infixados multiplicação, divisão e mod (associativo à esquerda)
expressao_mult_div_mod: expressao_mult_div_mod '*' expressao_unitario
  					  | expressao_mult_div_mod '/' expressao_unitario
  					  | expressao_mult_div_mod '%' expressao_unitario
  					  | expressao_unitario;

// Nível 1: unários pré-fixados soma, subtração e negação (+, -, !) (associação natural à direita - liguangem C)
expressao_unitario: '+' expressao_unitario
  				  | '-' expressao_unitario
  				  | '!' expressao_unitario
  				  | expressao_pos_fixado;

// Nível 0: pós-fixados primários e chamada de função
expressao_pos_fixado: expressao_primario
  		             | chamada_funcao;

// primários: identificadores, literais e parênteses
expressao_primario: TK_ID
  		 		   | literal
  		 		   | '(' expressao ')';
%%

void yyerror (char const *mensagem)
{
	printf("[ERRO]\nNa linha %d, com mensagem:\n%s\n", get_line_number(), mensagem);
}