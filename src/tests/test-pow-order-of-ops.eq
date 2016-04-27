Foo = {
 a = { 2; }
 b = { 3; }
}

Foo:find a {
  print("a ^ b ^ 2 = %.0f\n", a ^ b ^ 2);
}
