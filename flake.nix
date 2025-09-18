{
  description = "Custom fonts, themes, apps, scripts as a Home-Manager module";

  outputs = {self, ...}: {
    homeManagerModules.default = {
      lib,
      pkgs,
      config,
      ...
    }: let
      cfg = config.my;
    in {
      options.my = {
        enable = lib.mkEnableOption "Enable my extras";
        host = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null; # e.g., "timy" / "uni"
          description = "Optional per-host selector for extra scripts.";
        };
        fonts.enable = lib.mkEnableOption "Install custom fonts";
        themes.enable = lib.mkEnableOption "Install custom themes";
        apps.enable = lib.mkEnableOption "Install custom applications/configs";
        scripts.enable = lib.mkEnableOption "Install custom scripts";
        dict.enable = lib.mkEnableOption "Install custom dictionaries";
        wallpapers.enable = lib.mkEnableOption "Install wallpapers";
      };

      config = lib.mkIf cfg.enable {
        xdg.enable = lib.mkDefault true;

        home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

        xdg.dataFile = lib.mkMerge [
          (lib.mkIf cfg.fonts.enable {"fonts".source = ./fonts;})
          (lib.mkIf cfg.themes.enable {"themes".source = ./themes;})
          (lib.mkIf cfg.apps.enable {"applications".source = ./applications;})
          (lib.mkIf cfg.dict.enable {"stardict".source = ./stardict;})
          (lib.mkIf cfg.wallpapers.enable {"wallpapers".source = ./wallpapers;})
        ];

        home.file.".local/bin" = lib.mkIf cfg.scripts.enable {
          source = pkgs.symlinkJoin {
            name = "custom-bin";
            paths =
              [./bin]
              ++ lib.optional (cfg.host == "timy") ./bin-timy
              ++ lib.optional (cfg.host == "uni") ./bin-uni;
          };
          recursive = true;
          # executable = true  # not needed for directories
        };
      };
    };
  };
}
