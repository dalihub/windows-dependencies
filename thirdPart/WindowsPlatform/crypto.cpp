#include "../../ExInclude/openssl/crypto.h"

int CRYPTO_num_locks()
{
  return 1;
}

void CRYPTO_set_id_callback( void( *func )( CRYPTO_THREADID* tid ) )
{

}

void CRYPTO_set_locking_callback( void( *func )( int mode, int n, const char* file, int line ) )
{

}