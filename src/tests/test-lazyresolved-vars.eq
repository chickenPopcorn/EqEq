SomeCtx = {
  a = { b + 40; }
  b = { 2 ^ c + 5; }
  c = { 5; }
}

SomeCtx:find a {
  d = 100;
  print("a = %.0f (when b = %.0f)\n", a, b);
}
