#include "stdlib.h"
#include <StdToCdeclConvert.h>

void* __cdecl internal_malloc( int size )
{
  return malloc( size );
}

void __cdecl internal_free( void *buffer )
{
  free( buffer );
}

void __cdecl internal_exit(int exitCode)
{
  exit(exitCode);
}
