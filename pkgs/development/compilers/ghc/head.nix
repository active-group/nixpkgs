{ stdenv, fetchurl, ghc, perl, gmp, ncurses, happy, alex }:

let
  year = "2014";
  month = "11";
  day = "03";
in stdenv.mkDerivation rec {
  version = "7.9.${year}${month}${day}";
  name = "ghc-${version}";

  src = fetchurl {
    url = "http://deb.haskell.org/dailies/${year}-${month}-${day}/ghc_${version}.orig.tar.bz2";
    sha256 = "00h4c0vzgcfd0k2b3jg326g6r6y19if1m427nk0mmrh52j15vi14";
  };

  buildInputs = [ ghc perl gmp ncurses happy alex ];

  enableParallelBuilding = true;

  buildMK = ''
    libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-libraries="${gmp}/lib"
    libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-includes="${gmp}/include"
    DYNAMIC_BY_DEFAULT = NO
  '';

  preConfigure = ''
    echo "${buildMK}" > mk/build.mk
    sed -i -e 's|-isysroot /Developer/SDKs/MacOSX10.5.sdk||' configure
  '' + stdenv.lib.optionalString (!stdenv.isDarwin) ''
    export NIX_LDFLAGS="$NIX_LDFLAGS -rpath $out/lib/ghc-${version}"
  '';

  # required, because otherwise all symbols from HSffi.o are stripped, and
  # that in turn causes GHCi to abort
  stripDebugFlags = [ "-S" "--keep-file-symbols" ];

  meta = {
    homepage = "http://haskell.org/ghc";
    description = "The Glasgow Haskell Compiler";
    maintainers = [
      stdenv.lib.maintainers.marcweber
      stdenv.lib.maintainers.andres
      stdenv.lib.maintainers.simons
    ];
    inherit (ghc.meta) license platforms;
  };

}
