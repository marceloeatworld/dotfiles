# Smartcard daemon for the Cartao de Cidadao USB reader.
# pcscd is the only component that touches the reader hardware; the jailed
# Autenticacao.Gov plugin (modules/home/programs/autenticacao-gov.nix) talks
# to it through the /run/pcscd socket only. The ccid driver is pcscd's
# default plugin, so enabling the service is enough for standard readers.
{ ... }:

{
  services.pcscd.enable = true;
}
