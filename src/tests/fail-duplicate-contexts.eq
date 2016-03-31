MyContext = {
  someVal = { 42; }
}

MyContext = {
  unrelatedVal = { 24; }
}

MyContext:find someVal {
  print("someVal is '%.0f'\n", someVal);
}
