{
  pkgs,
  pkgs-stable,
  inputs,
  settings,
  config,
  ...
}: {
  imports = [
    ../. # Common user configuration
    inputs.spicetify-nix.homeManagerModules.default
    inputs.ags.homeManagerModules.default
  ];

  home.username = "${settings.username}"; # Set username
  home.homeDirectory = "/home/${settings.username}"; # Set home directory path

  programs.ags = {
    enable = true;

    # symlink to ~/.config/ags
    #configDir = "/home/${settings.username}";

    # additional packages to add to gjs's runtime
    extraPackages = with pkgs; [
      inputs.ags.packages.${pkgs.system}.battery
      fzf
    ];
  };
  
  programs.spicetify =
   let
     spicePkgs = inputs.spicetify-nix.legacyPackages.${settings.system};
   in
   {
     enable = true;
     enabledExtensions = with spicePkgs.extensions; [
       adblock
       hidePodcasts
       shuffle # shuffle+ (special characters are sanitized out of extension names)
     ];
   };

  wayland.windowManager.hyprland = {
    enable = true; # Enable hyprland configuration

    # Hyprland configuration
    settings = {
      "$mod" = "SUPER";

      bind =
        [
          "$mod, C, killactive,"
          "$mod, M, exit,"
          "$mod, Q, exec, kitty"
          "$mod, F, exec, zen"
          "$mod, space, exec, wofi --show drun"
	  "$mod, h, movefocus, l"
	  "$mod, j, movefocus, d"
	  "$mod, k, movefocus, u"
	  "$mod, l, movefocus, r"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (
              i: let
                ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );

      input = {
        touchpad = {
          natural_scroll = "true";
        };
      };

      decoration = {
        rounding = "5";
      };

      misc = {
        #force_default_wallpaper = "0";
        disable_hyprland_logo = "true";
      };
      
      exec-once = "kanata -c /home/${settings.username}/kanata.kbd";
    };
  };

  programs.kitty = {
    enable = true;

    settings = {
      confirm_os_window_close = 0;
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      l = "ls -l";
      ll = "ls -la";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    initExtra = ''
	set -o vi

        # Custom nh all command, rebuilding both nixos and home-manager
      nh() {
          if [[ "$1" == "all" ]]; then
              nh os "$${@:2}"
              nh home "$${@:2}"
          else
              command nh "$@"
          fi
      }
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;

  nixpkgs.config.allowUnfree = true; # Allow unfree packages

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
  "text/html" = "zen.desktop";
  "x-scheme-handler/http" = "zen.desktop";
  "x-scheme-handler/https" = "zen.desktop";
  "x-scheme-handler/about" = "zen.desktop";
  "x-scheme-handler/unknown" = "zen.desktop";
    };
  };

  programs.zsh.profileExtra = ''
    if [[ $(tty) == /dev/tty1 ]]; then
      exec Hyprland
    fi
  '';

  # User/home-manager packages
  home.packages = [
    pkgs.firefox
    pkgs.legcord
    pkgs.kanata
    pkgs.stremio
    pkgs.vscode
    pkgs.yazi
    inputs.zen-browser.packages."${settings.system}".specific
    #spotify # already within spicetify nix flake

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    "system/folder/file.txt".text = "nigga";

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/verz/etc/profile.d/hm-session-vars.sh
  #

  # Let Home Manager install and manage itself.
  #programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.

  home.stateVersion = "${settings.stateVersion}"; # Please read the comment before changing.
}
