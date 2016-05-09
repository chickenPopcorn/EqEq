SomeCtx = {
  a = { b + 40; }
  b = { 2 ^ c + 5; }
  c = { 5; }
  f = { 1/3; } /* never used */
}

SomeCtx:find a {
  d = 100; /* never used */
  print("a = %.0f (when b = %.0f)\n", a, b);

  b = 2;
  /* now: a depends on b which is independent */
  print("a = %.0f (when b = %.0f)\n", a, b);
}


/********** EXPECTED OUTPUT **********
#include <math.h>
#include <stdio.h>

double SomeCtx_a_0(double b) {
  return (double) (b + 40.);
}

double SomeCtx_b_1(double c) {
  return (double) (pow(2., c) + 5.);
}

double SomeCtx_c_2 = (double) (5.);

double SomeCtx_f_3 = (double) (1. / 3.);

void find_SomeCtx_0() {
  double f;
  double c;
  double b;
  double a;
  double d;

  c = SomeCtx_c_2;

  b = SomeCtx_b_1(c);

  a = SomeCtx_a_0(b);

  f = SomeCtx_f_3;

  d = 100.;

  printf("a = %.0f (when b = %.0f)\n", (double) (a), (double) (b));

  b = 2.;

  a = SomeCtx_a_0(b);

  printf("a = %.0f (when b = %.0f)\n", (double) (a), (double) (b));
}

void find_SomeCtx_0_range(){
  find_SomeCtx_0();
}


int main() {
  find_SomeCtx_0_range ();
  return 0;
}
 */
