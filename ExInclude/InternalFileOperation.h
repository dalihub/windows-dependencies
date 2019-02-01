#ifndef INTERNAL_FILE_OPERATION_INCLUDE
#define INTERNAL_FILE_OPERATION_INCLUDE

#include <cstdio>

#define fopen Dali::Internal::Platform::InternalFile::FOpen

#define fread Dali::Internal::Platform::InternalFile::FRead
#define fwrite Dali::Internal::Platform::InternalFile::FWrite
#define fseek Dali::Internal::Platform::InternalFile::FSeek

#define fclose Dali::Internal::Platform::InternalFile::FClose
#define ftell Dali::Internal::Platform::InternalFile::FTell
#define feof Dali::Internal::Platform::InternalFile::FEof

#define fmemopen Dali::Internal::Platform::InternalFile::FMemopen

namespace Dali
{
namespace Internal
{
namespace Platform
{
namespace InternalFile
{
  FILE* FOpen( const char *name, const char *mode );

  FILE *FMemopen( void *__s, size_t __len, const char *__modes );

  size_t FRead( void*  _Buffer, size_t _ElementSize, size_t _ElementCount, FILE*  _Stream );
  int FClose( FILE *__stream );

  void FWrite( void *buf, int size, int count, FILE *fp );

  int FSeek( FILE *fp, int offset, int origin );

  int FTell( FILE *fp );

  bool FEof( FILE *fp );
}
}
}
}

#endif