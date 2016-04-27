SomeContext = {
  a = {  
        0;
      }
  b = {
  		  3 + 4;
  	  }
  c = {
        3 - 1;
      }
  d = {
  	    3 % 2;
      }
  e = {
  	    | - 42|;
      }
  f = {
        3 == 1;
      }
  h = {
        3 < 4;
      }
  i = {
        2 ^ 2;
      }
  j = {
        (3 + 4);
      }
  k = {
        |- ((3 + 4) / 2)^2 * ( 18 - 7 ) |;
      }

}

SomeContext:find a {
  print("%.2f\n", a);
  print("%.2f\n", b);
  print("%.2f\n", c);
  print("%.2f\n", d);
  print("%.2f\n", e);
  print("%.2f\n", f);
  print("%.2f\n", h);
  print("%.2f\n", i);
  print("%.2f\n", j);
  print("%.2f\n", k);
}