CC=gcc
FLEX=flex
BISON=bison

CFLAGS=-fsanitize=address

DEPS = parser.tab.h
OBJ = lex.yy.o parser.tab.o main.o

ETAPA = etapa2

all: $(ETAPA)

parser.tab.c parser.tab.h &: parser.y
	$(BISON) -d parser.y
	
lex.yy.c: scanner.l
	$(FLEX) scanner.l
	
%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)
	
$(ETAPA): $(OBJ)
	$(CC) $(CFLAGS) $^ -o $@

#Remove lex.yy.c 
#Remove parser.tab.c
#Remove parser.tab.h
#Remove executável da etapa
clean:
	rm -f *.o  lex.yy.c parser.tab.c parser.tab.h $(ETAPA)
