#include <dlfcn.h>
#include <windows.h>

bool dlclose( void* handle )
{
  return true;
}

char* dlerror()
{
  return "";
}

void* dlopen( const char *name, int mode )
{
  const char* szStr = name;

  return LoadLibrary( szStr );
}

void* dlsym( void *handle, const char *name )
{
  return GetProcAddress( (HMODULE)handle, "CreateFeedbackPlugin" );
}