{
  description = "Custom fonts, themes, apps, scripts as a Home-Manager module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = {
    self,
    nixpkgs,
    ...
  }: {
    homeManagerModules.default = {
      lib,
      pkgs,
      config,
      ...
    }: let
      inherit (lib) mkIf mkEnableOption mkOption types optional;

      # Helper: wrap a local directory into a derivation
      mkDataPkg = name: src:
        pkgs.stdenv.mkDerivation {
          inherit name src;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out/share/${name}
            cp -r $src/* $out/share/${name}/
          '';
        };

      fontsPkg = mkDataPkg "fonts" ./fonts;
      themesPkg = mkDataPkg "themes" ./themes;
      appsPkg = mkDataPkg "applications" ./applications;
      dictPkg = mkDataPkg "stardict" ./stardict;
      wallsPkg = mkDataPkg "wallpapers" ./wallpapers;
    in {
      options = {
        myHost = mkOption {
          type = types.nullOr types.str;
          default = null; # e.g., "timy" / "uni"
          description = "Optional per-host selector for extra scripts.";
        };
        myFonts.enable = mkEnableOption "Install custom fonts";
        myThemes.enable = mkEnableOption "Install custom themes";
        myApps.enable = mkEnableOption "Install custom applications/configs";
        myScripts.enable = mkEnableOption "Install custom scripts";
        myDict.enable = mkEnableOption "Install custom dictionaries";
        myWallpapers.enable = mkEnableOption "Install wallpapers";
      };

      config = {
        home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

        xdg.dataFile = lib.mkMerge [
          (mkIf config.myFonts.enable {
            "fonts" = {
              source = "${fontsPkg}/share/fonts";
              recursive = true;
            };
          })
          (mkIf config.myThemes.enable {
            "themes" = {
              source = "${themesPkg}/share/themes";
              recursive = true;
            };
          })
          (mkIf config.myApps.enable {
            "applications" = {
              source = "${appsPkg}/share/applications";
              recursive = true;
            };
          })
          (mkIf config.myDict.enable {
            "stardict" = {
              source = "${dictPkg}/share/stardict";
              recursive = true;
            };
          })
          (mkIf config.myWallpapers.enable {
            "wallpapers" = {
              source = "${wallsPkg}/share/wallpapers";
              recursive = true;
            };
          })
        ];

        # Scripts remain in ~/.local/bin, built via symlinkJoin
        home.file = mkIf config.myScripts.enable {
          ".local/bin" = {
            source = pkgs.symlinkJoin {
              name = "custom-bin";
              paths =
                [./bin]
                ++ optional (config.myHost == "timy") ./bin-timy
                ++ optional (config.myHost == "uni") ./bin-uni;
            };
            recursive = true;
          };
        };
      };
    };
  };
}
