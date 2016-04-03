TownCtx = {
  population = { 99; }
}

FarmCtx = {
  acres = { 42; }
}

FarmCtx:find acres {
  print("The %0.2f acres of crops is just enough\n", acres);
}

TownCtx:find population {
  print("to support the %0.0f people living in this in town\n", population);
}
