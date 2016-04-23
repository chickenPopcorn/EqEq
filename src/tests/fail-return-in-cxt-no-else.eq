SomeContext = {
  a = { 42.333; }
  b = { if (1){
          3+81;
        }
        else{
          if (4>3){
            cos(20);
          }
        }
      }
}

SomeContext:find b {
  print("%.0f\n", b);
}
