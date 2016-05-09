MyCtx = {
  a = { b + d ^ 2; }
}

d = 5;

MyCtx: find a {
  b = 0;
  print("a = %.0f\n", a);

  b = 5;
  d = 2;
  print("a = %.0f\n", a);

  c = 100;
  a = c;
  print("a = c = %.0f\n", a);
}
