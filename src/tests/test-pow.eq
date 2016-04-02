SomeCtx = {
  a = { 2; }
  b = { 9; }
}

SomeCtx:find a {
  print("%0.0f\n", a ^ 2);
  print("%0.0f\n", b ^ 0.5);
}

