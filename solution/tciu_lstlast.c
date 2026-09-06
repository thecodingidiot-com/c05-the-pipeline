#include "libtciutil.h"

t_list  *tciu_lstlast(t_list *lst)
{
    if (!lst)
        return (NULL);          /* empty list has no last node */
    while (lst->next)
        lst = lst->next;        /* advance until next is NULL: that node is last */
    return (lst);
}
