SomeContext = {
  a = { 42.333; }
}

SomeContext:find a {
  print("%.0f\n", -a);
  print("%.0f\n", - 1);
  print("%.4f\n", - 1.2e-3);
  print("%.4f\n", - -1.2e-3);
  print("%.4f\n", - 1.2e-3 --0.27e10);
  print("%.4f\n", a --0.27e10);
  print("%.0f\n", - a);
  print("%.0f\n", 1 - -a);
  print("%.0f\n", 1 --a);
  print("%.0f\n", a+1);
  print("%.0f\n", a+ -1);
  print("%.0f\n", 1 + a);
}