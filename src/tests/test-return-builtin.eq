SomeContext = {
  a = {  
        cos(42);
      }
  b = {
  		log(42);
  	  }
  c = {
  	    sin(42);
      }
  d = {
  	    tan(42);
      }
  e = {
  	    sqrt(42);
      }
}

SomeContext:find a {
  print("%.2f\n", a);
  print("%.2f\n", b);
  print("%.2f\n", c);
  print("%.2f\n", d);
  print("%.2f\n", e);
}