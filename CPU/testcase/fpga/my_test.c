#include "io.h"
// input: 1 2 3 4
int a[9];
int *pa = a;
int main()
{
    int *pb[9];
	int i;
	pb[0] = pa;
	pb[1] = pa;
	pb[2] = pa;
	pb[3] = pa;
	outlln(9);
	for (i = 0; i < 9; i++)
		pb[0][i] = inl();
	for (i = 0; i < 9; i++)
		outl(pb[1][i]);
	println("");
	for (i = 0; i < 9; i++)
		pb[2][i] = 0;
	for (i = 0; i < 9; i++)
		outl(pb[3][i]);
}
