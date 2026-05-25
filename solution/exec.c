#include <unistd.h>
#include <stdlib.h>
#include "libtci.h"
#include "libtciutil.h"

static char *join_path(const char *dir, const char *name)
{
    size_t  dlen;
    size_t  nlen;
    char    *path;

    dlen = tci_strlen(dir);
    nlen = tci_strlen(name);
    path = malloc(dlen + 1 + nlen + 1);  /* +1 for '/', +1 for '\0' */
    if (!path)
        return (NULL);
    tci_strcpy(path, dir);
    path[dlen] = '/';
    tci_strcpy(path + dlen + 1, name);
    return (path);
}

void    exec_cmd(char **argv)
{
    char    *path_env;
    char    **dirs;
    int     i;
    char    *full;

    if (!argv || !argv[0])
        exit(127);
    if (tci_strchr(argv[0], '/')) {
        execve(argv[0], argv, NULL);  /* absolute or relative path — no PATH search */
        exit(127);
    }
    path_env = getenv("PATH");
    if (!path_env)
        exit(127);
    dirs = tciu_split(path_env, ':');
    if (!dirs)
        exit(127);
    i = 0;
    while (dirs[i]) {
        full = join_path(dirs[i], argv[0]);
        if (full && access(full, X_OK) == 0)
            execve(full, argv, NULL);  /* does not return on success */
        free(full);
        free(dirs[i]);
        i++;
    }
    free(dirs);
    exit(127);
}
