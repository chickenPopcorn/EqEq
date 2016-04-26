SomeCtx = {
  a = { b + 40; }
  b = { 2 ^ c + 5; }
  c = { 5; }
  f = { 1/3; } /* never used */
}

SomeCtx:find a {
  d = 100; /* never used */
  print("a = %.0f (when b = %.0f)\n", a, b);

  b = 2; /* now: a depends on b and b is independent */
  print("a = %.0f (when b = %.0f)\n", a, b);
}
