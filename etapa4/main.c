// INTEGRANTES DO GRUPO:
// JOÃO CARLOS BATISTA
// RICHARD LEAL RAMOS

#include <stdio.h>
#include "asd.h"
#include "tabela_simbolos.h"

extern int yyparse(void);
extern int yylex_destroy(void);

asd_tree_t *arvore = NULL;
tabela_simbolos_t *pilha_tabelas = NULL;

int main (int argc, char **argv)
{
  // Escopo global
  empilhar_tabela(&pilha_tabelas);

  int ret = yyparse();

   if (arvore) {
    asd_print_graphviz(arvore);
    // Libera AST
    asd_free(arvore);
    arvore = NULL;
  }
  
  // Desempilha e libera TODOS os escopos restantes (se houver)
  while (pilha_tabelas != NULL) {
    desempilhar_tabela(&pilha_tabelas);
  }

  // Finaliza o lexer (Flex)
  yylex_destroy();

  // Importante:
  // - Se houve erro semântico, alguma rotina deve ter chamado exit(ERR_*).
  // - Se não houve erro, yyparse() normalmente retorna 0.
  return ret;
}
