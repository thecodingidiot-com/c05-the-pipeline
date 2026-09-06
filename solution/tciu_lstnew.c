#include "libtciutil.h"
#include <stdlib.h>

t_list  *tciu_lstnew(void *content)
{
    t_list  *node;

    node = malloc(sizeof(t_list));  /* space for the struct, not the content */
    if (!node)
        return (NULL);
    node->content = content;        /* store the pointer; the caller owns what it points at */
    node->next = NULL;              /* a freshly allocated node is never mid-list */
    return (node);
}
