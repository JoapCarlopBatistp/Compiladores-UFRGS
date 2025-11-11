#include <stdio.h>
#include <stdlib.h>
#include "semantica.h"
#include "tabela_simbolos.h"

const char* semantica_nome_erro(int codigo) {
    switch (codigo) {
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

tipo_dado_t inferir_tipo_binario(tipo_dado_t tipo1, tipo_dado_t tipo2) {
    if (tipo1 == TIPO_INT && tipo2 == TIPO_INT) {
        return TIPO_INT;
    }
    if (tipo1 == TIPO_FLOAT && tipo2 == TIPO_FLOAT) {
        return TIPO_FLOAT;
    }
    return TIPO_NAO_DEFINIDO;
}

void verificar_tipo_binario(tipo_dado_t tipo1, tipo_dado_t tipo2, int linha) {
    if ((tipo1 == TIPO_INT && tipo2 == TIPO_FLOAT) ||
        (tipo1 == TIPO_FLOAT && tipo2 == TIPO_INT)) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: tipos incompatíveis (%s e %s) em operação.\n",
                semantica_nome_erro(ERR_WRONG_TYPE), ERR_WRONG_TYPE, linha,
                tipo_para_string(tipo1), tipo_para_string(tipo2));
        exit(ERR_WRONG_TYPE);
    }
}

void verificar_semantica_parametro(entrada_tabela_t *funcao, int linha) {
    if (funcao == NULL) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: parâmetro declarado fora de função.\n",
                semantica_nome_erro(ERR_WRONG_TYPE), ERR_WRONG_TYPE, linha);
        exit(ERR_WRONG_TYPE);
    }
}

void verificar_semantica_inicializacao_variavel_local(asd_tree_t *no_literal, valor_t *identificador, tipo_dado_t tipo_declarado, int linha) {
    if (no_literal == NULL) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: literal inválido na inicialização de '%s'.\n",
                semantica_nome_erro(ERR_WRONG_TYPE), ERR_WRONG_TYPE, linha,
                identificador ? identificador->lexema : "<anon>");
        exit(ERR_WRONG_TYPE);
    }
    if (no_literal->tipo != tipo_declarado && no_literal->tipo != TIPO_NAO_DEFINIDO) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: inicialização de '%s' com tipo incompatível (%s := %s).\n",
                semantica_nome_erro(ERR_WRONG_TYPE), ERR_WRONG_TYPE, linha,
                identificador ? identificador->lexema : "<anon>",
                tipo_para_string(tipo_declarado), tipo_para_string(no_literal->tipo));
        exit(ERR_WRONG_TYPE);
    }
}

void verificar_semantica_variavel_global(tabela_simbolos_t *pilha, valor_t *token, int linha) {
    if (pilha == NULL || token == NULL) return;
    if (buscar_simbolo_escopo_atual(pilha, token->lexema) != NULL) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: variável '%s' já foi declarada.\n",
                semantica_nome_erro(ERR_DECLARED), ERR_DECLARED, linha, token->lexema);
        exit(ERR_DECLARED);
    }
}

void verificar_semantica_variavel_local(tabela_simbolos_t *pilha, valor_t *token, int linha) {
    if (pilha == NULL || token == NULL) return;
    if (buscar_simbolo_escopo_atual(pilha, token->lexema) != NULL) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: variável '%s' já foi declarada neste escopo.\n",
                semantica_nome_erro(ERR_DECLARED), ERR_DECLARED, linha, token->lexema);
        exit(ERR_DECLARED);
    }
}

void verificar_semantica_declaracao_funcao(tabela_simbolos_t *pilha, valor_t *token, int linha) {
    if (pilha == NULL || token == NULL) return;
    if (buscar_simbolo_escopo_atual(pilha, token->lexema) != NULL) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: função '%s' já foi declarada.\n",
                semantica_nome_erro(ERR_DECLARED), ERR_DECLARED, linha, token->lexema);
        exit(ERR_DECLARED);
    }
}

void verificar_semantica_atribuicao(entrada_tabela_t *entrada_simbolo, asd_tree_t *expressao, int linha) {
    if (entrada_simbolo == NULL) return;
    if (entrada_simbolo->natureza != NAT_IDENTIFICADOR) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: '%s' é função e não pode receber atribuição.\n",
                semantica_nome_erro(ERR_FUNCTION), ERR_FUNCTION, linha,
                entrada_simbolo->chave);
        exit(ERR_FUNCTION);
    }
    tipo_dado_t tipo_expressao = expressao ? expressao->tipo : TIPO_NAO_DEFINIDO;
    if (tipo_expressao != entrada_simbolo->tipo && tipo_expressao != TIPO_NAO_DEFINIDO) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: atribuição incompatível (%s := %s).\n",
                semantica_nome_erro(ERR_WRONG_TYPE), ERR_WRONG_TYPE, linha,
                tipo_para_string(entrada_simbolo->tipo), tipo_para_string(tipo_expressao));
        exit(ERR_WRONG_TYPE);
    }
}

void verificar_semantica_retorno(entrada_tabela_t *funcao, asd_tree_t *expressao, int linha) {
    if (funcao == NULL) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: 'retorna' fora de função.\n",
                semantica_nome_erro(ERR_WRONG_TYPE), ERR_WRONG_TYPE, linha);
        exit(ERR_WRONG_TYPE);
    }
    tipo_dado_t tipo_expr = expressao ? expressao->tipo : TIPO_NAO_DEFINIDO;
    if (tipo_expr != funcao->tipo && tipo_expr != TIPO_NAO_DEFINIDO) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: tipo de retorno incompatível em '%s' (%s esperado, %s dado).\n",
                semantica_nome_erro(ERR_WRONG_TYPE), ERR_WRONG_TYPE, linha,
                funcao->chave, tipo_para_string(funcao->tipo), tipo_para_string(tipo_expr));
        exit(ERR_WRONG_TYPE);
    }
}

void verificar_semantica_condicional(asd_tree_t *bloco_then, asd_tree_t *bloco_else, int linha) {
    tipo_dado_t tipo_then = bloco_then ? bloco_then->tipo : TIPO_NAO_DEFINIDO;
    tipo_dado_t tipo_else = bloco_else ? bloco_else->tipo : TIPO_NAO_DEFINIDO;
    if (tipo_then != tipo_else && tipo_then != TIPO_NAO_DEFINIDO && tipo_else != TIPO_NAO_DEFINIDO) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: blocos 'se' e 'senao' com tipos incompatíveis (%s vs %s).\n",
                semantica_nome_erro(ERR_WRONG_TYPE), ERR_WRONG_TYPE, linha,
                tipo_para_string(tipo_then), tipo_para_string(tipo_else));
        exit(ERR_WRONG_TYPE);
    }
}

void verificar_semantica_expressao_primario(entrada_tabela_t *entrada_simbolo, int linha) {
    if (entrada_simbolo && entrada_simbolo->natureza == NAT_FUNCAO) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: função '%s' usada como variável.\n",
                semantica_nome_erro(ERR_FUNCTION), ERR_FUNCTION, linha,
                entrada_simbolo->chave);
        exit(ERR_FUNCTION);
    }
}

void verificar_declaracao_identificador(tabela_simbolos_t *pilha, char *nome, int linha) {
    if (buscar_simbolo(pilha, nome) == NULL) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: identificador '%s' não foi declarado.\n",
                semantica_nome_erro(ERR_UNDECLARED), ERR_UNDECLARED, linha, nome);
        exit(ERR_UNDECLARED);
    }
}

entrada_tabela_t* verificar_chamada_funcao(tabela_simbolos_t *pilha, char *nome, int linha) {
    entrada_tabela_t *entrada = buscar_simbolo(pilha, nome);
    if (entrada == NULL) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: função '%s' não foi declarada.\n",
                semantica_nome_erro(ERR_UNDECLARED), ERR_UNDECLARED, linha, nome);
        exit(ERR_UNDECLARED);
    }
    if (entrada->natureza != NAT_FUNCAO) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: '%s' é uma variável e não pode ser chamada como função.\n",
                semantica_nome_erro(ERR_VARIABLE), ERR_VARIABLE, linha, nome);
        exit(ERR_VARIABLE);
    }
    return entrada;
}

void verificar_argumentos_funcao(entrada_tabela_t *func, asd_tree_t *args, int linha) {
    if (func == NULL) return;
    int num_params = 0;
    for (parametro_t *p = func->parametros; p; p = p->proximo) num_params++;

    int num_args = asd_contar_argumentos(args);

    if (num_args < num_params) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: chamada de função '%s' com menos argumentos que o esperado.\n",
                semantica_nome_erro(ERR_MISSING_ARGS), ERR_MISSING_ARGS, linha, func->chave);
        exit(ERR_MISSING_ARGS);
    }
    if (num_args > num_params) {
        fprintf(stderr,
                "ERRO SEMÂNTICO [%s %d] linha %d: chamada de função '%s' com mais argumentos que o esperado.\n",
                semantica_nome_erro(ERR_EXCESS_ARGS), ERR_EXCESS_ARGS, linha, func->chave);
        exit(ERR_EXCESS_ARGS);
    }

    parametro_t *p = func->parametros;
    asd_tree_t *a = args;
    int pos = 1;
    while (p && a) {
        asd_tree_t *expr = asd_arg_expr(a);
        tipo_dado_t tipo_arg = expr ? expr->tipo : TIPO_NAO_DEFINIDO;
        if (tipo_arg != p->tipo && tipo_arg != TIPO_NAO_DEFINIDO) {
            fprintf(stderr,
                    "ERRO SEMÂNTICO [%s %d] linha %d: argumento %d da função '%s' com tipo incompatível (esperado %s, recebido %s).\n",
                    semantica_nome_erro(ERR_WRONG_TYPE_ARGS), ERR_WRONG_TYPE_ARGS, linha,
                    pos, func->chave, tipo_para_string(p->tipo), tipo_para_string(tipo_arg));
            exit(ERR_WRONG_TYPE_ARGS);
        }
        p = p->proximo;
        a = asd_arg_next(a);
        pos++;
    }
}
