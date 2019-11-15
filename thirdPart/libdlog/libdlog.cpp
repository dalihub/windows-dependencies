#include <stdio.h>
#include <string>

using namespace std;

#ifdef __cplusplus
extern "C"
#endif
int __declspec( dllexport ) dlog_print(int priority, const char *tag, const char *message, const char *file, const char *func, int line, const char * msg )
{
  string log = "[";
  log += tag;
  log += "] ";

  log += message;

  log += "\n\n";

  printf( log.c_str(), file, func, line, msg );
  return 0;
}
