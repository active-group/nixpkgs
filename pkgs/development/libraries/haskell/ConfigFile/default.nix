# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, MissingH, mtl, parsec }:

cabal.mkDerivation (self: {
  pname = "ConfigFile";
  version = "1.1.4";
  sha256 = "057mw146bip9wzs7j4b5xr1x24d8w0kr4i3inri5m57jkwspn25f";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [ MissingH mtl parsec ];
  meta = {
    homepage = "http://software.complete.org/configfile";
    description = "Configuration file reading & writing";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
