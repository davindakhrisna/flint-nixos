_: {
  flake.nixosModules.boot = {
    config,
    lib,
    ...
  }: {
    boot = {
      supportedFilesystems = lib.mkIf config.var.dualBoot.enable ["ntfs"];
      loader = {
        limine = {
          enable = true;
          efiSupport = true;
          maxGenerations = 5;
          extraEntries = lib.optionalString config.var.dualBoot.enable ''
            /Windows
                protocol: efi
                path: ${config.var.dualBoot.windowsEntry}
          '';
        };
        efi.canTouchEfiVariables = true;
      };
    };

    time.hardwareClockInLocalTime = lib.mkIf config.var.dualBoot.enable true;
  };
}
