SomeContext = {
  a = { 42.333; }
}

SomeContext:find a {
  if (3>4){
    a = 3;
  }
  elif (4>3){
    a = 4;
  }
  else{
    a =0;
  }
  print("%.0f\n", a);
}
