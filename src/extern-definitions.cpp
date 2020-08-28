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

int mkdir(const char *pathname, unsigned int mode)
{
	return CreateDirectory(pathname, nullptr);

}
