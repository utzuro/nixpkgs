{
  config,
  pkgs,
  # zathura_pdf_mupdf fails to load _opj_create_decompress at runtime on Darwin (https://github.com/NixOS/nixpkgs/pull/61295#issue-277982980)
  useMupdf ? config.zathura.useMupdf or (!pkgs.stdenv.isDarwin),
}:

let
  callPackage = pkgs.newScope self;

  self = rec {
    gtk = pkgs.gtk3;

    zathura_core = callPackage ./core { };

    zathura_pdf_poppler = callPackage ./pdf-poppler { };

    zathura_pdf_mupdf = callPackage ./pdf-mupdf { };

    zathuraWrapper = callPackage ./wrapper.nix {
      plugins = [
        (if useMupdf then zathura_pdf_mupdf else zathura_pdf_poppler)
      ];
    };
  };
in
self
