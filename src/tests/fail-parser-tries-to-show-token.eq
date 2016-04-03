SomeCtx = {
  a = { b + 40 }
  /** ^ Note we are missing a semi-colon */
}

SomeCtx:find a with b = 2 {
  print("a = %.0f (when b = %.0f)\n", a, b)
}
