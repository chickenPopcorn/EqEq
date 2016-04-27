Foo = {
 a = { 1; }
}

Foo: find a {
  while (a < 3) {
    print("%.0f\n", a);
    a = 3;
  }
}
