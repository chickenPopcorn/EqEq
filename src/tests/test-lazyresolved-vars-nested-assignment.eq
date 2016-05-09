Foo = {
  a = { 3; }
}

Foo:find a {
  x = y = 3; /* y should be marked resolved before evaluated against x */

  print("x=%0.f\n", x);
}
