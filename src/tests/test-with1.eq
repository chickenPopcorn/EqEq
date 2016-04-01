SomeCtx = {
  a = { 42; }

}

SomeCtx:find a with b =17 {
  print("%0.0f\n", a);
  print("%0.0f\n", b);
}
