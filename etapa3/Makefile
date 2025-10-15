#INTEGRANTES DO GRUPO:
#JOÃO CARLOS BATISTA
#RICHARD LEAL RAMOS

#-----------------------------------------------------------------

CC=gcc
FLEX=flex
BISON=bison

CFLAGS=-fsanitize=address -Wall -Werror -g

DEPS = parser.tab.h asd.h valor_token.h
OBJ = lex.yy.o parser.tab.o asd.o main.o

ETAPA = etapa3

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
	rm -f *.o  lex.yy.c parser.tab.c parser.tab.h $(ETAPA)

zip:
	tar cvzf $(ETAPA).tgz .