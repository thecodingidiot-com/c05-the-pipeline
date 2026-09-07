#include "libtciutil.h"
#include <stdlib.h>

void    tciu_lstdelone(t_list *lst, void (*del)(void *))
{
    del(lst->content);  /* caller's function frees whatever content points at */
    free(lst);          /* we free the node struct itself */
}
