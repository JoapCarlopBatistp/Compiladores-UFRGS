%{
//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asd.h"
#include "valor_token.h"
#include "tabela_simbolos.h"
#include "errors.h"
#include "semantica.h"

int yylex(void);
void yyerror (char const *mensagem);
extern int get_line_number();

extern asd_tree_t *arvore;

// Pilha de tabelas de símbolos (escopo)
extern tabela_simbolos_t *pilha_tabelas;

// ======= Funções auxiliares declaradas =======
%}

%code requires {
    #include "valor_token.h"
    #include "asd.h"
    #include "tabela_simbolos.h"
    #include "semantica.h"
}

%union {
  asd_tree_t *no;
 	valor_t *valor_lexico;
  tipo_dado_t tipo;
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

// Tipo semântico dos nós
%type<no> programa
%type<no> lista
%type<no> elemento
%type<no> declaracao_variavel_global
%type<tipo> tipo
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

// valor_lexico vindo do scanner
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

programa: %empty { arvore = NULL; } // Caso do programa vazio
        | lista ';' { arvore = $1; };

lista
  : %empty               { $$ = NULL; } // Obs: verificar o que fazer nesse caso
  | elemento             { $$ = $1; }
  | elemento ',' lista
    {
        if ($1 != NULL) {
            $$ = $1;
            if ($3 != NULL) {
                asd_add_child($$, $3);
            }
        } else {
            $$ = $3;
        }
    }
  ;

elemento
  : declaracao_variavel_global { if ($1 != NULL) asd_free($1); $$ = NULL; }
  | definicao_funcao           { $$ = $1; }
  ;

// DECLARAÇÃO DE VARIÁVEL GLOBAL
// Esta declaração é idêntica ao comando simples de declaração de variável que 
// consiste no token TK_VAR seguido do token TK_ID, que é por sua vez seguido do token TK_ATRIB e 
// enfim seguido do tipo. O tipo pode ser ou o token TK_DECIMAL ou o token TK_INTEIRO.
// A única e importante diferença é que esse elemento não pode receber valores de inicialização.

declaracao_variavel_global
  : TK_VAR TK_ID TK_ATRIB tipo
    {
        valor_t *token_identificador = $2;
        tipo_dado_t tipo_declarado = $4;
        verificar_semantica_variavel_global(pilha_tabelas, token_identificador, get_line_number());
        declarar_variavel_global(pilha_tabelas, token_identificador, tipo_declarado, get_line_number());
        
        $$ = NULL;
        free(token_identificador->lexema);
        free(token_identificador);
    }
  ;

tipo
  : TK_DECIMAL { $$ = TIPO_FLOAT; }
  | TK_INTEIRO { $$ = TIPO_INT;   }
  ;

// DEFINIÇÃO DE FUNÇÃO
// Ela possui um cabeçalho e um corpo. O cabeçalho consiste no token TK_ID
// seguido do token TK_SETA seguido ou do token TK_DECIMAL ou do token TK_INTEIRO, seguido
// por uma lista opcional de parâmetros seguido do token TK_ATRIB. A lista de parâmetros, quando
// presente, consiste no token opcional TK_COM seguido de uma lista, separada por vírgula, de parâmetros.
// Cada parâmetro consiste no token TK_ID seguido do token TK_ATRIB seguido ou do token TK_INTEIRO 
// ou do token TK_DECIMAL. O corpo de uma função é um bloco de comandos

definicao_funcao
  : cabecalho corpo
    {
        $$ = $1;                       // Cabeçalho
        if ($2 != NULL) {
            asd_add_child($1, $2);
        }
        // fecha escopo da função
        desempilhar_tabela(&pilha_tabelas);
    }
  ;

cabecalho
  : TK_ID TK_SETA tipo
    {
        // Declara a função no escopo corrente e abre escopo para parâmetros
      if (buscar_simbolo_escopo_atual(pilha_tabelas, $1->lexema) != NULL) {
          fprintf(stderr,
                  "ERRO SEMÂNTICO [%s %d] linha %d: função '%s' já foi declarada.\n",
                  semantica_nome_erro(ERR_DECLARED), ERR_DECLARED, get_line_number(), $1->lexema);
          exit(ERR_DECLARED);
      }
      entrada_tabela_t *funcao = declarar_funcao(pilha_tabelas, $1, $3, get_line_number());
      empilhar_tabela(&pilha_tabelas);
      pilha_tabelas->funcao = funcao;
    }
    lista_parametros_opcionais TK_ATRIB
    {
      $$ = asd_new($1->lexema);
      free($1->lexema);
      free($1);
    }
  ;


corpo
  : bloco_comando { $$ = $1; }
  ;

lista_parametros_opcionais
  : %empty            { $$ = NULL; }
  | lista_parametros  { $$ = $1; }
  | TK_COM lista_parametros { $$ = $2; }
  ;

lista_parametros
  : parametro                         { $$ = $1; }
  | parametro ',' lista_parametros
    {
        if ($1 != NULL) {
            asd_add_child($1, $3);
            $$ = $1;
        } else {
            $$ = $3;
        }
    }
  ;

parametro
  : TK_ID TK_ATRIB tipo
    {
        valor_t *token_parametro = $1;
        tipo_dado_t tipo_parametro = $3;
        entrada_tabela_t *funcao_contexto = pilha_tabelas ? pilha_tabelas->funcao : NULL;

        verificar_semantica_parametro(funcao_contexto, get_line_number());
        adicionar_parametro_funcao(funcao_contexto, tipo_parametro);
        verificar_semantica_variavel_local(pilha_tabelas, token_parametro, get_line_number());
        declarar_variavel_local(pilha_tabelas, token_parametro, tipo_parametro, get_line_number());
        
        free(token_parametro->lexema);
        free(token_parametro);
        $$ = NULL;
    }
  ;

// COMANDOS SIMPLES:
// Os comandos simples da linguagem podem ser: bloco de comandos, declaração de variável,
// comando de atribuição, chamada de função, comando de retorno, e construções de fluxo de controle.

comando_simples
  : bloco_comando          { $$ = $1; }
  | declaracao_variavel_local { $$ = $1; }
  | comando_atribuicao     { $$ = $1; }
  | chamada_funcao         { $$ = $1; }
  | comando_retorno        { $$ = $1; }
  | construcao_fluxo_controle { $$ = $1; }
  ;

// BLOCO DE COMANDO
// Definido entre colchetes, e consiste em uma sequência, possivelmente vazia, de comandos simples.
// Um bloco de comandos é considerado como um comando único simples e pode ser utilizado em qualquer
// construção que aceite um comando simples.

bloco_comando
  : '[' { empilhar_tabela(&pilha_tabelas); }
    sequencia_comando_simples
    ']' { $$ = $3; desempilhar_tabela(&pilha_tabelas); }
  ; // escopo de bloco

sequencia_comando_simples
  : %empty { $$ = NULL; }
  | comando_simples sequencia_comando_simples
    {
        if ($1 != NULL) {
            $$ = $1;
            if ($2 != NULL) {
                asd_add_child($$, $2);
            }
        } else {
            $$ = $2;
        }
    }
  ;

// DECLARAÇÃO DE VARIÁVEL LOCAL
// Consiste no token TK_VAR seguido do token TK_ID, que é por sua vez seguido do token TK_ATRIB e 
// enfim seguido do tipo. O tipo pode ser ou o token TK_DECIMAL ou o token TK_INTEIRO. Uma variável
// pode ser opcionalmente inicializada caso sua declaração seja seguida do token TK_COM e de um literal.
// Um literal pode ser ou o token TK_LI_INTEIRO ou o token TK_LI_DECIMAL.

declaracao_variavel_local
  : TK_VAR TK_ID TK_ATRIB tipo
    {
        valor_t *token_identificador = $2;
        tipo_dado_t tipo_declarado = $4;
        verificar_semantica_variavel_local(pilha_tabelas, token_identificador, get_line_number());
        declarar_variavel_local(pilha_tabelas, token_identificador, tipo_declarado, get_line_number());
        $$ = NULL;
        free(token_identificador->lexema);
        free(token_identificador);
    }
  | TK_VAR TK_ID TK_ATRIB tipo TK_COM literal
    {
        valor_t *token_identificador = $2;
        tipo_dado_t tipo_declarado = $4;
        asd_tree_t *no_literal = $6;

        verificar_semantica_variavel_local(pilha_tabelas, token_identificador, get_line_number());
        verificar_semantica_inicializacao_variavel_local(no_literal, token_identificador, tipo_declarado, get_line_number());
        declarar_variavel_local(pilha_tabelas, token_identificador, tipo_declarado, get_line_number());
        
        $$ = asd_new("com");
        asd_tree_t *no_identificador = asd_new(token_identificador->lexema);
        no_identificador->tipo = tipo_declarado;
        asd_add_child($$, no_identificador);
        asd_add_child($$, no_literal);
        $$->tipo = tipo_declarado;
        free(token_identificador->lexema);
        free(token_identificador);
    }
  ;

literal
  : TK_LI_INTEIRO
    {
        valor_t *token_literal = $1;
        registrar_literal(pilha_tabelas, token_literal, TIPO_INT);
        $$ = asd_new(token_literal->lexema);
        $$->tipo = TIPO_INT;
        free(token_literal->lexema);
        free(token_literal);
    }
  | TK_LI_DECIMAL
    {
        valor_t *token_literal = $1;
        registrar_literal(pilha_tabelas, token_literal, TIPO_FLOAT);
        $$ = asd_new(token_literal->lexema);
        $$->tipo = TIPO_FLOAT;
        free(token_literal->lexema);
        free(token_literal);
    }
  ;

// COMANDO DE ATRIBUIÇÃO
// O comando de atribuição consiste em um token TK_ID, seguido do token TK_ATRIB e enfim seguido por
// uma expressão.

comando_atribuicao
  : TK_ID TK_ATRIB expressao
    {
        valor_t *token_identificador = $1;
        asd_tree_t *no_expressao = $3;

        verificar_declaracao_identificador(pilha_tabelas, token_identificador->lexema, get_line_number());
        entrada_tabela_t *entrada_simbolo = buscar_simbolo(pilha_tabelas, token_identificador->lexema);
        verificar_semantica_atribuicao(entrada_simbolo, no_expressao, get_line_number());
        
        $$ = asd_new(":=");
        asd_tree_t *no_lado_esquerdo = asd_new(token_identificador->lexema);
        no_lado_esquerdo->tipo = entrada_simbolo->tipo;
        asd_add_child($$, no_lado_esquerdo);
        asd_add_child($$, no_expressao);
        $$->tipo = entrada_simbolo->tipo;
        free(token_identificador->lexema);
        free(token_identificador);
    }
  ;

// CHAMADA DE FUNÇÃO
// Uma chamada de função consiste no token TK_ID, seguida de argumentos
// entre parênteses, sendo que cada argumento é separado do outro por vírgula. Um argumento é
// uma expressão. Uma chamada de função pode existir sem argumentos.

chamada_funcao
  : TK_ID '(' argumentos ')'
    {
      valor_t *token_identificador = $1;
      asd_tree_t *nos_argumentos = $3;
      entrada_tabela_t *entrada_funcao = verificar_chamada_funcao(pilha_tabelas, token_identificador->lexema, get_line_number());
      verificar_argumentos_funcao(entrada_funcao, nos_argumentos, get_line_number());

      char *rotulo_no = (char*)calloc(strlen(token_identificador->lexema)+6, sizeof(char));
      strcpy(rotulo_no, "call "); strcat(rotulo_no, token_identificador->lexema);
      $$ = asd_new(rotulo_no);
      if (nos_argumentos) asd_add_child($$, nos_argumentos);
      $$->tipo = entrada_funcao->tipo;
      free(rotulo_no); free(token_identificador->lexema); free(token_identificador);
    }
  ;

argumentos
  : %empty          { $$ = NULL; }
  | argumento       { $$ = $1; }
  | argumento ',' argumentos
    {
        // encadeia em lista direita: arg -> arg -> ...
        $$ = $1;
        if ($3 != NULL) {
            asd_add_child($$, $3); // child[1] = próximo
        }
    }
  ;

argumento
  : expressao
    {
        $$ = asd_new("arg");
        asd_add_child($$, $1); // child[0] = expressão do argumento
        // child[1] (se existir) = próximo "arg" (ligação feita em 'argumentos')
    }
  ;

// COMANDO DE RETORNO
// Trata-se do token TK_RETORNA seguido de uma expressão, seguido do token TK_ATRIB
// e terminado ou pelo token TK_DECIMAL ou pelo token TK_INTEIRO.

comando_retorno
  : TK_RETORNA expressao TK_ATRIB tipo
    {
        asd_tree_t *no_expressao = $2;
        entrada_tabela_t *funcao_contexto = pilha_tabelas ? pilha_tabelas->funcao : NULL;
        verificar_semantica_retorno(funcao_contexto, no_expressao, get_line_number());

        $$ = asd_new("retorna");
        asd_add_child($$, no_expressao);
        $$->tipo = no_expressao->tipo;
    }
  ;

// CONSTRUÇÃO DE CONTROLE DE FLUXO
// A linguagem possui uma construção condicional e uma construção iterativa para controle estruturado de fluxo.

construcao_fluxo_controle
  : construcao_iterativa  { $$ = $1; }
  | construcao_condicional { $$ = $1; }
  ;

// A condicional consiste no token TK_SE seguido de uma expressão entre parênteses e então por um 
// bloco de comandos obrigatório. Após este bloco, podemos opcionalmente ter o token TK_SENAO que,
// quando aparece, é seguido obrigatoriamente por um bloco de comandos.

construcao_condicional
  : TK_SE '(' expressao ')' bloco_comando
    {
        asd_tree_t *no_condicao = $3;
        asd_tree_t *no_bloco_then = $5;
        $$ = asd_new("se");
        asd_add_child($$, no_condicao);
        asd_add_child($$, no_bloco_then);
        $$->tipo = no_condicao->tipo;
    }
  | TK_SE '(' expressao ')' bloco_comando TK_SENAO bloco_comando
    {
        asd_tree_t *no_condicao = $3;
        asd_tree_t *no_bloco_then = $5;
        asd_tree_t *no_bloco_else = $7;
        verificar_semantica_condicional(no_bloco_then, no_bloco_else, get_line_number());

        $$ = asd_new("se");
        asd_add_child($$, no_condicao);
        asd_add_child($$, no_bloco_then);
        asd_add_child($$, no_bloco_else);
        $$->tipo = no_condicao->tipo;
    }
  ;

// Temos apenas uma construção de repetição que é o token TK_ENQUANTO seguido de uma expressão entre
// parênteses e de um bloco de comandos.

construcao_iterativa
  : TK_ENQUANTO '(' expressao ')' bloco_comando
    {
        asd_tree_t *no_condicao = $3;
        asd_tree_t *no_bloco = $5;
        $$ = asd_new("enquanto");
        asd_add_child($$, no_condicao);
        asd_add_child($$, no_bloco);
        $$->tipo = no_condicao->tipo;
    }
  ;

// EXPRESSÃO
// Expressões envolvem operandos e operadores, sendo este opcional. Os operandos podem ser
// identificadores, literais e chamada de função ou outras expressões, podendo portanto ser formadas
// recursivamente pelo emprego de operadores. Elas também permitem o uso de parênteses para forçar
// uma associatividade ou precedência diferente daquela tradicional. A associatividade é à esquerda
// (portanto implemente recursão à esquerda nas regras gramaticais).

// Raiz
expressao
  : expressao_or { $$ = $1; }
  ;

// Nível 7: binário infixado or (|)
expressao_or
  : expressao_and '|' expressao_or
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("|");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_and { $$ = $1; }
  ;

// Nível 6: binário infixado and (&)
expressao_and
  : expressao_igual_desigual '&' expressao_and
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("&");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_igual_desigual { $$ = $1; }
  ;

// Nível 5: igualdade e desigualdade (==, !=)
expressao_igual_desigual
  : expressao_relacional TK_OC_EQ expressao_igual_desigual
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("==");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_relacional TK_OC_NE expressao_igual_desigual
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("!=");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_relacional { $$ = $1; }
  ;

// Nível 4: relacionais (<, >, <=, >=)
expressao_relacional
  : expressao_soma_subtracao '<'      expressao_relacional
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("<");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_soma_subtracao '>'      expressao_relacional
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new(">");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_soma_subtracao TK_OC_LE expressao_relacional
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("<=");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_soma_subtracao TK_OC_GE expressao_relacional
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new(">=");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_soma_subtracao { $$ = $1; }
  ;

// Nível 3: soma e subtração
expressao_soma_subtracao
  : expressao_mult_div_mod '+' expressao_soma_subtracao
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("+");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_mult_div_mod '-' expressao_soma_subtracao
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("-");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_mult_div_mod { $$ = $1; }
  ;

// Nível 2: multiplicação, divisão e mod
expressao_mult_div_mod
  : expressao_unitario '*' expressao_mult_div_mod
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("*");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_unitario '/' expressao_mult_div_mod
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("/");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_unitario '%' expressao_mult_div_mod
    {
      asd_tree_t *no_esquerdo = $1;
      asd_tree_t *no_direito = $3;
      verificar_tipo_binario(no_esquerdo->tipo, no_direito->tipo, get_line_number());

      asd_tree_t *no_operador = asd_new("%");
      asd_add_child(no_operador, no_esquerdo);
      asd_add_child(no_operador, no_direito);
    
      no_operador->tipo = inferir_tipo_binario(no_esquerdo->tipo, no_direito->tipo);
      $$ = no_operador;
    }
  | expressao_unitario { $$ = $1; }
  ;

// Nível 1: unários pré-fixados (+, -, !)
expressao_unitario
  : '+' expressao_unitario { $$ = asd_new("+"); asd_add_child($$, $2); $$->tipo = $2->tipo; }
  | '-' expressao_unitario { $$ = asd_new("-"); asd_add_child($$, $2); $$->tipo = $2->tipo; }
  | '!' expressao_unitario { $$ = asd_new("!"); asd_add_child($$, $2); $$->tipo = $2->tipo; }
  | expressao_pos_fixado   { $$ = $1; }
  ;

// Nível 0: pós-fixados primários e chamada de função
expressao_pos_fixado
  : expressao_primario { $$ = $1; }
  | chamada_funcao     { $$ = $1; }
  ;

// primários: identificadores, literais e parênteses
expressao_primario
  : TK_ID
    {
        valor_t *token_identificador = $1;
        verificar_declaracao_identificador(pilha_tabelas, token_identificador->lexema, get_line_number());
        entrada_tabela_t *entrada_simbolo = buscar_simbolo(pilha_tabelas, token_identificador->lexema);
        verificar_semantica_expressao_primario(entrada_simbolo, get_line_number());
        
        $$ = asd_new(token_identificador->lexema);
        $$->tipo = entrada_simbolo->tipo;
        free(token_identificador->lexema);
        free(token_identificador);
    }
  | literal { $$ = $1; }
  | '(' expressao ')' { $$ = $2; }
  ;

%%

void yyerror (char const *mensagem)
{
    fprintf(stderr, "[ERRO]\nNa linha %d, com mensagem:\n%s\n", get_line_number(), mensagem);
}
