Gcd = {
  a = 10;
  b = 20;
  gcd = {
   if (b == 0) {
     a;
   }
   else if (a == 0) {
     b;
   }
   else if (a == b ){
    a;
   }

   if (a > b) {
     a = b;
     b = a % b;
   }
   else {
     a = b % a;
     b = a;
   }
   gcd;
   }
}

Gcd:find gcd {
  print("gcd between 10 and 20 is %0.f\n", gcd);
}
