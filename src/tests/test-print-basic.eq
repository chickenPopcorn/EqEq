FarmTownCtx = {
  acres = { 42; }
  population = { 99; }
}

FarmTownCtx:find population {
  print("%0.0f people live in this in town\n", population);
  print("The %0.2f acres of crops is just enough\n", acres);
}
