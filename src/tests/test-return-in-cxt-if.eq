SomeContext = {
  a = { 42.333; }
  b = { if (1){
          cos(42)+log(7);
        }
        else{
          42;
        }
      }
}

SomeContext:find b {
  print("%.0f\n", b);
}
