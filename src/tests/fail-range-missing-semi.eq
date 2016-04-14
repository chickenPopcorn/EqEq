SomeCtx = {
  a = { 42; }
  b = { 32; }
  c = { 10; }
}

SomeCtx:find a with b = 3; c in range(3) { /* missing semicolon after 'range(3)' */
  print("%0.0f\n", a);
}