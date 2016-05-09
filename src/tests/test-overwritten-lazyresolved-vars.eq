MyCtx = {
  a = { b + 5; }
}

MyCtx: find a {
  b = 5;
  print("a = %.0f (when b = %.0f)\n", a, b);

  b = 20;
  print("a = %.0f (when b = %.0f)\n", a, b);

  c = 100;
  a = c;
  print("a = c = %.0f\n", a);
}
