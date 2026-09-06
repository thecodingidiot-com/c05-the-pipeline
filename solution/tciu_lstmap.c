#include "libtciutil.h"

t_list  *tciu_lstmap(t_list *lst, void *(*f)(void *),
        void (*del)(void *))
{
    t_list  *result;
    t_list  *node;
    void    *content;

    result = NULL;
    while (lst) {
        content = f(lst->content);          /* transform this node's content */
        if (!content) {
            tciu_lstclear(&result, del);      /* f failed: clean up what we built so far */
            return (NULL);
        }
        node = tciu_lstnew(content);
        if (!node) {
            del(content);                   /* lstnew failed: del the just-transformed content */
            tciu_lstclear(&result, del);      /* clean up the rest */
            return (NULL);
        }
        tciu_lstadd_back(&result, node);
        lst = lst->next;
    }
    return (result);
}
