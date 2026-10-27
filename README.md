# HanLock

<img src="https://raw.githubusercontent.com/lapalai/hanlock/main/assets/hanlock.png" width="80" height="80" alt="HanLock">

Windows 트레이 상주 단독 실행 파일(`HanLock.exe`)로, CapsLock 키를 한/영 전환 키로 쓰게 해 주는 작은 유틸리티입니다. 작성자: lio / 배포: lapalai / 버전 1.0.0 / 라이선스: GPL-2.0

저장소: https://github.com/lapalai/hanlock

## 동작

| 입력 | 동작 |
| --- | --- |
| CapsLock 짧게 누름 (설정한 기준 미만, 기본 0.4초) | 한/영 전환 |
| CapsLock 길게 누름 (설정한 기준 이상, 기본 0.4초) | CapsLock 켜기/끄기 토글 |

- 두 동작 모두 키를 **뗄 때(RELEASE)** 실행됩니다.
- `CapsLock`과 `sc0F2`(이미 레지스트리 스캔코드 매핑으로 전달되는 키)를 모두 처리합니다. HanLock은 레지스트리 매핑이나 PowerToys 설정을 **수정하지 않습니다.**
- 로컬/원격 키보드 입력이 일반 데스크톱에서 정상 동작하도록 만들었습니다. 다만 관리자 권한 창이나 보안 데스크톱(UAC, 잠금 화면 등)에서는 일반 권한 프로세스가 키를 가로챌 수 없는 Windows 제한이 있습니다.
- 실제 물리 Mac Jump 입력으로 검증했다고 주장하지 않습니다. Mac 쪽은 아무것도 수정하지 않습니다.

## 트레이 메뉴

트레이 아이콘을 우클릭하면 **길게 누르기 기준: 0.4초...**, **Windows 로그인 시 자동 시작**, 일시 중지/재개, 종료, 정보를 사용할 수 있습니다.

**길게 누르기 기준**을 클릭해 초 단위로 입력하면 즉시 반영됩니다. 예: `0.3`은 0.3초 미만을 짧게, 0.3초 이상을 길게 판단합니다. 최소 0.001초이며 밀리초 단위로 반올림됩니다.

설정은 `%APPDATA%\HanLock\settings.ini`에 저장되어 재부팅·재실행 후에도 유지됩니다. 프로그램을 제거해도 이 사용자 설정은 보존됩니다.

**Windows 로그인 시 자동 시작**을 클릭하면 체크 상태가 바뀝니다. 체크 시 현재 EXE를 시작프로그램에 등록하고, 해제 시 해당 등록을 제거합니다. 앱을 다시 실행해도 실제 등록 상태를 표시합니다.

## 설치

1. 릴리스 페이지(https://github.com/lapalai/hanlock/releases)에서 `HanLock-1.0.0-windows-x64.zip`을 받아 압축을 풉니다.
2. PowerShell에서 압축을 푼 폴더로 이동해 실행합니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

사용자별(per-user)로 `%LOCALAPPDATA%\HanLock`에 설치됩니다. 설치 직후 자동 시작은 켜져 있으며, 트레이 메뉴에서 해제할 수 있습니다. 자동 시작은 **재부팅 후 사용자 로그인 시점**에 동작하며 로그인 이전에는 실행되지 않습니다. 위 명령은 해당 실행에만 정책을 우회하며 영구적인 실행 정책 변경은 하지 않습니다.

제거:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

서명되지 않은 바이너리이므로 Windows SmartScreen 경고가 표시될 수 있습니다. 출처와 해시를 확인한 뒤 직접 판단하세요.

## 개발

```powershell
.\scripts\build.ps1
.\scripts\install.ps1 -SourcePath .\dist\HanLock.exe
```

빌드 결과는 `dist/`에 생성됩니다(`HanLock.exe`, 설치 스크립트, `HanLock-1.0.0-windows-x64.zip`). 빌드 도구 캐시 `.tools/`는 git에서 제외됩니다.

## 라이선스와 서드파티

HanLock은 GPL-2.0(`LICENSE`)입니다. 컴파일된 `HanLock.exe`에는 GPL-2.0 AutoHotkey v2.0.31 런타임이 포함되어 있습니다. 대응 소스는 같은 릴리스의 `AutoHotkey-2.0.31-source.zip`이며, 원본 태그는 https://github.com/AutoHotkey/AutoHotkey/tree/v2.0.31 입니다. 업스트림 라이선스(PCRE 포함)는 `third-party/AutoHotkey-LICENSE.txt`, 고지는 `THIRD-PARTY-NOTICES.md`를 참고하세요. 본 프로젝트는 AutoHotkey의 저작자가 아닌 lio의 스크립트이며 업스트림 저작권을 주장하지 않습니다.

## 확인한 동작

- 실행 중인 EXE에 Windows 키 이벤트를 보내 일반 CapsLock과 기존 매핑된 `sc0F2`의 짧게/길게 누르기, 자동 반복, 대문자 고정 유지 여부를 확인했습니다.
- 실제 Windows 입력창에서 `rksk` ↔ `가나` 전환을 확인했습니다.
- 트레이 UI에서 기준을 0.65초로 바꾸고 EXE를 재시작한 뒤에도 유지되는지, 450ms는 짧게/800ms는 길게 판단하는지 확인했습니다.
- 트레이에서 자동 시작을 끄고 재시작한 뒤 꺼진 상태가 유지되는지, 다시 켜면 실제 시작프로그램 바로가기가 생성되는지 확인했습니다.
- 빠른 연속 입력에서 키 전송 지연 때문에 생기는 누락을 수정했으며, 짧은 간격의 10회 입력이 모두 전환되는 것을 확인했습니다.
- 공백이 들어간 경로의 설치·제거 및 제거 시 무관한 파일 보존을 확인했습니다.

