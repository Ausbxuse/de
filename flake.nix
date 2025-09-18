{
  description = "Custom fonts, themes, apps, scripts as a Home-Manager module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = {self, ...}: {
    homeManagerModules.default = {
      lib,
      pkgs,
      config,
      ...
    }: let
      inherit (lib) mkIf mkEnableOption mkOption types optional;
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
        # no xdg.*

        home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

        # Put *everything* under one home.file definition
        home.file = lib.mkMerge [
          (mkIf config.myFonts.enable {
            ".local/share/fonts" = {
              source = ./fonts;
              recursive = true;
            };
          })
          (mkIf config.myThemes.enable {
            ".local/share/themes" = {
              source = ./themes;
              recursive = true;
            };
          })
          (mkIf config.myApps.enable {
            ".local/share/applications" = {
              source = ./applications;
              recursive = true;
            };
          })
          (mkIf config.myDict.enable {
            ".local/share/stardict" = {
              source = ./stardict;
              recursive = true;
            };
          })
          (mkIf config.myWallpapers.enable {
            ".local/share/wallpapers" = {
              source = ./wallpapers;
              recursive = true;
            };
          })
          (mkIf config.myScripts.enable {
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
          })
        ];
      };
    };
  };
}
