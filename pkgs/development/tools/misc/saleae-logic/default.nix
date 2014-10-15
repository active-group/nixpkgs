# Saleae logic analyzer software
#
# Suggested udev rules to be able to access the Logic device without being root:
#   SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="0925", ATTR{idProduct}=="3881", MODE="0666"
#   SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="21a9", ATTR{idProduct}=="1001", MODE="0666"
#
# In NixOS, simply add this package to services.udev.packages.

{ stdenv, fetchurl, unzip, glib, libSM, libICE, gtk, libXext, libXft
, fontconfig, libXrender, libXfixes, libX11, libXi, libXrandr, libXcursor
, freetype, libXinerama
, makeDesktopItem
}:

let

  libPath = stdenv.lib.makeLibraryPath [
    glib libSM libICE gtk libXext libXft fontconfig libXrender libXfixes libX11
    libXi libXrandr libXcursor freetype libXinerama
  ];

in

assert stdenv.system == "i686-linux" || stdenv.system == "x86_64-linux";

stdenv.mkDerivation rec {
  pname = "saleae-logic";
  version = "1.1.15";
  name = "${pname}-${version}";

  src =
    if stdenv.system == "i686-linux" then
      fetchurl {
	name = "saleae-logic-${version}-32bit.zip";
	url = "http://downloads.saleae.com/Logic%20${version}%20(32-bit).zip";
	sha256 = "0h13my4xgv8v8l12shimhhn54nn0dldbxz1gpbx92ysd8q8x1q79";
      }
    else if stdenv.system == "x86_64-linux" then
      fetchurl {
	name = "saleae-logic-${version}-64bit.zip";
	url = "http://downloads.saleae.com/Logic%20${version}%20(64-bit).zip";
	sha256 = "1phnjsmaj1gflx7shh8wfrd8dnhn43s3v7bck41h8yj4nd4ax69z";
      }
    else
      abort "Saleae Logic software requires i686-linux or x86_64-linux";

  desktopItem = makeDesktopItem {
    name = "saleae-logic";
    exec = "saleae-logic";
    icon = ""; # the package contains no icon
    comment = "Software for Saleae logic analyzers";
    desktopName = "Saleae Logic";
    genericName = "Logic analyzer";
    categories = "Application;Development";
  };

  buildInputs = [ unzip ];

  installPhase = ''
    # Copy prebuilt app to $out
    mkdir "$out"
    cp -r * "$out"

    # Patch it
    patchelf --set-interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" "$out/Logic"
    patchelf --set-rpath "${stdenv.cc.gcc}/lib:${stdenv.cc.gcc}/lib64:${libPath}:\$ORIGIN/Analyzers:\$ORIGIN" "$out/Logic"

    # Build the LD_PRELOAD library that makes Logic work from a read-only directory
    mkdir -p "$out/lib"
    gcc -shared -fPIC -DOUT=\"$out\" "${./preload.c}" -o "$out/lib/preload.so" -ldl

    # Make wrapper script that uses the LD_PRELOAD library
    mkdir -p "$out/bin"
    cat > "$out/bin/saleae-logic" << EOF
    #!${stdenv.shell}
    export LD_PRELOAD="$out/lib/preload.so"
    exec "$out/Logic" "\$@"
    EOF
    chmod a+x "$out"/bin/saleae-logic

    # Copy the generated .desktop file
    mkdir -p "$out/share/applications"
    cp "$desktopItem"/share/applications/* "$out/share/applications/"

    # Install provided udev rules
    mkdir -p "$out/etc/udev/rules.d"
    cp Drivers/99-SaleaeLogic.rules "$out/etc/udev/rules.d/"
  '';

  meta = with stdenv.lib; {
    description = "Software for Saleae logic analyzers";
    homepage = http://www.saleae.com/;
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}
