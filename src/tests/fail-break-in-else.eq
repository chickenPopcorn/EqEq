SomeContext = {
  a = { 42.333; }
}
SomeContext:find a {
  if (3>4){
    a = 3;
  }
  else if (4>3){
    a = 4;
    break;
  }
}
