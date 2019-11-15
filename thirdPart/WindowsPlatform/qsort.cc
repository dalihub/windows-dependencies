#include <string.h>
#include <stdlib.h>
#include <math.h>

typedef int( __stdcall* _InternalCoreCrtNonSecureSearchSortCompareFunction )( void const*, void const* );
static _InternalCoreCrtNonSecureSearchSortCompareFunction func = NULL;

int __cdecl _PtFuncCompare( void const *p1, void const *p2 )
{
  if( NULL != func )
  {
    return func( p1, p2 );
  }
  else
  {
    return 0;
  }
}

void __cdecl qsort( void*  _Base, unsigned int _NumOfElements, unsigned int _SizeOfElements, _InternalCoreCrtNonSecureSearchSortCompareFunction _CompareFunction )
{
  func = _CompareFunction;
  qsort( _Base, _NumOfElements, _SizeOfElements, _PtFuncCompare );
}