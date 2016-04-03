Foo1 = {
  a = { 1; }
}

Foo1: find a {
  print("previous a = %.0f\n", a);
  a = 3;
  print("after a = %.0f\n", a);
}

Foo1: find a {
  print("previous a = %.0f\n", a);
  a = 5;
  print("after a = %.0f\n", a);
}
