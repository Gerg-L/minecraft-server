{ lib, pkgs, ... }:
{
  minecraft-servers.fear = {
    enable = false;
    java = pkgs.javaPackages.compiler.temurin-bin.jdk-17;
    script = "${lib.getExe pkgs.bash} /minecraft-servers/fear/run.sh";
    ports = {
      TCP = [ 25565 ]; # for people to connect
      UDP = [ 24454 ]; # simple voice chat mod
    };
  };
}
