#ifndef STD_TO_CDECL_CONVERT_INCLUDED_H
#define STD_TO_CDECL_CONVERT_INCLUDED_H

void* __cdecl internal_malloc( int size );

void __cdecl internal_free( void *buffer );

void __cdecl internal_exit( int exitCode );

#endif