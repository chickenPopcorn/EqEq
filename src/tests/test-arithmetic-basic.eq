BasicMaths = {
  alpha = { 3; }
}

BasicMaths:find alpha {
  print("alpha(%0.f) squared is %0.f\n", alpha, alpha ^ 2);
  print("alpha minus %.0f is %0.f\n", 2, alpha - 2);
  print("alpha plus alpha is %0.f\n", alpha + alpha);
  print("alpha divided by %0.f is %0.2f\n", 2, alpha / 2);
  print("alpha modulo %0.f is %0.f\n", 2, alpha % 2);
  print("negative alpha is %0.f\n", -alpha);

  print("1 is true, 0 is false\n");
  print("alpha negated is %0.f\n", !alpha);
  print("alpha double negated is %0.f\n", !!alpha);

  print("alpha greater than %0.f is %0.f\n", 2, alpha > 2);
  print(
    "alpha greater than or equal to %0.f is %0.f\n",
    2, alpha >= 2);

  print("alpha less than %0.f is %0.f\n", 2, alpha < 2);
  print(
    "alpha less than or equal to %0.f is %0.f\n",
    2, alpha <= 2);

  print(
    "alpha times %0.f plus %0.f is %0.f\n",
    2, 1, alpha * 2 + 1);
}
