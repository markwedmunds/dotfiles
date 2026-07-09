{
  description = "dotfiles";

  inputs = {
    # Use `github:NixOS/nixpkgs/nixpkgs-26.05-darwin` to use Nixpkgs 26.05.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # 26.05 ships tree-sitter 0.26.x, which dropped the `--no-bindings` flag that
    # nvim-treesitter's master branch passes to `tree-sitter generate` (it supports
    # CLI up to 0.25.x only). This pin supplies 0.25.x just for that one package so
    # the swift parser still generates. Remove once nvim-treesitter supports 0.26+.
    nixpkgs-treesitter.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    # Use `github:nix-darwin/nix-darwin/nix-darwin-26.05` to use Nixpkgs 26.05.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, home-manager, nixpkgs, nixpkgs-treesitter }:
    let
      # The one username line to change if this isn't your machine.
      # bootstrap.sh offers to rewrite this for you if your macOS username differs.
      user = "meddy";
      # Pin tree-sitter to the 0.25.x from the 25.05 channel (see input comment).
      # This override is global, so pass the original 26.05 tree-sitter back to any
      # package that needs its newer API (helix uses `tree-sitter.grammarsScope`,
      # which the 0.25.x pin doesn't expose).
      treesitterOverlay = final: prev: {
        tree-sitter = (import nixpkgs-treesitter { inherit (prev) system; }).tree-sitter;
        helix = prev.helix.override { tree-sitter = prev.tree-sitter; };
      };
    in
    {
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user; };
        modules = [
          { nixpkgs.overlays = [ treesitterOverlay ]; }
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit user; };
            home-manager.users.${user} = import ./home.nix;
          }
        ];
      };
    };
}
