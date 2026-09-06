#include "libtciutil.h"

void    tciu_lstadd_back(t_list **lst, t_list *new)
{
    t_list  *last;

    if (!*lst) {
        *lst = new;             /* empty list: new node becomes the first */
        return;
    }
    last = tciu_lstlast(*lst);    /* walk to the end */
    last->next = new;           /* new->next is already NULL from tciu_lstnew */
}
