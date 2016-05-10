Foo = {
 b = { c + 3; }
}

Foo: find b {
  c = 3;     /* b == 6 */

  print("`b` is %0.f\n", b);
  b = b + 1; /* b == 7 */
  print("`b = b + 1` is %0.f\n", b);
  b = b + 3; /* b == 10 */
  print("`b = b + 3 is %0.f\n", b);
}
