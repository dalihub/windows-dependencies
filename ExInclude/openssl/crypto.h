#ifndef _CRY_PTO_H_
#define _CRY_PTO_H_

#define CRYPTO_LOCK 0xFFFFFFFF

typedef struct crypto_threadid_st
{
  void *ptr;
  unsigned long val;
} CRYPTO_THREADID;

int CRYPTO_num_locks();

void CRYPTO_set_id_callback( void( *func )( CRYPTO_THREADID* tid ) );

void CRYPTO_set_locking_callback( void( *func )( int mode, int n, const char* file, int line ) );

#endif