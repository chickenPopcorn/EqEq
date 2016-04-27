SomeContext = {
  a = { 42.333; }
  b = { if (3>2){
          a;
        }
        else {

        }
      }
}

SomeContext:find a {
  print("%.0f\n", -3);
}
