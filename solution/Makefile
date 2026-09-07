NAME        = pipeline
LIBNAME     = libtci.a
UTIL        = libtciutil.a

CC          = gcc
CFLAGS      = -Wall -Wextra -Werror -std=c99 -D BUFFER_SIZE=32
BUILD       = -g -O0
RELEASE     = -O2
AR          = ar rcs

SRCS        = tci_memset.c tci_memcpy.c tci_memmove.c tci_memchr.c tci_bzero.c \
              tci_isascii.c tci_isalpha.c tci_isdigit.c tci_isalnum.c \
              tci_isspace.c tci_isupper.c tci_islower.c tci_isprint.c \
              tci_toupper.c tci_tolower.c \
              tci_strlen.c tci_strcpy.c tci_strncpy.c tci_strlcpy.c tci_strlcat.c \
              tci_strcmp.c tci_strncmp.c tci_strchr.c tci_strrchr.c tci_strnstr.c \
              tci_atoi.c \
              tci_calloc.c tci_strdup.c tci_strndup.c \
              tci_printf.c \
              tci_getline.c

UTIL_SRCS   = tciu_split.c \
              tciu_lstnew.c tciu_lstadd_front.c tciu_lstadd_back.c \
              tciu_lstsize.c tciu_lstlast.c \
              tciu_lstdelone.c tciu_lstclear.c tciu_lstiter.c tciu_lstmap.c

PIPE_SRCS   = main.c exec.c pipeline.c

OBJS        = $(SRCS:.c=.o)
UTIL_OBJS   = $(UTIL_SRCS:.c=.o)
PIPE_OBJS   = $(PIPE_SRCS:.c=.o)

.PHONY: all release clean fclean re

all: $(LIBNAME) $(UTIL) $(NAME)

$(LIBNAME): $(OBJS)
	$(AR) $(LIBNAME) $(OBJS)

$(UTIL): $(UTIL_OBJS)
	$(AR) $(UTIL) $(UTIL_OBJS)

$(NAME): $(PIPE_OBJS) $(LIBNAME) $(UTIL)
	$(CC) $(BUILD) $(PIPE_OBJS) -L. -ltci -ltciutil -o $(NAME)

%.o: %.c
	$(CC) $(CFLAGS) $(BUILD) -c $< -o $@

release:
	@$(MAKE) --no-print-directory fclean
	@$(MAKE) --no-print-directory BUILD="$(RELEASE)"
	strip --strip-debug $(NAME) $(LIBNAME) $(UTIL)

clean:
	rm -f $(OBJS) $(UTIL_OBJS) $(PIPE_OBJS)

fclean: clean
	rm -f $(LIBNAME) $(UTIL) $(NAME)

re: fclean all
