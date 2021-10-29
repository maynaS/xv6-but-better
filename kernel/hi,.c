/* Example using #elif directive by TechOnTheNet.com */

#include <stdio.h>

#define YEARS_OLD 12

int main()
{
   #if YEARS_OLD <= 10
   printf("TechOnTheNet is a great resource.\n");
   #elif YEARS_OLD > 10
   printf("TechOnTheNet is over %d years old.\n", YEARS_OLD);
   #endif

   return 0;
}