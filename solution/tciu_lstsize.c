#include "libtciutil.h"

int     tciu_lstsize(t_list *lst)
{
    int  size;

    size = 0;
    while (lst) {
        lst = lst->next;    /* advance before incrementing: both happen once per node */
        size++;
    }
    return (size);
}
