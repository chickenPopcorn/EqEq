SomeCtx = {
  a = { 2; }
  b = { 99; }
}

SomeCtx:find a {
  print("%0.0f\n", a^2);
}

