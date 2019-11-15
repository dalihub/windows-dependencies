#include <cstdio>
#include <cstdarg>
#include <cstdlib>

int vasprintf( char **ptr, const char *format, va_list ap )
{
  int len;

  len = _vscprintf_p( format, ap ) + 1;
  *ptr = (char *)malloc( len * sizeof( char ) );
  if( !*ptr )
  {
    return -1;
  }

  return _vsprintf_p( *ptr, len, format, ap );
}