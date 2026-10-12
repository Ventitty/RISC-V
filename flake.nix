{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        ghdl-llvm
        surfer
        (quartus-prime-lite.override {
          supportedDevices = [ "Cyclone V" "MAX 10 FPGA" ];
        })
      ];
    };
  };
}
