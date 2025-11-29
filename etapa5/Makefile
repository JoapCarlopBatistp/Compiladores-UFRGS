# INTEGRANTES DO GRUPO:
# JOÃO CARLOS BATISTA
# RICHARD LEAL RAMOS

#-----------------------------------------------------------------

CC=gcc
FLEX=flex
BISON=bison

CFLAGS= -Wall -Werror -g #-fsanitize=address

DEPS = parser.tab.h asd.h valor_token.h tabela_simbolos.h iloc.h errors.h semantica.h
OBJ = lex.yy.o parser.tab.o asd.o main.o tabela_simbolos.o semantica.o iloc.o

ETAPA = etapa5

#-----------------------------------------------------------------

all: $(ETAPA)

parser.tab.c parser.tab.h &: parser.y
	$(BISON) -d parser.y
	
lex.yy.c: scanner.l
	$(FLEX) scanner.l
	
%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)
	
$(ETAPA): $(OBJ)
	$(CC) $(CFLAGS) $^ -o $@

#-----------------------------------------------------------------
	
clean:
	rm -f *.o  lex.yy.c parser.tab.c parser.tab.h *.dot $(ETAPA)

zip:
	tar cvzf $(ETAPA).tgz .
