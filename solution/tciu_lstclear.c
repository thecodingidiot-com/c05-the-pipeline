#include "libtciutil.h"

void    tciu_lstclear(t_list **lst, void (*del)(void *))
{
    if (!lst || !*lst)
        return;
    tciu_lstclear(&(*lst)->next, del);  /* free the rest first */
    tciu_lstdelone(*lst, del);           /* then free this node */
    *lst = NULL;                        /* null the caller's pointer */
}
