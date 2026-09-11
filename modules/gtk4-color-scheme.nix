{ pkgs, unstablePkgs, ... }:
let
  patch = ../patches/gtk4-initial-color-scheme.patch;
  patchedGtk4 = pkgs.gtk4.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ patch ];
  });
  patchedUnstableGtk4 = unstablePkgs.gtk4.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ patch ];
  });
in {
  system.replaceDependencies.replacements = [
    {
      oldDependency = pkgs.gtk4;
      newDependency = patchedGtk4;
    }
    {
      oldDependency = unstablePkgs.gtk4;
      newDependency = patchedUnstableGtk4;
    }
  ];
}
