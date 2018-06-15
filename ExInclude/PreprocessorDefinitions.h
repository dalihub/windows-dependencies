#ifndef _STDAFX_INCLUDE_
#define _STDAFX_INCLUDE_

#ifdef __cplusplus
#include <../windows-dependencies/ExInclude/atomic>
#include <cstdarg>
#include <ctime>

template <typename T>
T __sync_add_and_fetch( volatile T *oldValue, T value )
{
  *oldValue += value;
  return *oldValue;
}

template <typename T>
T __sync_sub_and_fetch( volatile T *oldValue, T value )
{
  *oldValue -= value;
  return *oldValue;
}


template <typename T>
T __sync_fetch_and_or( volatile T *originalValue, T value )
{
  T ret = *originalValue;
  *originalValue = (T)( *originalValue | value );
  return ret;
}

template <typename T>
T __sync_val_compare_and_swap( volatile T *originalValue, T value1, T value2 )
{
  T ret = *originalValue;
  if( *originalValue == value1 )
  {
    *originalValue = value2;
  }
  return ret;
}

template <typename T>
bool __sync_bool_compare_and_swap( volatile T *originalValue, T value1, T value2 )
{
  if( *originalValue == value1 )
  {
    *originalValue = value2;
    return true;
  }
  else
  {
    return false;
  }
}

template <typename T>
T __sync_lock_test_and_set( volatile T *originalValue, T value )
{
  T ret = *originalValue;
  *originalValue = value;
  return ret;
}

template <typename T>
T __sync_fetch_and_xor( T *originalValue, T value )
{
  T ret = *originalValue;
  *originalValue = (T)( *originalValue ^ value );
  return ret;
}

static unsigned int __sync_fetch_and_xor( unsigned int *originalValue, int value )
{
  unsigned int ret = *originalValue;
  *originalValue = (int)( *originalValue ^ value );
  return ret;
}

#endif

#ifndef __GNUC__
#define __attribute__(x)
#endif

#ifdef ERROR
#undef ERROR
#endif

#ifdef CopyMemory
#undef CopyMemory
#endif

#ifdef TRANSPARENT
#undef TRANSPARENT
#endif

#define M_E 2.71828182845904523536
#define M_LOG2E 1.44269504088896340736
#define M_LOG10E 0.434294481903251827651
#define M_LN2 0.693147180559945309417
#define M_LN10 2.30258509299404568402
#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define M_PI_4 0.785398163397448309616
#define M_1_PI 0.318309886183790671538
#define M_2_PI 0.636619772367581343076
#define M_2_SQRTPI 1.12837916709551257390
#define M_SQRT2 1.41421356237309504880
#define M_SQRT1_2 0.707106781186547524401

#define __atomic_base atomic

#define strtok_r strtok_s

#define PTW32_STATIC_LIB 1

#define __restrict__

#define S_ISREG

#define DALI_GLES_VERSION 20

#define lstat stat

#ifdef __cplusplus
#define _CPP11

extern int vasprintf( char **ptr, const char *format, va_list ap );

#define CLOCK_MONOTONIC 0
#define TIMER_ABSTIME 0

typedef int clockid_t;

extern int clock_gettime( int type, timespec *timeSpec );

extern int clock_nanosleep( clockid_t clock_id, int flags, const struct timespec *reqtp, struct timespec *remtp );
#endif

#endif