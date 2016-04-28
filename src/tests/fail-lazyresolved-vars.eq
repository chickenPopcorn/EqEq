SomeCtx = {
  a = { b + 40; }
  c = { 3; }
}

SomeCtx:find c {
  print("a = %.0f\n", a);
}
