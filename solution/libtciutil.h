#ifndef LIBTCIUTIL_H
# define LIBTCIUTIL_H

# include "libtci.h"

char    **tciu_split(char const *s, char sep);

/* lists */
typedef struct s_list {
    void            *content;
    struct s_list   *next;
}   t_list;

t_list  *tciu_lstnew(void *content);
void     tciu_lstadd_front(t_list **lst, t_list *new);
void     tciu_lstadd_back(t_list **lst, t_list *new);
int      tciu_lstsize(t_list *lst);
t_list  *tciu_lstlast(t_list *lst);
void     tciu_lstdelone(t_list *lst, void (*del)(void *));
void     tciu_lstclear(t_list **lst, void (*del)(void *));
void     tciu_lstiter(t_list *lst, void (*f)(void *));
t_list  *tciu_lstmap(t_list *lst, void *(*f)(void *),
        void (*del)(void *));

#endif
