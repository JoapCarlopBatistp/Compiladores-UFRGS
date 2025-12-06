// INTEGRANTES DO GRUPO:
// JOÃO CARLOS BATISTA
// RICHARD LEAL RAMOS

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "iloc.h"
#include "tabela_simbolos.h"

int temporario_count  = 0;
int label_count = 0;

//Malloca temporario e labels
char* novo_temporario()
{
	char* ret = int_to_str(temporario_count, "r");
	temporario_count++;
	return ret;
}

char* nova_label()
{
	char* ret = int_to_str(label_count, "L");
	label_count++;
	return ret;
}


iloc_t criar_iloc(opcode_t opcode, char* campo_1, char* campo_2, char* campo_3)
{
	iloc_t novo_iloc;
	
	novo_iloc.opcode = opcode;
	
	if (campo_1 != NULL)
	{
		novo_iloc.campos[0] = strdup(campo_1);
		
	}
	else 
		novo_iloc.campos[0] = NULL;
	
	if (campo_2 != NULL)
	{
		novo_iloc.campos[1] = strdup(campo_2);
		
	}
	else 
		novo_iloc.campos[1] = NULL;
	
	if (campo_3 != NULL)
	{
		novo_iloc.campos[2] = strdup(campo_3);
	}
	else 
		novo_iloc.campos[2] = NULL;
	
	return novo_iloc;
}

void free_iloc(iloc_t iloc)
{
	for (int i = 0; i < 3; i++)
		free(iloc.campos[i]);
}

iloc_t copia_iloc(iloc_t iloc)
{
	return criar_iloc(iloc.opcode, iloc.campos[0], iloc.campos[1], iloc.campos[2]);
}

void print_iloc(iloc_t iloc)
{
	switch (iloc.opcode){
		case ILOC_ADD:
			printf("add %s, %s => %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_SUB:
			printf("sub %s, %s => %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_MULT:
			printf("mult %s, %s => %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_DIV:
			printf("div %s, %s => %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_RSUBI:
			printf("rsubI %s, %s => %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_LOADI:
			printf("loadI %s => %s", iloc.campos[0], iloc.campos[1]);
			break;
	 	case ILOC_LOADAI:
			printf("loadAI %s, %s => %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_STOREAI:
			printf("storeAI %s => %s, %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_CMP_LT:
			printf("cmp_LT %s, %s -> %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_CMP_LE:
			printf("cmp_LE %s, %s -> %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_CMP_EQ:
			printf("cmp_EQ %s, %s -> %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_CMP_GE:
			printf("cmp_GE %s, %s -> %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_CMP_GT:
			printf("cmp_GT %s, %s -> %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_CMP_NE:
			printf("cmp_NE %s, %s -> %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_AND:
			printf("and %s, %s => %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_OR:
			printf("or %s, %s => %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_CBR:
			printf("cbr %s -> %s, %s", iloc.campos[0], iloc.campos[1], iloc.campos[2]);
			break;
	 	case ILOC_JUMPI:
			printf("jumpI -> %s", iloc.campos[0]);
			break;
	 	case ILOC_LABEL:
			printf("%s: nop", iloc.campos[0]);
			break;
	 	case ILOC_RETURN:
			printf("return %s", iloc.campos[0]);
			break;
	}
	printf("\n");
}

code_t* cria_codigo_vazio()
{
	code_t* ret = NULL;
  	ret = calloc(1, sizeof(code_t));
  	if (ret != NULL){
    		ret->ldc = 0;
    		ret->codigo = NULL;
  	}
  	return ret;
}

void destrutor_codigo(code_t* list)
{
	if (list != NULL){
    		for (int i = 0; i < list->ldc; i++)
      			free_iloc(list->codigo[i]);
      		
      		free(list->codigo);
      		free(list);
    	}
}

void inserir_codigo(code_t* list, iloc_t iloc)
{
	if (list != NULL){
    		list->ldc++;
    		list->codigo= realloc(list->codigo, list->ldc * sizeof(iloc_t));
    		
    		list->codigo[list->ldc-1] = iloc;
  	}
}

void append_lista_codigo(code_t* list1, code_t* list2)
{
	if (list1 != NULL && list2 != NULL){
		// se list2 é vazia, não tem nada pra concatenar à lista 1
		if (list2->ldc == 0) return;
			
		int append_base = list1->ldc;
		
    		list1->ldc += list2->ldc;
    		list1->codigo = realloc(list1->codigo, list1->ldc * sizeof(iloc_t));
    			
    		for (int i = 0; i < list2->ldc; i++)
    			list1->codigo[append_base+i] = copia_iloc(list2->codigo[i]);
  	}
}

void exportar_codigo(code_t* list)
{
    if (list != NULL)
		for (int i = 0; i < list->ldc; i++)
			print_iloc(list->codigo[i]);
}
