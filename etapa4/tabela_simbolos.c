//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tabela_simbolos.h"

// Cria nova tabela de símbolos
tabela_simbolos_t* criar_tabela() {
    tabela_simbolos_t *tabela = (tabela_simbolos_t*)malloc(sizeof(tabela_simbolos_t));
    if (tabela == NULL) {
        fprintf(stderr, "Erro ao alocar memória para tabela de símbolos\n");
        exit(1);
    }
    tabela->primeiro = NULL;
    tabela->anterior = NULL;
    return tabela;
}

// Empilha nova tabela (novo escopo)
void empilhar_tabela(tabela_simbolos_t **pilha) {
    tabela_simbolos_t *nova = criar_tabela();
    nova->anterior = *pilha;
    *pilha = nova;
}

// Desempilha e libera tabela (sai do escopo)
void desempilhar_tabela(tabela_simbolos_t **pilha) {
    if (*pilha == NULL) return;
    
    tabela_simbolos_t *temp = *pilha;
    *pilha = (*pilha)->anterior;
    liberar_tabela(temp);
}

// Libera lista de parâmetros
void liberar_parametros(parametro_t *params) {
    while (params != NULL) {
        parametro_t *temp = params;
        params = params->proximo;
        free(temp);
    }
}

// Libera tabela de símbolos
void liberar_tabela(tabela_simbolos_t *tabela) {
    if (tabela == NULL) return;
    
    entrada_tabela_t *atual = tabela->primeiro;
    while (atual != NULL) {
        entrada_tabela_t *temp = atual;
        atual = atual->proximo;
        
        free(temp->chave);
        if (temp->parametros != NULL) {
            liberar_parametros(temp->parametros);
        }
        // Não libera valor aqui pois pode ser usado na AST
        free(temp);
    }
    
    free(tabela);
}

// Insere símbolo na tabela (escopo atual)
void inserir_simbolo(tabela_simbolos_t *tabela, char *chave, natureza_t nat,
                     tipo_dado_t tipo, int linha, valor_t *val) {
    if (tabela == NULL) return;
    
    entrada_tabela_t *nova = (entrada_tabela_t*)malloc(sizeof(entrada_tabela_t));
    if (nova == NULL) {
        fprintf(stderr, "Erro ao alocar memória para entrada da tabela\n");
        exit(1);
    }
    
    nova->chave = strdup(chave);
    nova->natureza = nat;
    nova->tipo = tipo;
    nova->parametros = NULL;
    nova->linha = linha;
    nova->valor = val;
    nova->proximo = tabela->primeiro;
    
    tabela->primeiro = nova;
}

// Busca símbolo apenas no escopo atual
entrada_tabela_t* buscar_simbolo_escopo_atual(tabela_simbolos_t *tabela, char *chave) {
    if (tabela == NULL || chave == NULL) return NULL;
    
    entrada_tabela_t *atual = tabela->primeiro;
    while (atual != NULL) {
        if (strcmp(atual->chave, chave) == 0) {
            return atual;
        }
        atual = atual->proximo;
    }
    
    return NULL;
}

// Busca símbolo em toda a pilha de tabelas (do escopo atual até o global)
entrada_tabela_t* buscar_simbolo(tabela_simbolos_t *pilha, char *chave) {
    if (chave == NULL) return NULL;
    
    tabela_simbolos_t *atual = pilha;
    while (atual != NULL) {
        entrada_tabela_t *entrada = buscar_simbolo_escopo_atual(atual, chave);
        if (entrada != NULL) {
            return entrada;
        }
        atual = atual->anterior;
    }
    
    return NULL;
}

// Adiciona parâmetro à função
void adicionar_parametro(entrada_tabela_t *entrada, tipo_dado_t tipo) {
    if (entrada == NULL) return;
    
    parametro_t *novo = (parametro_t*)malloc(sizeof(parametro_t));
    if (novo == NULL) {
        fprintf(stderr, "Erro ao alocar memória para parâmetro\n");
        exit(1);
    }
    
    novo->tipo = tipo;
    novo->proximo = NULL;
    
    // Adiciona no final da lista
    if (entrada->parametros == NULL) {
        entrada->parametros = novo;
    } else {
        parametro_t *ultimo = entrada->parametros;
        while (ultimo->proximo != NULL) {
            ultimo = ultimo->proximo;
        }
        ultimo->proximo = novo;
    }
}

// Converte string de tipo para tipo_dado_t
tipo_dado_t string_para_tipo(char *tipo_str) {
    if (tipo_str == NULL) return TIPO_NAO_DEFINIDO;
    
    if (strcmp(tipo_str, "inteiro") == 0) {
        return TIPO_INT;
    } else if (strcmp(tipo_str, "decimal") == 0) {
        return TIPO_FLOAT;
    }
    
    return TIPO_NAO_DEFINIDO;
}

// Converte tipo_dado_t para string
char* tipo_para_string(tipo_dado_t tipo) {
    switch (tipo) {
        case TIPO_INT:
            return "inteiro";
        case TIPO_FLOAT:
            return "decimal";
        default:
            return "não definido";
    }
}

// Converte natureza_t para string
char* natureza_para_string(natureza_t nat) {
    switch (nat) {
        case NAT_LITERAL:
            return "literal";
        case NAT_IDENTIFICADOR:
            return "variável";
        case NAT_FUNCAO:
            return "função";
        default:
            return "desconhecido";
    }
}