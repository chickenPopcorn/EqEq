SomeContext = {
  a = { 42.333; }
  b = { if (1){
          3+81;
        }  
        else{
          42+1;
        }
      }
}

SomeContext:find b {
  print("%.0f\n", b);
}
