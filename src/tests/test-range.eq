SomeCtx = {
  a = { 42; }
  b = { 32; }
}

SomeCtx:find a {
   print("print for simple find\n");
   print("a = %0.0f\n", a);
   print("b = %0.0f\n", b);
}

SomeCtx:find a with c in range(0,3,1); {
  print("print for find with range (0,3,1)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}

SomeCtx:find a with c in range(2,-1,-1); {
  print("print for find with range (2,-1,-1)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}

SomeCtx:find a with c in range(-1,-1, 1); {
  print("print for find with range (-1,-1,1)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}

SomeCtx:find a with b = 10; c in range(0,4,2); {
  print("print for find with range (0,4,2)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}

SomeCtx:find a with b = 10; c in range(0,2); {
  print("print for find with range (0,2)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}

SomeCtx:find a with b = 10; c in range(2); {
  print("print for find with range (2)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}


/** EXPECTED OUTPUT
#include <stdio.h>

double SomeCtx_a_0 (){
return (double) (42.);
}

double SomeCtx_b_1 (){
return (double) (32.);
}
void find_SomeCtx_0(double c){
// if it's a range, then `c` is used as a function argument instead => no declaration for `c`
// double c;
// TODO: check if there is any other places that affected by `c` being an argument
double b;
double a;

b = SomeCtx_b_1();

a = SomeCtx_a_0();

//-----gen_finddecl_stmt-----
b = 10.;
printf("print for find with range (2)\n");
printf("a = %0.0f\n", (double) (a));
printf("b = %0.0f\n", (double) (b));
printf("c = %0.0f\n", (double) (c));
}


// some other stuff
 */
