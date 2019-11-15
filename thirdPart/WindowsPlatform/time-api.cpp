#include <ctime>
#include <windows.h>
#include <time-api.h>

typedef int clockid_t;

const uint64_t NANOSECONDS_PER_SECOND = 1e+9;

static LARGE_INTEGER _cpuFrequency;
static LARGE_INTEGER *_pCpuFrequency = NULL;

void InternalGetNanoseconds( uint64_t& timeInNanoseconds )
{
  if( NULL == _pCpuFrequency )
  {
    _pCpuFrequency = &_cpuFrequency;
    QueryPerformanceFrequency( _pCpuFrequency );
  }

  LARGE_INTEGER curTime;
  QueryPerformanceCounter( &curTime );

  timeInNanoseconds = (double)curTime.QuadPart / (double)_pCpuFrequency->QuadPart * 1000000000;
}

unsigned int InternalGetCurrentMilliSeconds( void )
{
  if( NULL == _pCpuFrequency )
  {
    _pCpuFrequency = &_cpuFrequency;
    QueryPerformanceFrequency( _pCpuFrequency );
  }

  LARGE_INTEGER curTime;
  QueryPerformanceCounter( &curTime );

  return curTime.QuadPart * 1000 / _pCpuFrequency->QuadPart;
}

void Sleep( uint64_t timeInNanoseconds )
{
  //::Sleep( 5 );
  return;
  uint64_t miroSecond = timeInNanoseconds / 1000;

  LARGE_INTEGER litmp;
  LONGLONG QPart1, QPart2;
  LONGLONG dfMinus, dfFreq;
  int dfTim;
  QueryPerformanceFrequency( &litmp );
  dfFreq = litmp.QuadPart;// 获得计数器的时钟频率
  QueryPerformanceCounter( &litmp );
  QPart1 = litmp.QuadPart;// 获得初始值
  do {
    QueryPerformanceCounter( &litmp );
    QPart2 = litmp.QuadPart;//获得中止值
    dfMinus = QPart2 - QPart1;
    dfTim = dfMinus * 1000000 / dfFreq;// 获得对应的时间值，单位为秒
  } while( dfTim < miroSecond );
}

int clock_gettime( int type, timespec *timeSpec )
{
  uint64_t timeInNanoseconds;
  InternalGetNanoseconds( timeInNanoseconds );

  timeSpec->tv_sec = timeInNanoseconds / NANOSECONDS_PER_SECOND;
  timeSpec->tv_nsec = timeInNanoseconds % NANOSECONDS_PER_SECOND;

  return 0;
}

int clock_nanosleep( clockid_t clock_id, int flags, const struct timespec *reqtp, struct timespec *remtp )
{
  uint64_t curTime;
  InternalGetNanoseconds( curTime );

  uint64_t timeInNanoseconds = reqtp->tv_sec * NANOSECONDS_PER_SECOND + reqtp->tv_sec;
  Sleep( timeInNanoseconds - curTime );

  return 0;
}