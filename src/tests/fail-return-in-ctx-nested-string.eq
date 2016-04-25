SomeContext = {
  b = { if (5>2){
            "This";
        }
        else{
            "is illegal!";
        }
      }
}

SomeContext:find b {
  print("%.0f\n", b);
}
