Foo = {
 a = { 1; }
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
}
