SomeCtx = {
  a = { 42; }
  b = { 4.2e-4; }
  c = { 0.42; }
  d = { .42; }
  e = { 0e1; }

}

SomeCtx:find a {
  print("%0.0f\n", a);
  printf("%0.5f\n", b);
  printf("%0.2f\n", c);
  printf("%0.2f\n", d);
  printf("%0.1f\n", e);
}
