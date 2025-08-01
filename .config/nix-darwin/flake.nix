{
  description = "Edgar nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, }:
  let
    configuration = { pkgs, config, ... }: {

      system.primaryUser = "edgar";
      nixpkgs.config.allowUnfree = true;

      environment.systemPackages =
        [ 
          pkgs.neovim
          pkgs.awscli2
          pkgs.brave
          pkgs.tree
          pkgs.mkalias # used to setup alias in the Application folder
          pkgs.stow  # manage symlinks for dotfiles
          pkgs.docker
          pkgs.git-credential-manager
          pkgs.pgcli
          pkgs.dbeaver-bin
          pkgs.bat

          # herramientas de GO
          pkgs.go
          pkgs.delve
          pkgs.gopls
          pkgs.sonar-scanner-cli
          
          pkgs.go-mockery
          pkgs.mockgen

          pkgs.goose
          # fin herramientas de GO
          

        ];

      homebrew = {
        enable = true;
        brews = [
          "mas" # check appstore application id. mas search WhatsApp
          "gpg" # manage gpg keys
          "fzf" # fuzzy finder on the command line + other stuff
          "golangci-lint"
          "aws-sam-cli"
          "nvm"
          "gum"
          "typescript"
        ];
        casks = [
          "hammerspoon" # automate taks in macOS
          "the-unarchiver"
          "notion"
        ];
        masApps = {
          "WhatsApp" = 310633997;
        };
        onActivation.cleanup = "zap";
      };

      fonts.packages = 
        [
          pkgs.texlivePackages.jetbrainsmono-otf
        ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
      '';

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      programs.zsh.enable = true;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#empro
    darwinConfigurations."empro" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "edgar";

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;
          };
        }
      ];
    };

    darwinPackages = self.darwinConfigurations."empro".pkgs;
  };
}
