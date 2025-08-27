CC=gcc
FLEX=flex

DEPS = tokens.h
OBJ = main.o lex.yy.o

all: etapa1

lex.yy.c: scanner.l
	$(FLEX) scanner.l
	
%.o: %.c $(DEPS)
	$(CC) $< -c
		
etapa1: $(OBJ)
	$(CC) $^ -o $@

clean:
	rm lex.yy.c etapa1 main.o lex.yy.o