#ifndef FMEMOPEN_INCLUDE
#define FMEMOPEN_INCLUDE

#include <cstdio>

#define fmemopen Dali::Internal::Platform::InternalFile::FMemopen

namespace Dali
{
namespace Internal
{
namespace Platform
{
namespace InternalFile
{
  FILE *FMemopen( void *__s, size_t __len, const char *__modes );
}
}
}
}

#endif