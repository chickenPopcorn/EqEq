Euclid = {
  gcd = {
    if (0 == b) {
      a;  // solution is a
    } elif (a == 0) {
      b;  // solution is b
    }

    if (a > b) {
      a = b, b = a % b;
      // note: multiple assignments on single line
    } else {
      a = b % a, b = a;
    }
    gcd; // solution is gcd w/the current a and b
  }
}

Euclid: find gcd {
  a = 2;
  b = 14;
  print("%.0f", a, b, gcd);

  a = 3;
  b = 15;
  print("%.0f", a, b, gcd);

  a = 99;
  b = 121;
  print("%.0f", a, b, gcd);
}
