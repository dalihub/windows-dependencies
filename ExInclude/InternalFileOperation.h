#ifndef INTERNAL_FILE_OPERATION_INCLUDE
#define INTERNAL_FILE_OPERATION_INCLUDE

#include <cstdio>

#include <CustomFile.h>

#define fopen CustomFile::FOpen

#define fread CustomFile::FRead
#define fwrite CustomFile::FWrite
#define fseek CustomFile::FSeek

#define fclose CustomFile::FClose
#define ftell CustomFile::FTell
#define feof CustomFile::FEof

#define fmemopen CustomFile::FMemopen

#endif