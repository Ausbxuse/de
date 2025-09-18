{
  description = "Custom fonts, themes, apps, scripts as a Home-Manager module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  outputs = {self, ...}: {
    homeManagerModules.default = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = {
        myHost = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null; # e.g., "timy" / "uni"
          description = "Optional per-host selector for extra scripts.";
        };
        myFonts.enable = lib.mkEnableOption "Install custom fonts";
        myThemes.enable = lib.mkEnableOption "Install custom themes";
        myApps.enable = lib.mkEnableOption "Install custom applications/configs";
        myScripts.enable = lib.mkEnableOption "Install custom scripts";
        myDict.enable = lib.mkEnableOption "Install custom dictionaries";
        myWallpapers.enable = lib.mkEnableOption "Install wallpapers";
      };

      config = {
        xdg.enable = lib.mkDefault true;

        home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

        xdg.dataFile = lib.mkMerge [
          (lib.mkIf config.myFonts.enable {"fonts".source = ./fonts;})
          (lib.mkIf config.myThemes.enable {"themes".source = ./themes;})
          (lib.mkIf config.myApps.enable {"applications".source = ./applications;})
          (lib.mkIf config.myDict.enable {"stardict".source = ./stardict;})
          (lib.mkIf config.myWallpapers.enable {"wallpapers".source = ./wallpapers;})
        ];

        home.file.".local/bin" = lib.mkIf config.my.scripts.enable {
          source = pkgs.symlinkJoin {
            name = "custom-bin";
            paths =
              [./bin]
              ++ lib.optional (config.my.host == "timy") ./bin-timy
              ++ lib.optional (config.my.host == "uni") ./bin-uni;
          };
          recursive = true;
          # executable = true  # not needed for directories
        };
      };
    };
  };
}
