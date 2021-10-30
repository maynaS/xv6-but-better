#include "kernel/types.h"
#include "kernel/param.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{

  if(argc < 3){
    fprintf(2,"Invalid number of Arguments");
    exit(1);
  }

  if (setpriority(atoi(argv[1]),atoi(argv[2])) < 0) {
    fprintf(2, "Incorrect Mask value");
    exit(1);
  }
  exit(0);
}