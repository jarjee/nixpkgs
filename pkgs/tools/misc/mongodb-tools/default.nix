{ stdenv, buildGoPackage, fetchFromGitHub, openssl_1_0_2, pkgconfig, libpcap }:

let
  tools = [
    "bsondump" "mongodump" "mongoexport" "mongofiles" "mongoimport"
    "mongoreplay" "mongorestore" "mongostat" "mongotop"
  ];
in

with stdenv.lib;

buildGoPackage rec {
  name = "mongo-tools-${version}";
  version = "4.1.6";
  rev = "r${version}";

  goPackagePath = "github.com/mongodb/mongo-tools";
  subPackages = map (t: t + "/main") tools;

  src = fetchFromGitHub {
    inherit rev;
    owner = "mongodb";
    repo = "mongo-tools";
    sha256 = "014gpf193mdv6hnjqajg5y5i457s3s83wnjk8spd0mygk882y2nf";
  };

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ openssl_1_0_2 libpcap ];

  # Mongodb incorrectly names all of their binaries main
  # Let's work around this with our own installer
  buildPhase = ''
    # move vendored codes so nixpkgs go builder could find it
    mv go/src/github.com/mongodb/mongo-tools/vendor/src/* go/src/github.com/mongodb/mongo-tools/vendor/

    runHook preBuild
    ${stdenv.lib.concatMapStrings (t: ''
      go build -o "$bin/bin/${t}" -tags ssl -ldflags "-s -w" $goPackagePath/${t}/main
    '') tools}
    runHook postBuild
  '';

  meta = {
    homepage = https://github.com/mongodb/mongo-tools;
    description = "Tools for the MongoDB";
    license = licenses.asl20;
  };
}
