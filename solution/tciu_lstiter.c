#include "libtciutil.h"

void    tciu_lstiter(t_list *lst, void (*f)(void *))
{
    while (lst) {
        f(lst->content);    /* call f on this node's content; f owns any side effects */
        lst = lst->next;    /* navigation only — does not modify the list */
    }
}
