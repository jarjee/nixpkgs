{ stdenv, fetchurl, unzip
, alsaLib, atk, cairo, cups, curl, dbus, expat, fontconfig, freetype, glib
, gnome2, libnotify, libxcb, nspr, nss, systemd, xorg, gtk3 }:

let

  version = "3.4.0";

  rpath = stdenv.lib.makeLibraryPath [
    alsaLib
    atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    glib
    gnome2.GConf
    gnome2.gdk_pixbuf
    gnome2.gtk
    gnome2.pango
    gtk3
    libnotify
    libxcb
    nspr
    nss
    stdenv.cc.cc
    systemd

    xorg.libxkbfile
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXScrnSaver
  ] + ":${stdenv.cc.cc.lib}/lib64";

  src =
    if stdenv.system == "x86_64-linux" then
      fetchurl {
        url = "https://download.cypress.io/desktop/${version}?platform=linux";
        sha256 = "0in9y2d8sf4l9hl32l8kw5nkbxsm0hsz0dnjlq041a55m7cqq7n3";
      }
    else
      throw "Cypress is not supported on ${stdenv.system}";

in stdenv.mkDerivation {
  name = "cypress-${version}";

  inherit src;

  unpackPhase = "true";

  buildInputs = [ unzip gtk3 ];

  buildCommand = ''
    IFS=$'\n'
    unzip $src -d $out
    #The node_modules are bringing in non-linux files/dependencies
    find $out -name "*.app" -exec rm -rf {} \; || true
    find $out -name "*.dll" -delete
    find $out -name "*.exe" -delete
    # Otherwise it looks "suspicious"
    chmod -R g-w $out
    for file in `find $out -type f -perm /0111 -o -name \*.so\*`; do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$file" || true
      patchelf --set-rpath ${rpath}:$out/Cypress "$file" || true
    done
    mkdir $out/bin
    mkdir -p $out/share/applications
    ln -s $out/Cypress/Cypress $out/bin/cypress

    #If we don't mock the binary_state.json file, cypress will attempt to write to this folder
    echo '{ "verified": true }' > $out/Cypress/binary_state.json
    substituteAll ${./cypress.desktop} $out/share/applications/cypress.desktop
  '';

  meta = with stdenv.lib; {
    description = "Cypress is a next generation front end testing tool built for the modern web";
    homepage = https://www.cypress.io/;
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
