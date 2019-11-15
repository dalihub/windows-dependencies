#include "stdlib.h"
#include <string.h>

void*  __cdecl internal_malloc( int size )
{
  return malloc( size );
}

void __cdecl internal_free( void *buffer )
{
  free( buffer );
}

void* __cdecl internal_bsearch( void const* _Key, void const* _Base, size_t _NumOfElements, size_t _SizeOfElements, _CoreCrtNonSecureSearchSortCompareFunction _CompareFunction )
{
  return bsearch( _Key, _Base, _NumOfElements, _SizeOfElements, _CompareFunction );
}

void __cdecl internal_memcpy( void *dest, void *src, int length )
{
  memcpy( dest, src, length );
}
