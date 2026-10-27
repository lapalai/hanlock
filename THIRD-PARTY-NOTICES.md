# Third-party notices

HanLock 1.0.0 is copyright (C) lio and is licensed under GPL-2.0 (see `LICENSE`).

## AutoHotkey v2.0.31

The compiled `HanLock.exe` embeds the AutoHotkey v2.0.31 runtime (`AutoHotkey64.exe`) as its interpreter base. AutoHotkey is © Steve Gray, Chris Mallett, the AutoHotkey Foundation and contributors, and is distributed under the GNU General Public License version 2. The runtime also contains PCRE, distributed under its BSD licence.

- The complete upstream license text, including the PCRE licence, is preserved verbatim in `third-party/AutoHotkey-LICENSE.txt`.
- Corresponding source: the release asset `AutoHotkey-2.0.31-source.zip` (the upstream `v2.0.31` source archive), attached to the same HanLock release.
- Upstream tag: https://github.com/AutoHotkey/AutoHotkey/tree/v2.0.31
- Upstream release: https://github.com/AutoHotkey/AutoHotkey/releases/tag/v2.0.31

HanLock's own script (`src/HanLock.ahk`) was written by lio and does not claim upstream authorship.

## Ahk2Exe (build tool, not redistributed in the release)

The build script downloads Ahk2Exe 1.1.37.02a2 from https://github.com/AutoHotkey/Ahk2Exe to compile the script. It is used only at build time.
