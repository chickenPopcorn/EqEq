SomeCtx = {
  a = { 42; }
  b = { 32; }
}

SomeCtx:find a range(3); { /* the 'in' in front of range is missing  */
  print("%0.0f\n", a);
}