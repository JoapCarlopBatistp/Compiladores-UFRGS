// INTEGRANTES DO GRUPO:
// JOÃO CARLOS BATISTA
// RICHARD LEAL RAMOS

#ifndef _ASD_H_
#define _ASD_H_

#include "valor_token.h"
#include "tabela_simbolos.h"
#include "iloc.h"

typedef struct asd_tree {
  char *label;
  valor_t *valor;
  tipo_dado_t tipo; // Tipo de dado do nó
  int number_of_children;
  char* temp;
  code_t* codigo;
  struct asd_tree **children;
} asd_tree_t;

/*
 * Função asd_new, cria um nó sem filhos com o label informado.
 */
asd_tree_t *asd_new(const char *label);

/*
 * Função asd_tree, libera recursivamente o nó e seus filhos.
 */
void asd_free(asd_tree_t *tree);

/*
 * Função asd_add_child, adiciona child como filho de tree.
 */
void asd_add_child(asd_tree_t *tree, asd_tree_t *child);

/*
 * Função asd_print, imprime recursivamente a árvore.
 */
void asd_print(asd_tree_t *tree);

/*
 * Função asd_print_graphviz, idem, em formato DOT
 */
void asd_print_graphviz (asd_tree_t *tree);

void asd_libera_valor(valor_t *val);

int asd_contar_argumentos(asd_tree_t *args);
asd_tree_t* asd_arg_expr(asd_tree_t *arg);
asd_tree_t* asd_arg_next(asd_tree_t *arg);

#endif //_ASD_H_
