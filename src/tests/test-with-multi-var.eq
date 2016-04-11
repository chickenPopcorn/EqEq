SomeCtx = {
  a = { 42; }
  b = { 32; }
  c = { 22; }

}

SomeCtx:find a with b =17; c = 7; {
  print("%0.0f\n", a);
  print("%0.0f\n", b);
  print("%0.0f\n", c);
}
