{
  description = "cpolar tunnel info query scripts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/e7a3ca8092b61ff85b6a45bf863ea2b2d6a661b3";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "cpolar-tunnels";
            version = "0.1.0";
            src = self;

            nativeBuildInputs = [ pkgs.makeWrapper pkgs.gettext ];
            buildInputs = [ pkgs.bash pkgs.jq pkgs.curl pkgs.gettext ];

            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/locale/zh_CN/LC_MESSAGES
              install -m755 cpolar_tunnels.sh $out/bin/cpolar-tunnels
              msgfmt po/zh_CN.po -o $out/share/locale/zh_CN/LC_MESSAGES/cpolar-tunnels.mo
              wrapProgram $out/bin/cpolar-tunnels \
                --set TEXTDOMAIN cpolar-tunnels \
                --set TEXTDOMAINDIR $out/share/locale \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.bash pkgs.jq pkgs.curl pkgs.gettext ]}
              runHook postInstall
            '';
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.jq pkgs.curl pkgs.gettext ];
          };
        });
    };
}
