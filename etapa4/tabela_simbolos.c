// INTEGRANTES DO GRUPO:
// JOÃO CARLOS BATISTA
// RICHARD LEAL RAMOS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tabela_simbolos.h"

static valor_t* duplicar_valor(const valor_t *src) {
    if (src == NULL) return NULL;

    valor_t *dest = (valor_t*)malloc(sizeof(valor_t));
    if (dest == NULL) {
        fprintf(stderr, "Erro ao alocar memória para valor_t\n");
        exit(1);
    }

    dest->linha_token = src->linha_token;
    dest->tipo = src->tipo;
    dest->lexema = src->lexema ? strdup(src->lexema) : NULL;
    if (src->lexema && dest->lexema == NULL) {
        fprintf(stderr, "Erro ao alocar memória para lexema de valor_t\n");
        exit(1);
    }

    return dest;
}

static void liberar_valor_copiado(valor_t *val) {
    if (val == NULL) return;
    free(val->lexema);
    free(val);
}

// Cria nova tabela de símbolos
tabela_simbolos_t* criar_tabela() {
    tabela_simbolos_t *tabela = (tabela_simbolos_t*)malloc(sizeof(tabela_simbolos_t));
    if (tabela == NULL) {
        fprintf(stderr, "Erro ao alocar memória para tabela de símbolos\n");
        exit(1);
    }
    tabela->primeiro = NULL;
    tabela->anterior = NULL;
    tabela->funcao = NULL;
    return tabela;
}

// Empilha nova tabela (novo escopo)
void empilhar_tabela(tabela_simbolos_t **pilha) {
    if (pilha == NULL) return;

    tabela_simbolos_t *topo_atual = *pilha;
    tabela_simbolos_t *nova = criar_tabela();
    nova->funcao = topo_atual ? topo_atual->funcao : NULL;
    nova->anterior = topo_atual;
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

void adicionar_parametro_funcao(entrada_tabela_t *func, tipo_dado_t tipo) {
    adicionar_parametro(func, tipo);
}

void declarar_variavel_global(tabela_simbolos_t *pilha, valor_t *token, tipo_dado_t tipo, int linha) {
    if (pilha == NULL || token == NULL) return;
    inserir_simbolo(pilha, token->lexema, NAT_IDENTIFICADOR, tipo, linha, token);
}

void declarar_variavel_local(tabela_simbolos_t *pilha, valor_t *token, tipo_dado_t tipo, int linha) {
    if (pilha == NULL || token == NULL) return;
    inserir_simbolo(pilha, token->lexema, NAT_IDENTIFICADOR, tipo, linha, token);
}

entrada_tabela_t* declarar_funcao(tabela_simbolos_t *pilha, valor_t *token, tipo_dado_t tipo, int linha) {
    if (pilha == NULL || token == NULL) return NULL;
    inserir_simbolo(pilha, token->lexema, NAT_FUNCAO, tipo, linha, token);
    return buscar_simbolo(pilha, token->lexema);
}

void registrar_literal(tabela_simbolos_t *pilha, valor_t *token, tipo_dado_t tipo) {
    if (token == NULL || pilha == NULL) return;
    if (buscar_simbolo_escopo_atual(pilha, token->lexema) == NULL) {
        inserir_simbolo(pilha, token->lexema, NAT_LITERAL, tipo, token->linha_token, token);
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
        liberar_valor_copiado(temp->valor);
        free(temp);
    }
    
    free(tabela);
}

// Insere símbolo na tabela (escopo atual)
void inserir_simbolo(tabela_simbolos_t *tabela, const char *chave, natureza_t nat,
                     tipo_dado_t tipo, int linha, const valor_t *val) {
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
    nova->valor = duplicar_valor(val);
    nova->proximo = tabela->primeiro;
    
    tabela->primeiro = nova;
}

// Busca símbolo apenas no escopo atual
entrada_tabela_t* buscar_simbolo_escopo_atual(tabela_simbolos_t *tabela, const char *chave) {
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
entrada_tabela_t* buscar_simbolo(tabela_simbolos_t *pilha, const char *chave) {
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
