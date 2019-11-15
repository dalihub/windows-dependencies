#include <dirent.h>

#undef UNICODE

#include <errno.h>
#include <windows.h>

struct DIR {
    HANDLE h;
    struct dirent d;
    WIN32_FIND_DATA ffd;
    BOOL valid;
};

DIR *opendir(const char *dirname) {
    DIR *d = malloc(sizeof(DIR));
    int length = strlen(dirname);

    char *name = (char*)malloc((length + 7) * sizeof(char));

    for (size_t i = 0; i < length; i++)
    {
        name[i] = dirname[i];
    }

    name[length++] = '\\';
    name[length++] = '*';
    name[length++] = '.';
    name[length++] = 't';
    name[length++] = 't';
    name[length++] = 'f';
    name[length++] = 0;

    //strcpy_s(name, strlen(dirname), dirname);
    //strcat_s(name, 3, "\\*");

    d->h = FindFirstFile(name, &d->ffd);

    free(name);

    if (!d->h) {
        free(d);
        d = NULL;
        if (GetLastError() == ERROR_FILE_NOT_FOUND)
            errno = ENOENT;
        else
            errno = EACCES;
    }
    d->valid = TRUE;
    return d;
}

struct dirent *readdir(DIR *dirp) {
    if (!dirp->valid) return NULL;
    dirp->d.d_name = dirp->ffd.cFileName;
    if (!FindNextFile(dirp->h, &dirp->ffd)) dirp->valid = FALSE;
    return &dirp->d;
}

int closedir(DIR *dirp) {
    FindClose(dirp->h);
    free(dirp);
    return 0;
}
