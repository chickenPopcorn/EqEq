SomeCtx = {
  a = { c + 40; }
  c = { b + 1; }
}

SomeCtx:find a {

  /* ERROR: cycle: b -> a -> c -> b */
  b = a + 1;

  print("a = %.0f (when b = %.0f)\n", a, b);
}
