SomeCtx = {
  a = { c + 40; }
  c = { b + 1; }
}

SomeCtx:find c {
  /* OK: valid program */
  b = 3;
  print("a = %.0f (when b = %.0f)\n", a, b);

  /* Error: NEW CYCLE! */
  b = a + 1;
  print("a = %.0f (when b depends on a!)\n", a);
}
