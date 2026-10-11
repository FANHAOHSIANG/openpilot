# Carrot DEC C4 installer

On the C4 custom software screen enter:

`FANHAOHSIANG/carrotpilot-dec`

Full URL: https://installer.comma.ai/FANHAOHSIANG/carrotpilot-dec

This branch is an installation bootstrap. It downloads the complete
`FANHAOHSIANG/openpilot-carrot` repository's `carrotpilot-dec` branch, including
submodules, checks that it contains commit
`ec3451446723cd1da3680a0c49e50a1af20caec2`, then starts its normal launcher.
The installed repository's origin remains `openpilot-carrot`; subsequent updates
use that repository. Installation requires Internet access and the vehicle off.
The bootstrap is retained in `/data/carrot-dec-bootstrap.*` after successful
handoff. Failed downloads leave the bootstrap in place for retry on reboot.

DEC and the parked model switch remain disabled by default. See the installed
repository's `docs/parked_model_switch_dec_20261011.md` for enabling the latter.
The bootstrap has local integration checks; C4 installation and driving behavior
have not been verified on hardware.
