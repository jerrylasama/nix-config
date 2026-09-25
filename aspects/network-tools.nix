{ den, ... }:
{
  den.aspects.network-tools = {
    homeManager = { pkgs, ... }: {
      home.packages = [
        pkgs.tcpdump
        pkgs.wireshark-cli
        pkgs.nmap
        pkgs.mitmproxy
        pkgs.python3Packages.scapy
        pkgs.socat
      ];
    };
  };
}
