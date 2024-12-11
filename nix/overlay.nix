final: prev:
{
  # Add an alias here can help future migration
  llvmPkgs = final.llvmPackages_17;
  # Use clang instead of gcc to compile, to avoid gcc13 miscompile issue.
  buddy-llvm = final.callPackage ./buddy-llvm.nix { stdenv = final.llvmPkgs.stdenv; };
  buddy-mlir = final.callPackage ./buddy-mlir.nix {
  stdenv = final.llvmPkgs.stdenv;
  cmake = final.cmake;
  ninja = final.ninja;
  llvmPkgs = final.llvmPkgs;
  libjpeg = final.libjpeg;
  libpng = final.libpng;
  zlib-ng = final.zlib-ng;
  ccls = final.ccls;
  pkgs = final;
};
}
