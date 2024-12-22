{
  description = ''
		[REPO] github.com/verziet/.system
		[INSTALL] soon ...
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable"; # unstable branch, is default
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz"; # latest stable branch, use for build in case of problems
    nixpkgs-master.url = "github:nixos/nixpkgs?ref=master"; # master branch, don't think i'll ever use it tho

    home-manager = {
      # url = "https://flakehub.com/f/nix-community/home-manager/*.tar.gz"; # latest stable branch, in case of problems
      url = "https://github.com/nix-community/home-manager/archive/master.tar.gz"; # latest unstable branch
      inputs.nixpkgs.follows = "nixpkgs"; # not duping nixpkgs
    };

		#gonna move these to a separate inputs file
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    ags.url = "github:aylur/ags"; 
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-master,
    home-manager,
    ...
  } @ inputs: let
    # FIXME settings values
    users = [
      "verz"
    ];

    hosts = [
      "leet"
      "host2"
    ];

    settings = rec {
      username = "verz"; # your main account's username
      hostname = "leet"; # your main 

      timezone = "Europe/Prague";
      locale = "en_US.UTF-8";

      flakePath = "/home/${settings.username}/system";
      system = "x86_64-linux";
      stateVersion = "24.05";
    };

    pkgs = nixpkgs.legacyPackages.${settings.system};
    pkgs-stable = nixpkgs-stable.legacyPackages.${settings.system};
    pkgs-master = nixpkgs-master.legacyPackages.${settings.system};

    forAllHosts = inputs.nixpkgs.lib.genAttrs hosts;

    # Systems that can run tests:
      supportedSystems = [ "aarch64-linux" "i686-linux" "x86_64-linux" ];

      # Function to generate a set based on supported systems:
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;

      # Attribute set of nixpkgs for each system:
      nixpkgsFor =
        forAllSystems (system: import inputs.nixpkgs { inherit system; });

      nixosConfigs = nixpkgs.lib.genAttrs hosts (host: inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts

        ];
        specialArgs = { inherit pkgs-stable inputs settings; };
      });

  in {
      nixosConfigurations = nixosConfigs;
      

      #${settings.hostname} = nixpkgs.lib.nixosSystem {
        #system = settings.system;

        #modules = [
          #./hosts
        #];

        #specialArgs = { inherit pkgs-stable inputs settings; };
      #};
    

    homeConfigurations.${settings.username} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [
        ./users/${settings.username}/home.nix
      ];

      extraSpecialArgs = {inherit pkgs-stable inputs settings;};
    };

    packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = self.packages.${system}.install;

          install = pkgs.writeShellApplication {
            name = "install";
            runtimeInputs = with pkgs; [ git ];
	    text = ''
	      #!/bin/sh

       echo "Proceeding with installation"

       HOME_DIR = "/home"
       if [ -d "/home" ]; then
         echo "Looks like you've built the system once before"
       else
         echo "Looks like you're in a live environment"
         HOME_DIR = "/mnt/home"
       fi

       echo "Creating a home folder if it doesn't exist already
       sudo mkdir -p "$HOME_DIR/${users -A 0}"
	    '';
          };
        });

      apps = forAllSystems (system: {
        default = self.apps.${system}.install;

        install = {
          type = "app";
          program = "${self.packages.${system}.install}/bin/install";
        };
      });
  };
}
