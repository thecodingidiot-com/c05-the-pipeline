NAME    = pipeline
CC      = gcc
CFLAGS  = -Wall -Wextra -g -std=c99 -D BUFFER_SIZE=32

SRCS    = main.c exec.c pipeline.c
OBJS    = $(SRCS:.c=.o)

.PHONY: all clean fclean re

all: $(NAME)

$(NAME): $(OBJS)
	$(CC) $(OBJS) -L. -ltciutil -ltci -o $(NAME)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS)

fclean: clean
	rm -f $(NAME)

re: fclean all
