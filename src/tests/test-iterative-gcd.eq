Gcd = {

  gcd = {
    a= 10;
    b=20;
    while (a != b) {
      if (a > b) {a = a - b;}
      else {b = b - a;}
    }
    a;
   }
}

Gcd:find gcd {
  print("gcd between 10 and 20 is %0.f\n", gcd);
}
