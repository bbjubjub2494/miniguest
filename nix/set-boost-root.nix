{ pkgs, ... }:

{
  env = [{
    name = "BOOST_ROOT";
    value = pkgs.boost.dev;
  }];
}
