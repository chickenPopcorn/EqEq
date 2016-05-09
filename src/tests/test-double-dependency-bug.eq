Foo = {
  twice = b + b;
}

Foo:find twice {
  b = 10;
  print("twice = %0.f [b = %0.f]\n", twice, b);
}
