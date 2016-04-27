Foo = {
 a = { 1; }
}

Foo: find a {
  while (a < 3) {
    print("a=%.0f\n", a);
    a = a + 1;
  }

  b = 0;
  while (b < 3) {
    a = b = b + 1;
    print("a=b=%.0f\n", a);
  }
}
