#include <unistd.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <stdio.h>
#include "libtciutil.h"

void    exec_cmd(char **argv);

static int  **alloc_pipes(int n)
{
    int     **pipes;
    int     i;

    if (n == 0)
        return (NULL);
    pipes = malloc(n * sizeof(int *));
    if (!pipes)
        exit(1);
    i = 0;
    while (i < n) {
        pipes[i] = malloc(2 * sizeof(int));
        if (!pipes[i] || pipe(pipes[i]) < 0) {
            perror("pipe");
            exit(1);
        }
        i++;
    }
    return (pipes);
}

static void free_pipes(int **pipes, int n)
{
    int i;

    if (!pipes)
        return;
    i = 0;
    while (i < n) {
        free(pipes[i]);
        i++;
    }
    free(pipes);
}

int     run_pipeline(t_list *cmds, int infd, int outfd)
{
    int     n;
    int     **pipes;
    pid_t   *pids;
    t_list  *node;
    int     k;
    int     j;
    int     stdin_fd;
    int     stdout_fd;
    int     status;
    int     last_status;

    n = tciu_lstsize(cmds);
    pipes = alloc_pipes(n - 1);
    pids = malloc(n * sizeof(pid_t));
    if (!pids)
        exit(1);

    node = cmds;
    k = 0;
    while (node) {
        stdin_fd  = (k == 0)     ? infd      : pipes[k - 1][0];
        stdout_fd = (k == n - 1) ? outfd     : pipes[k][1];

        pids[k] = fork();
        if (pids[k] < 0) { perror("fork"); exit(1); }
        if (pids[k] == 0) {
            dup2(stdin_fd, STDIN_FILENO);
            dup2(stdout_fd, STDOUT_FILENO);
            j = 0;
            while (j < n - 1) {
                close(pipes[j][0]);
                close(pipes[j][1]);
                j++;
            }
            if (infd != STDIN_FILENO)
                close(infd);
            if (outfd != STDOUT_FILENO)
                close(outfd);
            exec_cmd((char **)node->content);
        }

        node = node->next;
        k++;
    }

    j = 0;
    while (j < n - 1) {
        close(pipes[j][0]);
        close(pipes[j][1]);
        j++;
    }

    last_status = 0;
    k = 0;
    while (k < n) {
        waitpid(pids[k], &status, 0);
        if (k == n - 1 && WIFEXITED(status))
            last_status = WEXITSTATUS(status);
        k++;
    }

    free_pipes(pipes, n - 1);
    free(pids);
    return (last_status);
}
