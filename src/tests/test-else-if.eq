SomeContext = {
  a = { 42.333; }
}

SomeContext:find a {
  if (3>4){
    a = 3;

  }
  else if (4>3){
    a = 4;
    print("%.0f\n", a);
    print("%.0f\n", a + 1);
    print("%.0f\n", a + 2);
  }
  else if (4>3){
    a = 4;
  }
  else if (4>3){
    a = 4;
  }
  else{
    a =0;
  }
  print("%.0f\n", a);
}
