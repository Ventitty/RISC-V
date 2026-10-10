{
  description = "Environnement de développement FPGA pour Tang Primer 25K (Gowin EDA)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = let
        fhs = pkgs.buildFHSEnv {
          name = "gowin-fhs-env";
          targetPkgs = p: with p; [
            # Dépendances système et graphiques pour l'IDE Gowin
            glibc
            zlib
            freetype
            fontconfig
            libglvnd
            libxkbcommon
            dbus
            udev
            nss
            nspr

            # Bibliothèques X11 / Qt pour l'interface graphique de l'IDE
            xorg.libX11
            xorg.libXext
            xorg.libXrender
            xorg.libXft
            xorg.libXi
            xorg.libXrandr
            xorg.libXcursor
            xorg.libXfixes
            xorg.libXcomposite
            xorg.libXdamage
            qt5.qtbase
            qt5.qtsvg

            # Outils de développement matériel et flashage
            openfpgaloader
            ghdl
            gtkwave
            gtksourceview4
          ];
          profile = ''
            export QT_QPA_PLATFORM=xcb
            echo "--- Environnement FPGA Tang Primer 25K prêt ---"
            echo "Lance l'IDE avec : ~/gowin/IDE/bin/gw_ide"
          '';
        };
      in fhs.env;
    };
}
