// INTEGRANTES DO GRUPO:
// JOÃO CARLOS BATISTA
// RICHARD LEAL RAMOS

#include <stdio.h>
#include <stdlib.h> // Necessário para exit
#include "asd.h"
#include "tabela_simbolos.h"
#include "iloc.h"
#include "geracao.h"

extern int yyparse(void);
extern int yylex_destroy(void);

// extern FILE *yyin; 

asd_tree_t *arvore = NULL;
tabela_simbolos_t *pilha_tabelas = NULL;

int main (int argc, char **argv)
{
  if (argc >= 3) {
      FILE *arquivo_saida = freopen(argv[2], "w", stdout);
      if (arquivo_saida == NULL) {
          fprintf(stderr, "Erro ao abrir o arquivo de saída %s.\n", argv[2]);
          exit(1);
      }
  }

  // Escopo global
  empilhar_tabela(&pilha_tabelas);

  int ret = yyparse();

  if (arvore != NULL)
    gerar_codigo_assembly(arvore, pilha_tabelas);

  fflush(stdout);

  asd_free(arvore);
  
  while(pilha_tabelas != NULL)
    desempilhar_tabela(&pilha_tabelas);
   
  yylex_destroy();

  return ret;
}
