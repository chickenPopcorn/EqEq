SomeContext = {
  a = { 42; }

}

SomeContext:find a {
  print("%0.2f\n", cos(a));
  print("%0.2f\n", sin(a));
  print("%0.2f\n", tan(a));
  print("%0.2f\n", sqrt(a));
  print("%0.2f\n", log(a));
}
