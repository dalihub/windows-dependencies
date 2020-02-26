/*
 * Copyright (c) 2019 Samsung Electronics Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

// FILE HEADER
#include <extern-definitions.h>

// EXTERNAL INCLUDE
#include <cstdio>
#include <cstdarg>
#include <cstdlib>
#include <random>

#include <windows.h>

namespace
{
  
static unsigned int _seed = -1;
const uint64_t NANOSECONDS_PER_SECOND = 1e+9;
static LARGE_INTEGER _cpuFrequency;
static LARGE_INTEGER *_pCpuFrequency = NULL;

void InternalGetNanoseconds( uint64_t& timeInNanoseconds )
{
  if( nullptr == _pCpuFrequency )
  {
    _pCpuFrequency = &_cpuFrequency;
    QueryPerformanceFrequency( _pCpuFrequency );
  }

  LARGE_INTEGER curTime;
  QueryPerformanceCounter( &curTime );

  timeInNanoseconds = ( curTime.QuadPart * NANOSECONDS_PER_SECOND ) / _pCpuFrequency->QuadPart; // VCC have a look to this as it's different to other Windows versions!!!!!  
}

void Sleep( uint64_t timeInNanoseconds )
{
  //::Sleep( 5 ); VCC have a look to this!!!!!  
  return;
  uint64_t microSecond = timeInNanoseconds / 1000;

  LARGE_INTEGER litmp;
  LONGLONG QPart1, QPart2;
  LONGLONG dfMinus, dfFreq;
  int dfTim;
  QueryPerformanceFrequency( &litmp );
  dfFreq = litmp.QuadPart;  // Get clock frequency of counter
  QueryPerformanceCounter( &litmp );
  QPart1 = litmp.QuadPart;  // Get initial value
  do {
    QueryPerformanceCounter( &litmp );
    QPart2 = litmp.QuadPart;  // Get current value
    dfMinus = QPart2 - QPart1;
    dfTim = dfMinus * 1000000 / dfFreq; // Get delta time in seconds
  } while( dfTim < microSecond );
}

} // namespace

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

int asprintf(char **strp, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    int r = vasprintf(strp, fmt, ap);
    va_end(ap);
    return r;
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

int rand_r( unsigned int* seed )
{
	if (*seed != _seed)
	{
		_seed = *seed;
		srand(_seed);
	}

	return rand();
}

int setenv( const char* __name, const char* __value, int __replace )
{
  int length = strlen(__name) + strlen(__value) + 1u;
  char* envExpression = static_cast<char*>(malloc(length + 1u));
  
  strcpy(envExpression, __name);
  strcat(envExpression, "=");
  strcat(envExpression, __value);
  envExpression[length] = '\0';

  const bool result = _putenv( envExpression );

  free(envExpression);

  return result;
}
