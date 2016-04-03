SomeCtx() {
  /** ^ Note we don't have a "Ctx()" syntax */

  a = { b + 40; }
}

SomeCtx:find a with b = 2 {
  print("a = %.0f (when b = %.0f)\n", a, b)
}
