//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "asd.h"
#include "errors.h"

asd_tree_t *asd_new(const char *label)
{
  asd_tree_t *ret = NULL;
  ret = calloc(1, sizeof(asd_tree_t));
  if (ret != NULL){
    ret->label = strdup(label);
    ret->number_of_children = 0;
    ret->children = NULL;
    ret->tipo = TIPO_NAO_DEFINIDO;  // Inicializa tipo
  }
  return ret;
}

void asd_free(asd_tree_t *tree)
{
  if (tree != NULL){
    int i;
    for (i = 0; i < tree->number_of_children; i++){
      asd_free(tree->children[i]);
    }
    free(tree->children);
    free(tree->label);
    if (tree->valor != NULL) {
        free(tree->valor->lexema);      // << LIBERA A STRING INTERNA
    }
    free(tree->valor); //Teve que ser adicionado pela mudança do header
    free(tree);
  }else{
    printf("Erro: %s recebeu parâmetro tree = %p.\n", __FUNCTION__, tree);
  }
}

void asd_add_child(asd_tree_t *tree, asd_tree_t *child)
{
  if (tree != NULL && child != NULL){
    tree->number_of_children++;
    tree->children = realloc(tree->children, tree->number_of_children * sizeof(asd_tree_t*));
    tree->children[tree->number_of_children-1] = child;
  }else{
    printf("Erro: %s recebeu parâmetro tree = %p / %p.\n", __FUNCTION__, tree, child);
  }
}

static void _asd_print (FILE *foutput, asd_tree_t *tree, int profundidade)
{
  int i;
  if (tree != NULL){
    fprintf(foutput, "%d%*s: Nó '%s' tem %d filhos:\n", profundidade, profundidade*2, "", tree->label, tree->number_of_children);
    for (i = 0; i < tree->number_of_children; i++){
      _asd_print(foutput, tree->children[i], profundidade+1);
    }
  }else{
    printf("Erro: %s recebeu parâmetro tree = %p.\n", __FUNCTION__, tree);
  }
}

void asd_print(asd_tree_t *tree)
{
  FILE *foutput = stderr;
  if (tree != NULL){
    _asd_print(foutput, tree, 0);
  }else{
    printf("Erro: %s recebeu parâmetro tree = %p.\n", __FUNCTION__, tree);
  }
}

static void _asd_print_graphviz (FILE *foutput, asd_tree_t *tree)
{
  int i;
  if (tree != NULL){
    fprintf(foutput, "  %ld [ label=\"%s\" ];\n", (long)tree, tree->label);
    for (i = 0; i < tree->number_of_children; i++){
      fprintf(foutput, "  %ld -> %ld;\n", (long)tree, (long)tree->children[i]);
      _asd_print_graphviz(foutput, tree->children[i]);
    }
  }else{
    printf("Erro: %s recebeu parâmetro tree = %p.\n", __FUNCTION__, tree);
  }
}

void asd_print_graphviz(asd_tree_t *tree)
{
  FILE *foutput = stdout;
  if (tree != NULL){
    fprintf(foutput, "digraph grafo {\n");
    _asd_print_graphviz(foutput, tree);
    fprintf(foutput, "}\n");
  }else{
    printf("Erro: %s recebeu parâmetro tree = %p.\n", __FUNCTION__, tree);
  }
}

void asd_libera_valor(valor_t *val) {               //Função extra criada para liberar valores do valor_token.h
    if (val != NULL) {
        if (val->lexema != NULL) free(val->lexema);
        free(val);
    }
}


int asd_contar_argumentos(asd_tree_t *args) {
    int n = 0;
    asd_tree_t *p = args;
    while (p != NULL) {
        n++;
        if (p->number_of_children >= 2) {
            p = p->children[1];
        } else {
            p = NULL;
        }
    }
    return n;
}

asd_tree_t* asd_arg_expr(asd_tree_t *arg) {
    return (arg && arg->number_of_children > 0) ? arg->children[0] : NULL;
}

asd_tree_t* asd_arg_next(asd_tree_t *arg) {
    return (arg && arg->number_of_children > 1) ? arg->children[1] : NULL;
}
