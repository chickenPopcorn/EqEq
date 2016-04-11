SomeContext = {
  a = { 42.333; }
}

SomeContext:find a {
  print("%.0f\n", -a);
  print("%.0f\n", - 1);
  print("%.0f\n", - a);
  print("%.0f\n", 1 - -a);
  print("%.0f\n", 1 --a);
  print("%.0f\n", a+1);
  print("%.0f\n", 1 + a);
}