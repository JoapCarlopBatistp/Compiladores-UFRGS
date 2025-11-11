//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS

#ifndef SEMANTICA_H
#define SEMANTICA_H

#include "errors.h"
#include "tabela_simbolos.h"
#include "asd.h"

const char* semantica_nome_erro(int codigo);
tipo_dado_t inferir_tipo_binario(tipo_dado_t tipo1, tipo_dado_t tipo2);
void verificar_tipo_binario(tipo_dado_t tipo1, tipo_dado_t tipo2, int linha);
void verificar_semantica_parametro(entrada_tabela_t *funcao, int linha);
void verificar_semantica_inicializacao_variavel_local(asd_tree_t *no_literal, valor_t *identificador, tipo_dado_t tipo_declarado, int linha);
void verificar_semantica_variavel_global(tabela_simbolos_t *pilha, valor_t *token, int linha);
void verificar_semantica_variavel_local(tabela_simbolos_t *pilha, valor_t *token, int linha);
void verificar_semantica_declaracao_funcao(tabela_simbolos_t *pilha, valor_t *token, int linha);
void verificar_semantica_atribuicao(entrada_tabela_t *entrada_simbolo, asd_tree_t *expressao, int linha);
void verificar_semantica_retorno(entrada_tabela_t *funcao, asd_tree_t *expressao, int linha);
void verificar_semantica_condicional(asd_tree_t *bloco_then, asd_tree_t *bloco_else, int linha);
void verificar_semantica_expressao_primario(entrada_tabela_t *entrada_simbolo, int linha);
void verificar_declaracao_identificador(tabela_simbolos_t *pilha, char *nome, int linha);
entrada_tabela_t* verificar_chamada_funcao(tabela_simbolos_t *pilha, char *nome, int linha);
void verificar_argumentos_funcao(entrada_tabela_t *func, asd_tree_t *args, int linha);

#endif // SEMANTICA_H
