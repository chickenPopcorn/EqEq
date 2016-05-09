Foo = {
  a = { 40; }
}

Foo:find a {
  b = 2;
  print("a + b is %0.f\n", a + b);
}
