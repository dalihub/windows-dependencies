#include "stdlib.h"

void InternalFree( void* _Block )
{
  ::free( _Block );
}
