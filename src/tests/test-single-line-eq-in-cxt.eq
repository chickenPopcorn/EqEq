SomeContext = {
  a = 42.333;
  b = 41.333;
  c = 40.333;
}

SomeContext:find a {
  print("%.0f\n", a);
  print("%.0f\n", b);
  print("%.0f\n", c);
}
