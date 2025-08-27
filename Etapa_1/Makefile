CC = gcc
EXECUTABLE = etapa1
SOURCES_C = main.c
SOURCES_L = scanner.l
GENERATED_C = lex.yy.c
OBJECTS = $(SOURCES_C:.c=.o) $(GENERATED_C:.c=.o)

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(OBJECTS) -o $(EXECUTABLE) -lfl

%.o: %.c
	$(CC) -c $< -o $@

$(GENERATED_C): $(SOURCES_L)
	flex $<

.PHONY: clean
clean:
	rm -f $(EXECUTABLE) $(OBJECTS) $(GENERATED_C)

