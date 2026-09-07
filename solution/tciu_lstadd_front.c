#include "libtciutil.h"

void    tciu_lstadd_front(t_list **lst, t_list *new)
{
    new->next = *lst;   /* point new at the current front (NULL if list is empty) */
    *lst = new;         /* update the caller's front pointer */
}
