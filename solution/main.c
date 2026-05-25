#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include "libtci.h"
#include "libtciutil.h"

int     run_pipeline(t_list *cmds, int infd, int outfd);

static char **parse_cmd(char *str)
{
    return (tciu_split(str, ' '));
}

static void free_cmd(void *ptr)
{
    char    **argv;
    int     i;

    argv = (char **)ptr;
    i = 0;
    while (argv[i])
        free(argv[i++]);
    free(argv);
}

static int is_heredoc(char *arg)
{
    return (access(arg, F_OK) != 0);
}

static int heredoc(char *limiter)
{
    int     fd[2];
    char    *line;

    if (pipe(fd) < 0) { perror("pipe"); exit(1); }
    line = tci_getline(STDIN_FILENO);
    while (line) {
        if (tci_strncmp(line, limiter, tci_strlen(limiter)) == 0) {
            free(line);
            break;
        }
        write(fd[1], line, tci_strlen(line));
        write(fd[1], "\n", 1);
        free(line);
        line = tci_getline(STDIN_FILENO);
    }
    close(fd[1]);
    return (fd[0]);
}

int main(int argc, char **argv)
{
    int     infd;
    int     outfd;
    t_list  *cmds;
    t_list  *node;
    int     i;
    int     status;

    if (argc < 4) {
        tci_printf("usage: ./pipeline infile|LIMITER cmd... outfile\n");
        return (1);
    }

    if (is_heredoc(argv[1]))
        infd = heredoc(argv[1]);
    else {
        infd = open(argv[1], O_RDONLY);
        if (infd < 0) { perror(argv[1]); return (1); }
    }

    outfd = open(argv[argc - 1], O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (outfd < 0) { perror(argv[argc - 1]); close(infd); return (1); }

    cmds = NULL;
    i = 2;
    while (i < argc - 1) {
        node = tciu_lstnew(parse_cmd(argv[i]));
        if (!node) { close(infd); close(outfd); return (1); }
        tciu_lstadd_back(&cmds, node);
        i++;
    }

    status = run_pipeline(cmds, infd, outfd);

    close(infd);
    close(outfd);
    tciu_lstclear(&cmds, free_cmd);
    return (status);
}
