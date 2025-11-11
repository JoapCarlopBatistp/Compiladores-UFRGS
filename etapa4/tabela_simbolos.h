//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS

#ifndef TABELA_SIMBOLOS_H
#define TABELA_SIMBOLOS_H

#include "valor_token.h"

// Natureza do símbolo
typedef enum {
    NAT_LITERAL,
    NAT_IDENTIFICADOR,
    NAT_FUNCAO
} natureza_t;

// Tipo de dado
typedef enum {
    TIPO_INT,
    TIPO_FLOAT,
    TIPO_NAO_DEFINIDO
} tipo_dado_t;

// Informação de um parâmetro
typedef struct parametro {
    tipo_dado_t tipo;
    struct parametro *proximo;
} parametro_t;

// Entrada na tabela de símbolos
typedef struct entrada_tabela {
    char *chave;                    // Nome do identificador
    natureza_t natureza;            // Natureza (literal, id, função)
    tipo_dado_t tipo;               // Tipo do dado
    parametro_t *parametros;        // Lista de parâmetros (se função)
    int linha;                      // Linha de declaração
    valor_t *valor;                 // Dados do token
    struct entrada_tabela *proximo; // Próxima entrada (lista encadeada)
} entrada_tabela_t;

// Tabela de símbolos
typedef struct tabela_simbolos {
    entrada_tabela_t *primeiro;       // Primeira entrada da tabela
    struct tabela_simbolos *anterior; // Tabela do escopo anterior (pilha)
    entrada_tabela_t *funcao;         // Função associada ao escopo (se houver)
} tabela_simbolos_t;

// Funções da tabela de símbolos
tabela_simbolos_t* criar_tabela();
void empilhar_tabela(tabela_simbolos_t **pilha);
void desempilhar_tabela(tabela_simbolos_t **pilha);
void liberar_tabela(tabela_simbolos_t *tabela);

// Funções de manipulação de entradas
void inserir_simbolo(tabela_simbolos_t *tabela, const char *chave, natureza_t nat, 
                     tipo_dado_t tipo, int linha, const valor_t *val);
entrada_tabela_t* buscar_simbolo(tabela_simbolos_t *pilha, const char *chave);
entrada_tabela_t* buscar_simbolo_escopo_atual(tabela_simbolos_t *tabela, const char *chave);

// Funções para parâmetros de função
void adicionar_parametro(entrada_tabela_t *entrada, tipo_dado_t tipo);
void liberar_parametros(parametro_t *params);
void adicionar_parametro_funcao(entrada_tabela_t *func, tipo_dado_t tipo);
void declarar_variavel_global(tabela_simbolos_t *pilha, valor_t *token, tipo_dado_t tipo, int linha);
void declarar_variavel_local(tabela_simbolos_t *pilha, valor_t *token, tipo_dado_t tipo, int linha);
entrada_tabela_t* declarar_funcao(tabela_simbolos_t *pilha, valor_t *token, tipo_dado_t tipo, int linha);
void registrar_literal(tabela_simbolos_t *pilha, valor_t *token, tipo_dado_t tipo);

// Função para converter string de tipo em tipo_dado_t
tipo_dado_t string_para_tipo(char *tipo_str);
char* tipo_para_string(tipo_dado_t tipo);
char* natureza_para_string(natureza_t nat);

#endif // TABELA_SIMBOLOS_H
