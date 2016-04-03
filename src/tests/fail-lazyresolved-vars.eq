SomeCtx = {
  a = { b + 40; }
}

SomeCtx:find a {
  print("a = %.0f (when b = %.0f)\n", a, b)
}
