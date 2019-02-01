#ifndef _CUSTOMFILE_INCLUDE_
#define _CUSTOMFILE_INCLUDE_

#include <stdint.h>

namespace CustomFile
{
void* FOpen( const char *name, const char *mode );

int FClose( const void* fp );

void* FMemopen( void* buffer, size_t dataSize, const char * const mode );

int FRead( void* buf, int eleSize, int count, const void *fp );

void FWrite( void *buf, int size, const void *fp );

int FSeek( const void *fp, int offset, int origin );

int FTell( const void *fp );

bool FEof( const void *fp );
}

#endif
