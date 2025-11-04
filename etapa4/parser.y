%{
//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "asd.h"
#include "valor_token.h"
#include "tabela_simbolos.h"
#include "errors.h"

int yylex(void);
void yyerror (char const *mensagem);
extern int get_line_number();

// Estado semântico E4
static entrada_tabela_t *func_atual = NULL;
static tipo_dado_t tipo_em_contexto = TIPO_NAO_DEFINIDO;

extern asd_tree_t *arvore;

// Pilha de tabelas de símbolos (escopo)
// (Definição REAL em main.c; aqui somente a declaração.)
extern tabela_simbolos_t *pilha_tabelas;

// ======= Funções auxiliares declaradas por ti =======
void declarar_variavel_global(char *nome, tipo_dado_t tipo, int linha);
void declarar_variavel_local(char *nome, tipo_dado_t tipo, int linha);
entrada_tabela_t* declarar_funcao(char *nome, tipo_dado_t tipo, int linha);
void verificar_uso_identificador(char *nome, int linha);
entrada_tabela_t* verificar_chamada_funcao(char *nome, int linha);
void adicionar_parametro_funcao(entrada_tabela_t *func, tipo_dado_t tipo);
void verificar_argumentos_funcao(entrada_tabela_t *func, asd_tree_t *args, int linha);
int contar_argumentos(asd_tree_t *args);

// ---- Impressão padronizada de erros E4 ----
static const char* err_name(int code) {
    switch (code) {
        case ERR_UNDECLARED:      return "ERR_UNDECLARED";
        case ERR_DECLARED:        return "ERR_DECLARED";
        case ERR_VARIABLE:        return "ERR_VARIABLE";
        case ERR_FUNCTION:        return "ERR_FUNCTION";
        case ERR_WRONG_TYPE:      return "ERR_WRONG_TYPE";
        case ERR_MISSING_ARGS:    return "ERR_MISSING_ARGS";
        case ERR_EXCESS_ARGS:     return "ERR_EXCESS_ARGS";
        case ERR_WRONG_TYPE_ARGS: return "ERR_WRONG_TYPE_ARGS";
        default:                  return "ERR_UNKNOWN";
    }
}

// Usa a linha fornecida
static void semerr_line(int code, int linha, const char *fmt, ...) {
    va_list ap;
    fprintf(stderr, "ERRO SEMÂNTICO [%s %d] linha %d: ", err_name(code), code, linha);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    if (fmt[0] && fmt[strlen(fmt)-1] != '\n') fprintf(stderr, "\n");
    exit(code);
}

// Usa get_line_number()
static void semerr(int code, const char *fmt, ...) {
    va_list ap;
    int linha = get_line_number();
    fprintf(stderr, "ERRO SEMÂNTICO [%s %d] linha %d: ", err_name(code), code, linha);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    if (fmt[0] && fmt[strlen(fmt)-1] != '\n') fprintf(stderr, "\n");
    exit(code);
}
%}

%code requires {
    #include "valor_token.h"
    #include "asd.h"
    #include "tabela_simbolos.h"
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
        // Declara no escopo corrente (global se no topo)
        declarar_variavel_global($2->lexema, tipo_em_contexto, get_line_number());
        $$ = asd_new($2->lexema);
        free($2->lexema);
        free($2);
        if ($4 != NULL) asd_free($4);
        $$ = NULL; // não precisamos manter nó de declaração
    }
  ;

tipo
  : TK_DECIMAL { tipo_em_contexto = TIPO_FLOAT; $$ = NULL; }
  | TK_INTEIRO { tipo_em_contexto = TIPO_INT;   $$ = NULL; }
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
        func_atual = NULL;
    }
  ;

cabecalho
  : TK_ID TK_SETA tipo
    {
        // Declara a função no escopo corrente e abre escopo para parâmetros
      func_atual = declarar_funcao($1->lexema, tipo_em_contexto, get_line_number());
      empilhar_tabela(&pilha_tabelas);
    }
    lista_parametros_opcionais TK_ATRIB
    {
      $$ = asd_new($1->lexema);
      free($1->lexema);
      free($1);
      if ($3 != NULL) asd_free($3);
      if ($5 != NULL) asd_free($5);
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
        // adiciona tipo formal e insere parâmetro como variável do escopo da função
        adicionar_parametro_funcao(func_atual, tipo_em_contexto);
        declarar_variavel_local($1->lexema, tipo_em_contexto, get_line_number());
        free($1->lexema);
        free($1);
        if ($3 != NULL) asd_free($3);
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
  : '[' { empilhar_tabela(&pilha_tabelas); } sequencia_comando_simples ']' 
    { $$ = $3; desempilhar_tabela(&pilha_tabelas); }
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
        // Declara no escopo atual (local)
        declarar_variavel_local($2->lexema, tipo_em_contexto, get_line_number());
        $$ = NULL;
        free($2->lexema);
        free($2);
        if ($4 != NULL) asd_free($4);
    }
  | TK_VAR TK_ID TK_ATRIB tipo TK_COM literal
    {
        // Declara local e checa tipo da inicialização (E4)
        tipo_dado_t tvar = tipo_em_contexto; // setado por 'tipo'
        if ($6 == NULL) {
            semerr(ERR_WRONG_TYPE, "literal inválido.");
        }
        if ($6->tipo != tvar && $6->tipo != TIPO_NAO_DEFINIDO) {
            semerr(ERR_WRONG_TYPE, "inicialização de '%s' com tipo incompatível (%s := %s).",
                   $2->lexema, tipo_para_string(tvar), tipo_para_string($6->tipo));
        }
        declarar_variavel_local($2->lexema, tvar, get_line_number());
        // monta um nó "com" apenas para manter a AST de declaração+init
        $$ = asd_new("com");
        asd_tree_t *decl = asd_new($2->lexema);
        asd_add_child($$, decl);
        asd_add_child($$, $6);
        free($2->lexema);
        free($2);
        if ($4 != NULL) asd_free($4);
    }
  ;

literal
  : TK_LI_INTEIRO { $$ = asd_new($1->lexema); $$->tipo = TIPO_INT;  free($1->lexema); free($1); }
  | TK_LI_DECIMAL { $$ = asd_new($1->lexema); $$->tipo = TIPO_FLOAT; free($1->lexema); free($1); }
  ;

// COMANDO DE ATRIBUIÇÃO
// O comando de atribuição consiste em um token TK_ID, seguido do token TK_ATRIB e enfim seguido por
// uma expressão.

comando_atribuicao
  : TK_ID TK_ATRIB expressao
    {
        verificar_uso_identificador($1->lexema, get_line_number());
        entrada_tabela_t *e = buscar_simbolo(pilha_tabelas, $1->lexema);
        if (e->natureza != NAT_IDENTIFICADOR) {
            semerr(ERR_VARIABLE, "'%s' não é variável.", e->chave);
        }
        if ($3->tipo != e->tipo && $3->tipo != TIPO_NAO_DEFINIDO) {
            semerr(ERR_WRONG_TYPE, "atribuição incompatível (%s := %s).",
                   tipo_para_string(e->tipo), tipo_para_string($3->tipo));
        }
        $$ = asd_new(":=");
        asd_tree_t *lhs = asd_new($1->lexema);
        asd_add_child($$, lhs);
        asd_add_child($$, $3);
        $$->tipo = e->tipo;
        free($1->lexema);
        free($1);
    }
  ;

// CHAMADA DE FUNÇÃO
// Uma chamada de função consiste no token TK_ID, seguida de argumentos
// entre parênteses, sendo que cada argumento é separado do outro por vírgula. Um argumento é
// uma expressão. Uma chamada de função pode existir sem argumentos.

chamada_funcao
  : TK_ID '(' argumentos ')'
    {
      entrada_tabela_t *f = verificar_chamada_funcao($1->lexema, get_line_number());
      verificar_argumentos_funcao(f, $3, get_line_number());

      char *node_label = (char*)calloc(strlen($1->lexema)+6, sizeof(char));
      strcpy(node_label, "call "); strcat(node_label, $1->lexema);
      $$ = asd_new(node_label);
      if ($3) asd_add_child($$, $3);
      $$->tipo = f->tipo;
      free(node_label); free($1->lexema); free($1);
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
        if (!func_atual) {
            semerr(ERR_WRONG_TYPE, "'retorna' fora de função.");
        }
        if ($2->tipo != func_atual->tipo && $2->tipo != TIPO_NAO_DEFINIDO) {
            semerr(ERR_WRONG_TYPE, "tipo de retorno incompatível em '%s' (%s esperado, %s dado).",
                   func_atual->chave, tipo_para_string(func_atual->tipo), tipo_para_string($2->tipo));
        }
        $$ = asd_new("retorna");
        asd_add_child($$, $2);
        if ($4 != NULL) asd_free($4);
        $$->tipo = $2->tipo;
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
        $$ = asd_new("se");
        asd_add_child($$, $3); // condição
        asd_add_child($$, $5); // bloco then
        $$->tipo = $3->tipo;   // tipo do comando = tipo da expressão de teste
    }
  | TK_SE '(' expressao ')' bloco_comando TK_SENAO bloco_comando
    {
        $$ = asd_new("se");
        asd_add_child($$, $3); // condição
        asd_add_child($$, $5); // bloco then
        asd_add_child($$, $7); // bloco else
        $$->tipo = $3->tipo;
    }
  ;

// Temos apenas uma construção de repetição que é o token TK_ENQUANTO seguido de uma expressão entre
// parênteses e de um bloco de comandos.

construcao_iterativa
  : TK_ENQUANTO '(' expressao ')' bloco_comando
    {
        $$ = asd_new("enquanto");
        asd_add_child($$, $3);
        asd_add_child($$, $5);
        $$->tipo = $3->tipo; // tipo do comando = tipo da expressão de teste
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
    { $$ = asd_new("|"); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_and { $$ = $1; }
  ;

// Nível 6: binário infixado and (&)
expressao_and
  : expressao_igual_desigual '&' expressao_and
    { $$ = asd_new("&"); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_igual_desigual { $$ = $1; }
  ;

// Nível 5: igualdade e desigualdade (==, !=)
expressao_igual_desigual
  : expressao_relacional TK_OC_EQ expressao_igual_desigual
    { $$ = asd_new("=="); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_relacional TK_OC_NE expressao_igual_desigual
    { $$ = asd_new("!="); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_relacional { $$ = $1; }
  ;

// Nível 4: relacionais (<, >, <=, >=)
expressao_relacional
  : expressao_soma_subtracao '<'      expressao_relacional
    { $$ = asd_new("<"); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_soma_subtracao '>'      expressao_relacional
    { $$ = asd_new(">"); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_soma_subtracao TK_OC_LE expressao_relacional
    { $$ = asd_new("<="); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_soma_subtracao TK_OC_GE expressao_relacional
    { $$ = asd_new(">="); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_soma_subtracao { $$ = $1; }
  ;

// Nível 3: soma e subtração
expressao_soma_subtracao
  : expressao_mult_div_mod '+' expressao_soma_subtracao
    { $$ = asd_new("+"); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_mult_div_mod '-' expressao_soma_subtracao
    { $$ = asd_new("-"); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_mult_div_mod { $$ = $1; }
  ;

// Nível 2: multiplicação, divisão e mod
expressao_mult_div_mod
  : expressao_unitario '*' expressao_mult_div_mod
    { $$ = asd_new("*"); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_unitario '/' expressao_mult_div_mod
    { $$ = asd_new("/"); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
  | expressao_unitario '%' expressao_mult_div_mod
    { $$ = asd_new("%"); asd_add_child($$, $1); asd_add_child($$, $3);
      $$->tipo = inferir_tipo_binario($1->tipo, $3->tipo, get_line_number()); }
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
        verificar_uso_identificador($1->lexema, get_line_number());
        entrada_tabela_t *e = buscar_simbolo(pilha_tabelas, $1->lexema);
        if (e->natureza == NAT_FUNCAO) {
            semerr(ERR_FUNCTION, "função '%s' usada como variável.", e->chave);
        }
        $$ = asd_new($1->lexema);
        $$->tipo = e->tipo;
        free($1->lexema);
        free($1);
    }
  | literal { $$ = $1; }
  | '(' expressao ')' { $$ = $2; }
  ;

%%

void yyerror (char const *mensagem)
{
    fprintf(stderr, "[ERRO]\nNa linha %d, com mensagem:\n%s\n", get_line_number(), mensagem);
}

// ================== Implementações das tuas funções auxiliares ==================

void declarar_variavel_global(char *nome, tipo_dado_t tipo, int linha) {
    if (buscar_simbolo_escopo_atual(pilha_tabelas, nome) != NULL) {
        semerr_line(ERR_DECLARED, linha, "variável '%s' já foi declarada.", nome);
    }
    inserir_simbolo(pilha_tabelas, nome, NAT_IDENTIFICADOR, tipo, linha, NULL);
}

void declarar_variavel_local(char *nome, tipo_dado_t tipo, int linha) {
    if (buscar_simbolo_escopo_atual(pilha_tabelas, nome) != NULL) {
        semerr_line(ERR_DECLARED, linha, "variável '%s' já foi declarada neste escopo.", nome);
    }
    inserir_simbolo(pilha_tabelas, nome, NAT_IDENTIFICADOR, tipo, linha, NULL);
}

entrada_tabela_t* declarar_funcao(char *nome, tipo_dado_t tipo, int linha) {
    if (buscar_simbolo_escopo_atual(pilha_tabelas, nome) != NULL) {
        semerr_line(ERR_DECLARED, linha, "função '%s' já foi declarada.", nome);
    }
    inserir_simbolo(pilha_tabelas, nome, NAT_FUNCAO, tipo, linha, NULL);
    return buscar_simbolo(pilha_tabelas, nome);
}

void verificar_uso_identificador(char *nome, int linha) {
    if (buscar_simbolo(pilha_tabelas, nome) == NULL) {
        semerr_line(ERR_UNDECLARED, linha, "identificador '%s' não foi declarado.", nome);
    }
}

entrada_tabela_t* verificar_chamada_funcao(char *nome, int linha) {
    entrada_tabela_t *entrada = buscar_simbolo(pilha_tabelas, nome);
    if (entrada == NULL) {
        semerr_line(ERR_UNDECLARED, linha, "função '%s' não foi declarada.", nome);
    }
    if (entrada->natureza != NAT_FUNCAO) {
        semerr_line(ERR_VARIABLE, linha, "'%s' é uma variável e não pode ser chamada como função.", nome);
    }
    return entrada;
}

void adicionar_parametro_funcao(entrada_tabela_t *func, tipo_dado_t tipo) {
    adicionar_parametro(func, tipo);
}

// ===== Helpers para lista de argumentos em nós "arg" =====

// Conta nós "arg" encadeados em child[1]
int contar_argumentos(asd_tree_t *args) {
    int n = 0;
    asd_tree_t *p = args;
    while (p != NULL) {
        n++;
        if (p->number_of_children >= 2)
            p = p->children[1]; // próximo "arg"
        else
            p = NULL;
    }
    return n;
}

static asd_tree_t* arg_expr(asd_tree_t *arg) {
    return (arg && arg->number_of_children > 0) ? arg->children[0] : NULL;
}
static asd_tree_t* arg_next(asd_tree_t *arg) {
    return (arg && arg->number_of_children > 1) ? arg->children[1] : NULL;
}

void verificar_argumentos_funcao(entrada_tabela_t *func, asd_tree_t *args, int linha) {
    // Conta parâmetros esperados
    int num_params = 0;
    for (parametro_t *p2 = func->parametros; p2; p2 = p2->proximo) num_params++;

    // Conta argumentos fornecidos
    int num_args = contar_argumentos(args);

    if (num_args < num_params) {
        semerr_line(ERR_MISSING_ARGS, linha, "chamada de função '%s' com menos argumentos que o esperado.", func->chave);
    }
    if (num_args > num_params) {
        semerr_line(ERR_EXCESS_ARGS,  linha, "chamada de função '%s' com mais argumentos que o esperado.",  func->chave);
    }

    // Verifica tipos 1 a 1
    parametro_t *p = func->parametros;
    asd_tree_t  *a = args;
    int pos = 1;

    while (p && a) {
        asd_tree_t *expr = arg_expr(a);
        tipo_dado_t ta = expr ? expr->tipo : TIPO_NAO_DEFINIDO;

        if (ta != p->tipo && ta != TIPO_NAO_DEFINIDO) {
            semerr_line(ERR_WRONG_TYPE_ARGS, linha,
                "argumento %d da função '%s' com tipo incompatível (esperado %s, recebido %s).",
                pos, func->chave, tipo_para_string(p->tipo), tipo_para_string(ta));
        }
        p = p->proximo;
        a = arg_next(a);
        pos++;
    }
}
