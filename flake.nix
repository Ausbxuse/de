{
  description = "Custom fonts, themes, apps, and scripts as a Home-Manager module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = f:
      builtins.listToAttrs (map (system: {
          name = system;
          value = f system;
        })
        systems);
  in {
    homeManagerModules.default = {
      config,
      lib,
      hostname,
      pkgs,
      ...
    }: {
      options = {
        myFonts.enable = lib.mkEnableOption "Install custom fonts";
        myThemes.enable = lib.mkEnableOption "Install custom themes";
        myApps.enable = lib.mkEnableOption "Install custom applications/configs";
        myScripts.enable = lib.mkEnableOption "Install custom scripts";
      };

      config = {
        home.file = {
          "${config.xdg.dataHome}/fonts" = lib.mkIf config.myFonts.enable {
            source = ./fonts;
            recursive = true;
          };

          "${config.xdg.dataHome}/themes" = lib.mkIf config.myThemes.enable {
            source = ./themes;
            recursive = true;
          };

          "${config.xdg.dataHome}/applications" = lib.mkIf config.myApps.enable {
            source = ./applications;
            recursive = true;
          };

          "${config.home.homeDirectory}/.local/bin" = lib.mkIf config.myScripts.enable {
            source = pkgs.symlinkJoin {
              name = "custom-bin";
              paths =
                [
                  ./bin
                ]
                ++ lib.optional (hostname == "timy") ./bin-timy
                ++ lib.optional (hostname == "uni") ./bin-uni;
            };
            recursive = true;
            executable = true;
          };
        };
      };
    };
  };
}
