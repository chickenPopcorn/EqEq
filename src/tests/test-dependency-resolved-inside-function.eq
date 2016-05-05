MyCtx = {
  a = {
    dep = 10;
    dep + 1;
  }
}

MyCtx: find a {
  print("a = %0.f\n", a);
}

