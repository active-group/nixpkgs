{stdenv, fetchurl, which, file, perl, curl, python27, makeWrapper}:

assert stdenv.cc.gcc != null;

/* Rust's build process has a few quirks :

- It requires some patched in llvm that haven't landed upstream, so it
  compiles its own llvm. This might change in the future, so at some
  point we may be able to switch to nix's llvm.

- The Rust compiler is written is Rust, so it requires a bootstrap
  compiler, which is downloaded during the build. To make the build
  pure, we download it ourself before and put it where it is
  expected. Once the language is stable (1.0) , we might want to
  switch it to use nix's packaged rust compiler.

*/

with ((import ./common.nix) {inherit stdenv; version = "0.11.0"; });

let snapshot = if stdenv.system == "i686-linux"
      then "84339ea0f796ae468ef86797ef4587274bec19ea"
      else if stdenv.system == "x86_64-linux"
      then "bd8a6bc1f28845b7f4b768f6bfa06e7fbdcfcaae"
      else if stdenv.system == "i686-darwin"
      then "3f25b2680efbab16ad074477a19d49dcce475977"
      else if stdenv.system == "x86_64-darwin"
      then "4a8c2e1b7634d73406bac32a1a97893ec3ed818d"
      else abort "no-snapshot for platform ${stdenv.system}";
    snapshotDate = "2014-06-21";
    snapshotRev = "db9af1d";
    snapshotName = "rust-stage0-${snapshotDate}-${snapshotRev}-${platform}-${snapshot}.tar.bz2";

in stdenv.mkDerivation {
  inherit name;
  inherit version;
  inherit meta;

  src = fetchurl {
    url = http://static.rust-lang.org/dist/rust-0.11.0.tar.gz;
    sha256 = "1fhi8iiyyj5j48fpnp93sfv781z1dm0xy94h534vh4mz91jf7cyi";
  };

  # We need rust to build rust. If we don't provide it, configure will try to download it.
  snapshot = stdenv.mkDerivation {
    name = "rust-stage0";
    src = fetchurl {
      url = "http://static.rust-lang.org/stage0-snapshots/${snapshotName}";
      sha1 = snapshot;
    };
    dontStrip = true;
    installPhase = ''
      mkdir -p "$out"
      cp -r bin "$out/bin"
    '' + (if stdenv.isLinux then ''
      patchelf --interpreter "${stdenv.glibc}/lib/${stdenv.cc.dynamicLinker}" \
               --set-rpath "${stdenv.cc.gcc}/lib/:${stdenv.cc.gcc}/lib64/" \
               "$out/bin/rustc"
    '' else "");
  };

  configureFlags = [ "--enable-local-rust" "--local-rust-root=$snapshot" ];

  # The compiler requires cc, so we patch the source to tell it where to find it
  patches = [ ./hardcode_paths.patch ./local_stage0.patch ];
  postPatch = ''
    substituteInPlace src/librustc/back/link.rs \
      --subst-var-by "ccPath" "${stdenv.cc}/bin/cc" \
      --subst-var-by "arPath" "${stdenv.cc.binutils}/bin/ar"
  '';

  buildInputs = [ which file perl curl python27 makeWrapper ];
  enableParallelBuilding = true;
}
