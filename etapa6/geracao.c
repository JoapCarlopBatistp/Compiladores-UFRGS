// INTEGRANTES DO GRUPO:
// JOÃO CARLOS BATISTA
// RICHARD LEAL RAMOS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>

#include "geracao.h"
#include "iloc.h"

/* Estrutura que carrega todas as informacoes necessárias 
para traduzir o ILOC para assembly. */
typedef struct {
    const tabela_simbolos_t *tabela_global;
    const char *nome_funcao;
    int tamanho_area_local;
    int tamanho_area_temporarios;
    int tamanho_frame;
    bool tem_retorno;
    char rotulo_retorno[32];
} contexto_assembly_t;

/* Sobe a pilha de escopos e retorna o escopo global (raiz). */
static const tabela_simbolos_t* obter_tabela_global(const tabela_simbolos_t *pilha) {
    const tabela_simbolos_t *atual = pilha;
    while (atual != NULL && atual->anterior != NULL)
        atual = atual->anterior;
    return atual;
}

/* Confere se a entrada pertence ao segmento de dados global. */
static bool entrada_eh_global(const entrada_tabela_t *entrada) {
    return entrada != NULL 
        && entrada->base != NULL
        && strcmp(entrada->base, "rbss") == 0
        && entrada->deslocamento != NULL;
}

/* Emite diretivas do segmento de dados com todas as variaveis globais. */
static void imprimir_segmento_dados(const tabela_simbolos_t *global) {
    printf("\t.data\n");
    if (global == NULL) {
        printf("\n");
        return;
    }

    /* Percorre apenas entradas globais para emitir simbolos e reserva de 4 bytes (int). */
    for (const entrada_tabela_t *entrada = global->primeiro;
         entrada != NULL;
         entrada = entrada->proximo) {
        if (entrada_eh_global(entrada)) {
            printf("\t.globl %s\n", entrada->chave);
            printf("\t.align 4\n");
            printf("\t.type %s, @object\n", entrada->chave);
            printf("\t.size %s, 4\n", entrada->chave);
            printf("%s:\n", entrada->chave);
            printf("\t.long 0\n\n");
        }
    }

    printf("\n");
}

/* Valida se a string segue o padrao de registrador ILOC (r<numero>). */
static bool nome_eh_registrador_iloc(const char *nome) {
    if (nome == NULL || nome[0] != 'r') {
        return false;
    }

    const unsigned char segundo = (unsigned char)nome[1];
    if (!isdigit(segundo)) {
        return false;
    }

    for (const char *ponteiro = nome + 2; *ponteiro != '\0'; ++ponteiro) {
        if (!isdigit((unsigned char)*ponteiro)) {
            return false;
        }
    }
    return true;
}

/* Extrai o numero do registrador ILOC (ex.: r7 -> 7). */
static int indice_do_registrador_iloc(const char *nome) {
    if (!nome_eh_registrador_iloc(nome)) {
        return -1;
    }
    return (int)strtol(nome + 1, NULL, 10);
}

/* Converte texto de deslocamento de variavel local em deslocamento negativo relativo a %rbp. */
static int deslocamento_local(const char *offset_texto) {
    if (offset_texto == NULL) {
        return 0;
    }
    int valor = (int)strtol(offset_texto, NULL, 10);
    return -(valor + 4);
}

static int deslocamento_temporario(const contexto_assembly_t *contexto, const char *nome) {
    int indice = indice_do_registrador_iloc(nome);
    if (indice < 0) {
        fprintf(stderr, "Erro interno: registrador ILOC invalido '%s'.\n", nome ? nome : "<null>");
        exit(1);
    }
    /* Temporarios ficam apos a area de variaveis locais, cada um com 4 bytes. */
    return -contexto->tamanho_area_local - ((indice + 1) * 4);
}

/* Mapeia um deslocamento do segmento global para o nome da variavel correspondente. */
static const char* nome_global_por_deslocamento(const tabela_simbolos_t *global, const char *offset) {
    if (global == NULL || offset == NULL) {
        return NULL;
    }
    int alvo = (int)strtol(offset, NULL, 10);
    /* Busca pelo simbolo com deslocamento */
    for (const entrada_tabela_t *entrada = global->primeiro;
         entrada != NULL;
         entrada = entrada->proximo) {
        if (entrada_eh_global(entrada)) {
            int desloc = (int)strtol(entrada->deslocamento, NULL, 10);
            if (desloc == alvo) {
                return entrada->chave;
            }
        }
    }
    return NULL;
}

/* Move o valor de um temporario ILOC da pilha para um registrador x86. */
static void carregar_temporario(const contexto_assembly_t *contexto, const char *nome_temporario, const char *registrador_cpu) {
    int deslocamento_temporario_bytes = deslocamento_temporario(contexto, nome_temporario);
    printf("\tmovl %d(%%rbp), %s\n", deslocamento_temporario_bytes, registrador_cpu);
}

/* Salva o valor de um registrador x86 no slot reservado ao temporario ILOC. */
static void armazenar_temporario(const contexto_assembly_t *contexto, const char *nome_temporario, const char *registrador_cpu) {
    int deslocamento_temporario_bytes = deslocamento_temporario(contexto, nome_temporario);
    printf("\tmovl %s, %d(%%rbp)\n", registrador_cpu, deslocamento_temporario_bytes);
}

/* Carrega uma variavel (local via rfp ou global via rbss) para um registrador x86. */
static void carregar_memoria(const contexto_assembly_t *contexto, const char *base_memoria, const char *deslocamento_textual, const char *registrador_cpu) {
    if (base_memoria == NULL) {
        return;
    }

    /* Diferencia acesso local (rfp) de global (rbss). */
    if (strcmp(base_memoria, "rfp") == 0) {
        int desloc = deslocamento_local(deslocamento_textual);
        printf("\tmovl %d(%%rbp), %s\n", desloc, registrador_cpu);
    } else if (strcmp(base_memoria, "rbss") == 0) {
        const char *nome = nome_global_por_deslocamento(contexto->tabela_global, deslocamento_textual);
        if (nome == NULL) {
            fprintf(stderr, "Erro interno: variavel global para offset %s inexiste.\n", deslocamento_textual ? deslocamento_textual : "<null>");
            exit(1);
        }
        printf("\tmovl %s(%%rip), %s\n", nome, registrador_cpu);
    } else {
        fprintf(stderr, "Base de memoria '%s' nao suportada.\n", base_memoria);
        exit(1);
    }
}

/* Armazena um registrador x86 em uma variavel (local via rfp ou global via rbss). */
static void armazenar_memoria(const contexto_assembly_t *contexto, const char *base_memoria, const char *deslocamento_textual, const char *registrador_cpu) {
    if (base_memoria == NULL) {
        return;
    }

    /* Diferencia acesso local (rfp) de global (rbss). */
    if (strcmp(base_memoria, "rfp") == 0) {
        int desloc = deslocamento_local(deslocamento_textual);
        printf("\tmovl %s, %d(%%rbp)\n", registrador_cpu, desloc);
    } else if (strcmp(base_memoria, "rbss") == 0) {
        const char *nome = nome_global_por_deslocamento(contexto->tabela_global, deslocamento_textual);
        if (nome == NULL) {
            fprintf(stderr, "Erro interno: variavel global para offset %s inexiste.\n", deslocamento_textual ? deslocamento_textual : "<null>");
            exit(1);
        }
        printf("\tmovl %s, %s(%%rip)\n", registrador_cpu, nome);
    } else {
        fprintf(stderr, "Base de memoria '%s' nao suportada.\n", base_memoria);
        exit(1);
    }
}

/* Converte uma string numerica em inteiro (para operandos imediatos). */
static int ler_imediato(const char *texto) {
    return texto ? (int)strtol(texto, NULL, 10) : 0;
}

/* Pre-analisa o codigo ILOC para calcular tamanhos do frame e rotulo de retorno. */
static void analisar_codigo(const code_t *codigo, contexto_assembly_t *contexto) {
    int maior_indice_registrador = -1;
    int maior_deslocamento_local = -1;

    if (codigo != NULL) {
        for (int i = 0; i < codigo->ldc; ++i) {
            const iloc_t *instrucao = &codigo->codigo[i];
            for (int campo = 0; campo < 3; ++campo) {
                if (nome_eh_registrador_iloc(instrucao->campos[campo])) {
                    int indice_registrador = indice_do_registrador_iloc(instrucao->campos[campo]);
                    if (indice_registrador > maior_indice_registrador) {
                        maior_indice_registrador = indice_registrador;
                    }
                }
            }

            const char *base_memoria = NULL;
            const char *deslocamento_textual = NULL;
            if (instrucao->opcode == ILOC_LOADAI) {
                base_memoria = instrucao->campos[0];
                deslocamento_textual = instrucao->campos[1];
            } else if (instrucao->opcode == ILOC_STOREAI) {
                base_memoria = instrucao->campos[1];
                deslocamento_textual = instrucao->campos[2];
            }

            if (base_memoria != NULL && strcmp(base_memoria, "rfp") == 0 && deslocamento_textual != NULL) {
                int valor = (int)strtol(deslocamento_textual, NULL, 10);
                if (valor > maior_deslocamento_local) {
                    maior_deslocamento_local = valor;
                }
            }
        }
    }

    contexto->tamanho_area_local = (maior_deslocamento_local >= 0) ? maior_deslocamento_local + 4 : 0;
    contexto->tamanho_area_temporarios = (maior_indice_registrador >= 0) ? (maior_indice_registrador + 1) * 4 : 0;
    contexto->tamanho_frame = contexto->tamanho_area_local + contexto->tamanho_area_temporarios;
    int alinhamento = contexto->tamanho_frame % 16;
    if (alinhamento != 0) {
        contexto->tamanho_frame += 16 - alinhamento;
    }

    static int retorno_seq = 0;
    /* Rotulo de retorno unico por traducao. */
    snprintf(contexto->rotulo_retorno, sizeof(contexto->rotulo_retorno), ".Lreturn_%d", retorno_seq++);
}

/* Emite o prologo da funcao principal (salva rbp e reserva o frame). */
static void emitir_prologo(const contexto_assembly_t *contexto) {
    printf("\tpushq %%rbp\n");
    printf("\tmovq %%rsp, %%rbp\n");
    if (contexto->tamanho_frame > 0) {
        printf("\tsubq $%d, %%rsp\n", contexto->tamanho_frame);
    }
}

/* Emite o epilogo da funcao principal (restaura o frame e retorna). */
static void emitir_epilogo(const contexto_assembly_t *contexto) {
    printf("\tleave\n");
    printf("\tret\n");
    printf("\t.size %s, .-%s\n", contexto->nome_funcao, contexto->nome_funcao);
}

/* Traduz instrucoes cmp_* do ILOC para a sequencia cmp/setX em x86-64. */
static void traduzir_comparacao(const contexto_assembly_t *contexto, const iloc_t *instrucao, const char *sufixo) {
    carregar_temporario(contexto, instrucao->campos[0], "%eax");
    carregar_temporario(contexto, instrucao->campos[1], "%edx");
    printf("\tcmpl %%edx, %%eax\n");
    printf("\tset%s %%al\n", sufixo);
    printf("\tmovzbl %%al, %%eax\n");
    armazenar_temporario(contexto, instrucao->campos[2], "%eax");
}

/* Mapeia uma instrucao ILOC especifica para instrucoes x86-64 equivalentes. */
static void traduzir_instrucao(const iloc_t *instrucao, contexto_assembly_t *contexto) {
    switch (instrucao->opcode) {
        case ILOC_ADD:
            /* Soma registradores temporarios e salva resultado. */
            carregar_temporario(contexto, instrucao->campos[0], "%eax");
            carregar_temporario(contexto, instrucao->campos[1], "%edx");
            printf("\taddl %%edx, %%eax\n");
            armazenar_temporario(contexto, instrucao->campos[2], "%eax");
            break;
        case ILOC_SUB:
            /* Subtracao de temporarios. */
            carregar_temporario(contexto, instrucao->campos[0], "%eax");
            carregar_temporario(contexto, instrucao->campos[1], "%edx");
            printf("\tsubl %%edx, %%eax\n");
            armazenar_temporario(contexto, instrucao->campos[2], "%eax");
            break;
        case ILOC_MULT:
            /* Multiplicacao de inteiros. */
            carregar_temporario(contexto, instrucao->campos[0], "%eax");
            carregar_temporario(contexto, instrucao->campos[1], "%edx");
            printf("\timull %%edx, %%eax\n");
            armazenar_temporario(contexto, instrucao->campos[2], "%eax");
            break;
        case ILOC_DIV:
            /* Divisao assinada usa edx:eax. */
            carregar_temporario(contexto, instrucao->campos[0], "%eax");
            printf("\tcltd\n");
            carregar_temporario(contexto, instrucao->campos[1], "%ecx");
            printf("\tidivl %%ecx\n");
            armazenar_temporario(contexto, instrucao->campos[2], "%eax");
            break;
        case ILOC_RSUBI: {
            /* imediato - temporario. */
            int imediato = ler_imediato(instrucao->campos[1]);
            printf("\tmovl $%d, %%eax\n", imediato);
            carregar_temporario(contexto, instrucao->campos[0], "%edx");
            printf("\tsubl %%edx, %%eax\n");
            armazenar_temporario(contexto, instrucao->campos[2], "%eax");
            break;
        }
        case ILOC_LOADI: {
            /* Carrega imediato para temporario. */
            int imediato = ler_imediato(instrucao->campos[0]);
            printf("\tmovl $%d, %%eax\n", imediato);
            armazenar_temporario(contexto, instrucao->campos[1], "%eax");
            break;
        }
        case ILOC_LOADAI:
            /* Le de memoria (local/global) para temporario. */
            carregar_memoria(contexto, instrucao->campos[0], instrucao->campos[1], "%eax");
            armazenar_temporario(contexto, instrucao->campos[2], "%eax");
            break;
        case ILOC_STOREAI:
            /* Escreve temporario na memoria (local/global). */
            carregar_temporario(contexto, instrucao->campos[0], "%eax");
            armazenar_memoria(contexto, instrucao->campos[1], instrucao->campos[2], "%eax");
            break;
        case ILOC_CMP_LT:
            traduzir_comparacao(contexto, instrucao, "l");
            break;
        case ILOC_CMP_LE:
            traduzir_comparacao(contexto, instrucao, "le");
            break;
        case ILOC_CMP_EQ:
            traduzir_comparacao(contexto, instrucao, "e");
            break;
        case ILOC_CMP_GE:
            traduzir_comparacao(contexto, instrucao, "ge");
            break;
        case ILOC_CMP_GT:
            traduzir_comparacao(contexto, instrucao, "g");
            break;
        case ILOC_CMP_NE:
            traduzir_comparacao(contexto, instrucao, "ne");
            break;
        case ILOC_AND:
            /* AND logico numerico (0/1). */
            carregar_temporario(contexto, instrucao->campos[0], "%eax");
            carregar_temporario(contexto, instrucao->campos[1], "%edx");
            printf("\tandl %%edx, %%eax\n");
            printf("\tcmpl $0, %%eax\n");
            printf("\tsetne %%al\n");
            printf("\tmovzbl %%al, %%eax\n");
            armazenar_temporario(contexto, instrucao->campos[2], "%eax");
            break;
        case ILOC_OR:
            /* OR logico numerico (0/1). */
            carregar_temporario(contexto, instrucao->campos[0], "%eax");
            carregar_temporario(contexto, instrucao->campos[1], "%edx");
            printf("\torl %%edx, %%eax\n");
            printf("\tcmpl $0, %%eax\n");
            printf("\tsetne %%al\n");
            printf("\tmovzbl %%al, %%eax\n");
            armazenar_temporario(contexto, instrucao->campos[2], "%eax");
            break;
        case ILOC_CBR:
            /* Desvio condicional baseado em 0/nao-zero. */
            carregar_temporario(contexto, instrucao->campos[0], "%eax");
            printf("\tcmpl $0, %%eax\n");
            printf("\tjne %s\n", instrucao->campos[1]);
            printf("\tjmp %s\n", instrucao->campos[2]);
            break;
        case ILOC_JUMPI:
            /* Desvio incondicional. */
            printf("\tjmp %s\n", instrucao->campos[0]);
            break;
        case ILOC_LABEL:
            printf("%s:\n", instrucao->campos[0]);
            break;
        case ILOC_RETURN:
            /* Move valor de retorno para eax e pula para epilogo. */
            carregar_temporario(contexto, instrucao->campos[0], "%eax");
            printf("\tjmp %s\n", contexto->rotulo_retorno);
            contexto->tem_retorno = true;
            break;
    }
}

/* Ponto de entrada: recebe a AST com codigo ILOC e emite o assembly completo. */
void gerar_codigo_assembly(asd_tree_t *programa, tabela_simbolos_t *pilha) {
    /* Segmento de dados com globais. */
    const tabela_simbolos_t *tabela_global = obter_tabela_global(pilha);
    imprimir_segmento_dados(tabela_global);
    printf("\t.text\n");

    /* Simplificacao: assumimos que o programa tem uma unica funcao principal. */
    const char *nome_funcao = "main";

    printf("\t.globl %s\n", nome_funcao);
    printf("\t.type %s, @function\n", nome_funcao);
    printf("%s:\n", nome_funcao);

    /* Calcula frame e gera corpo. */
    contexto_assembly_t contexto = (contexto_assembly_t){0};
    contexto.tabela_global = tabela_global;
    contexto.nome_funcao = nome_funcao;
    analisar_codigo(programa ? programa->codigo : NULL, &contexto);
    emitir_prologo(&contexto);

    if (programa != NULL && programa->codigo != NULL) {
        for (int i = 0; i < programa->codigo->ldc; ++i) {
            traduzir_instrucao(&programa->codigo->codigo[i], &contexto);
        }
    }

    if (!contexto.tem_retorno) {
        printf("\tmovl $0, %%eax\n");
    }

    /* Rotulo de retorno compartilhado pelo fluxo. */
    printf("%s:\n", contexto.rotulo_retorno);
    emitir_epilogo(&contexto);
}
