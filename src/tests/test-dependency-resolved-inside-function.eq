MyCtx = {
  a = {
    internalVar = 10;
    internalVar + 1;
  }
}

MyCtx: find a {
  print("a = %0.f\n", a);
}

