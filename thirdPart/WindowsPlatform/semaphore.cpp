#include "semaphore.h"
#include <Windows.h>

void sem_init( sem_t *sem, int p1, int p2 )
{
  *sem = (long)::CreateSemaphore(NULL, 0, 1, NULL);
}

void sem_post( sem_t *sem )
{
  ::ReleaseSemaphore( reinterpret_cast<HWND>( *sem ), 1, 0 );
}

void sem_wait( sem_t *sem )
{
  ::WaitForSingleObject( reinterpret_cast<HWND>( *sem ), INFINITE );
}

long sem_timedwait( sem_t *sem, timespec *time )
{
  long dwMilliseconds = time->tv_sec * 1000000 + time->tv_nsec / 1000;

  return ::WaitForSingleObject( reinterpret_cast<HWND>( *sem ), dwMilliseconds );
}
