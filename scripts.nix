{s}: 
{
  ghcidScript = s "dev" "ghcid --command 'cabal new-repl lib:ellisorrery' --allow-eval --warnings";
  testScript = s "test" "cabal run test:ellisorrery-tests";
  hoogleScript = s "hgl" "hoogle serve";
}
