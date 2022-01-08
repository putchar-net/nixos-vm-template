{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # https://github.com/nix-community/nixos-generators
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  ## https://gist.github.com/tarnacious/f9674436fff0efeb4bb6585c79a3b9ff
  outputs = { self, nixpkgs, nixos-generators, ... }: {
    packages.x86_64-linux = {
      ## to build just do nix build .#qcow
      qcow = nixos-generators.nixosGenerate {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        format = "qcow";
        modules = [
          ({ config, lib, pkgs, modulesPath, ... }: {
            imports = [ "${toString modulesPath}/profiles/qemu-guest.nix" ];

            fileSystems."/" = {
              device = "/dev/disk/by-label/nixos";
              autoResize = true;
              fsType = "ext4";
            };

            boot.growPartition = true;
            boot.kernelParams = [ "console=ttyS0" ];
            boot.loader.grub.device = lib.mkDefault "/dev/vda";
            boot.loader.timeout = lib.mkDefault 10;

            system.build.qcow =
              import "${toString modulesPath}/../lib/make-disk-image.nix" {
                inherit lib config pkgs;
                diskSize = 16384;
                format = "qcow2";
              };

            formatAttr = "qcow";

            services.sshd.enable = true;

            users.users.root.password = "nixos";
            services.openssh.permitRootLogin = lib.mkDefault "yes";
            services.getty.autologinUser = lib.mkDefault "root";
          })
        ];
      };

      raw = nixos-generators.nixosGenerate {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        format = "raw";
      };

      rawefi = nixos-generators.nixosGenerate {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        format = "raw-efi";
      };
    };
  };
}
