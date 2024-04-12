{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    #python312Packages.python-lsp-server
    #nodePackages_latest.nodemon
    tailwindcss-language-server
    #nodePackages_latest.intelephense
    #nodePackages_latest.typescript
    #nodePackages_latest.typescript-language-server
    nodePackages_latest.vscode-langservers-extracted
    #nodePackages_latest.yaml-language-server
    nodePackages_latest.dockerfile-language-server-nodejs
    #sumneko-lua-language-server
    marksman
    #nil
    #zls
    #gopls
    #delve
  ];  
}
