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

#ifndef DALI_CORE_EXTERN_DEFINITIONS_H
#define DALI_CORE_EXTERN_DEFINITIONS_H

#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <ctime>

#ifndef strerror_r
#define strerror_r(errno, buf, len) strerror_s(buf, len, errno)
#endif

#ifdef __cplusplus

template <typename T>
T __sync_add_and_fetch( volatile T *oldValue, int value )
{
  *oldValue += value;
  return *oldValue;
}

template <typename T>
T __sync_sub_and_fetch( volatile T *oldValue, int value )
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

#endif // __cplusplus

int vasprintf(char** strp, const char* fmt, va_list ap);
int asprintf(char** strp, const char* fmt, ...);

int rand_r( unsigned int* seed );

int setenv( const char* __name, const char* __value, int __replace );

typedef size_t ssize_t;

int mkdir(const char *pathname, unsigned int mode);


#endif // DALI_CORE_EXTERN_DEFINITIONS_H

