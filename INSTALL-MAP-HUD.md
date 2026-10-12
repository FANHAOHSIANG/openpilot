# Carrot Map HUD direct installer

Enter this URL on the comma custom software setup screen:

https://raw.githubusercontent.com/FANHAOHSIANG/openpilot/carrot-wip-map-hud/installer

`installer` is an unchanged copy downloaded with User-Agent AGNOSSetup from
https://installer.comma.ai/FANHAOHSIANG/carrot-wip-map-hud on 2026-10-12.
It is an ARM64 ELF installer whose embedded clone target is
https://github.com/FANHAOHSIANG/openpilot.git branch carrot-wip-map-hud.
The launcher in that branch downloads the actual feature branch from
FANHAOHSIANG/openpilot-carrot, requiring feature commit 2664c0dd.

Binary size: 1270680 bytes.
SHA256: 8aa02beae537c7d6353d8c6e418568b722791b7987b9eadde6a0754ad83a090d.

This mirror provides a different download endpoint; it does not establish the
cause of a particular device's setup failure. HTTP download, binary identity,
embedded target and mocked bootstrap tests are verified. A physical C4 install
has not been performed in this environment.
