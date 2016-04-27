SomeContext = {
  a = { print("42\n"); 
        42;
      }
}

SomeContext:find a {
  print("%.0f\n", a);
}