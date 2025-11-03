//INTEGRANTES DO GRUPO:
//JOÃO CARLOS BATISTA
//RICHARD LEAL RAMOS

#ifndef VALOR_TOKEN_H
#define VALOR_TOKEN_H

typedef enum { IDENTIFICADOR, LITERAL } tipo_token_t;
typedef struct {
    char* lexema;
    int linha_token;
    tipo_token_t tipo;
} valor_t;

#endif // VALOR_TOKEN_H