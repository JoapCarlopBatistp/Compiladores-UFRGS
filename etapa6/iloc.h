// INTEGRANTES DO GRUPO:
// JOÃO CARLOS BATISTA
// RICHARD LEAL RAMOS
#ifndef _ILOC_H_
#define _ILOC_H_

typedef enum opcode {
 	ILOC_ADD,
 	ILOC_SUB,	
 	ILOC_MULT,	
 	ILOC_DIV,	
 	ILOC_RSUBI,	
 	ILOC_LOADI,	    
 	ILOC_LOADAI,	
 	ILOC_STOREAI,	
 	ILOC_CMP_LT,	
 	ILOC_CMP_LE,	
 	ILOC_CMP_EQ,	
 	ILOC_CMP_GE,	
 	ILOC_CMP_GT,	
 	ILOC_CMP_NE,	
 	ILOC_AND,	
 	ILOC_OR,	
 	ILOC_CBR,	
 	ILOC_JUMPI,
 	ILOC_LABEL,
 	ILOC_RETURN
} opcode_t;

char* novo_temporario();        //String para temporário
char* nova_label();             //String para label


typedef struct iloc_inst {
	opcode_t opcode;
  	char *campos[3];
} iloc_t;

iloc_t criar_iloc(opcode_t opcode, char* campo_1, char* campo_2, char* campo_3);        //Cria o iloc
void free_iloc(iloc_t iloc);                //Dá free
iloc_t copia_iloc(iloc_t iloc);             //Copia o iloc
void fprint_iloc(FILE* stream, iloc_t iloc);              //Escreve no arquivo de saida

//==============================================================

typedef struct code_list {
  	int ldc;  //linhas
  	iloc_t *codigo;
} code_t;

code_t* cria_codigo_vazio();                                //Código vazio
void destrutor_codigo(code_t* lista);                        //Destrutor da lista de código  
void inserir_codigo(code_t* lista, iloc_t iloc);             //Insere a instrução
void append_lista_codigo(code_t* lista1, code_t* lista2);     //Append de lista 2 em lista 1
void exportar_codigo(code_t* list);                         //Gera o .iloc final

//==============================================================

#endif //_ILOC_H_
