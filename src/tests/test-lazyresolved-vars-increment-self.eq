Foo = {
 a = { 1; }
 b = { c + 3; }
}

Foo: find a {
  while (a < 3) {
    print("a=%.0f\n", a);
    a = a + 1;
  }
  d = 0;
  while (d < 3) {
    a = d = d + 1;
    print("a=d=%.0f\n", a);
  }

  c = 3;     /* b == 6 */
  print("`b` is %0.f\n", b);
  b = b + 1; /* b == 7 */
  print("`b = b + 1` is %0.f\n", b);
  b = b + 3; /* b == 10 */
  print("`b = b + 3 is %0.f\n", b);
}
