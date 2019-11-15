#ifndef TIME_API_INCLUDED_H
#define TIME_API_INCLUDED_H

#include <stdint.h>

void InternalGetNanoseconds( uint64_t& timeInNanoseconds );

unsigned int InternalGetCurrentMilliSeconds( void );

#endif
