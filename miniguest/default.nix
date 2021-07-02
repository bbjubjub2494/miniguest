{ substituteAll, nixFlakes, writers }:
writers.writeBashBin "miniguest" (substituteAll {
  src = ./miniguest.bash;
  inherit nixFlakes;
})
