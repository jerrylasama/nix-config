{ den, ... }:
{
  den.aspects.network-tools = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        tcpdump
        wireshark-cli
        nmap
        mitmproxy
        python3Packages.scapy
        socat
      ];
    };
  };
}
