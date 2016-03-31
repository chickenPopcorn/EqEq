SomeCtx = {
  a = { 42; }
  b = { 99; }
}

SomeCtx:find a {
  print("%0.0f\n", a % 2);
}