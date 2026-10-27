# 작업 기록 — 2026-10-27

## 프로젝트

- 이름: HanLock
- 제작자: lio
- 배포: lapalai
- 소스: https://github.com/lapalai/hanlock
- 공개 릴리스: https://github.com/lapalai/hanlock/releases/tag/v1.0.0
- 라이선스: GPL-2.0. 내장 AutoHotkey 런타임의 대응 소스와 라이선스도 릴리스에 포함.

## 완료한 작업

- Windows 전용 AutoHotkey v2 스크립트를 단독 실행 가능한 x64 EXE로 패키징.
- 짧게 누르면 한/영 전환, 길게 누르면 Caps Lock 전환. 두 동작 모두 키를 뗄 때 실행.
- 기본 판단 기준 0.4초. 트레이 메뉴에서 초 단위 변경 가능.
- 기준 설정은 `%APPDATA%\HanLock\settings.ini`에 저장해 재실행 후 유지.
- 트레이에서 Windows 로그인 시 자동 시작을 켜고 끌 수 있도록 구현.
- 정보, 일시 중지/재개, 종료 메뉴 제공.
- 민트·화이트 양방향 화살표 SVG와 다중 해상도 ICO 제작, EXE 및 트레이에 반영.
- 기존 CapsLock→한/영 스캔코드 매핑(`003A -> 00F2`)을 유지하며 일반 CapsLock과 `sc0F2` 모두 처리.
- 기존 PowerToys 설정과 Mac 설정은 변경하지 않음.
- 설치/제거 스크립트, 해시 검증을 포함한 빌드 스크립트, 오픈소스 문서 작성.
- 임시 검증 스크립트 및 이전 CapsLockIME 설치를 제거하고 HanLock으로 전환.

## 재현한 오류와 수정

빠른 연속 입력에서 기본 SendEvent 지연 때문에 같은 키의 후속 release 처리가 누락되는 경우를 재현했다. 누락된 release는 이후 짧은 입력을 길게 누른 것으로 오판할 위험도 있다.

- `SetKeyDelay -1, -1`로 키 전송 지연 제거.
- 누름/뗌 핸들러에 `Critical`을 적용해 상태 갱신 중 다음 핫키가 끼어들지 않도록 처리.
- 개발 중 설정 검증 실패로 테스트 기준 0.65초가 남았던 것을 확인하고 0.4초로 복원.

## 실행으로 확인한 범위

- Windows 원시 키보드 후크로 일반 CapsLock과 매핑된 키 각각 10회 입력 → 전환 키 10회 전달 확인.
- 빠른 입력 이후 다음 짧은 입력이 길게 누르기로 오판되지 않는 것 확인.
- 길게 누르기 대문자 고정 켜기/끄기 및 한/영 전환과의 분리 확인.
- 실제 Windows 입력창에서 `rksk` ↔ `가나` 전환 확인. 최종 EXE는 네이티브 WinForms 입력창에서도 조합 확정 후 확인.
- 트레이 UI에서 기준 0.65초 변경, 재시작 후 유지, 450ms/800ms 판단 확인.
- 자동 시작 해제 후 재시작 시 해제 유지, 다시 활성화 시 바로가기 생성 확인.
- 공백이 있는 경로의 설치/제거와 무관한 파일 보존 확인.
- Windows 트레이의 실제 전용 아이콘과 툴팁 확인.
- GitHub에 공개된 배포 파일의 SHA256이 로컬 배포 해시와 일치함을 확인.

## 인계 시 상태

- 설치 경로: `%LOCALAPPDATA%\HanLock\HanLock.exe`
- HanLock 단독 프로세스 하나가 실행되는 것을 마지막으로 확인.
- 로그인 자동 시작 켜짐, 판단 기준 0.4초로 인계.
- 시작프로그램: `shell:startup`의 `HanLock.lnk`.
- 빌드: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1`
- 빌드 산출물: `dist/`에 생성. 캐시와 산출물은 Git에서 제외.

## 알려진 제한

- 실제 물리 Mac 키 입력 → Jump Desktop → Windows 전체 경로의 모든 간헐적 실패가 해결됐다고 확정하지 않았다.
- 일반 권한 HanLock이 전송한 키는 관리자 권한 앱에서 Windows 보안 정책에 의해 막힐 수 있다. UAC/로그인 보안 화면은 지원 범위 밖이다.
- 수정키를 누른 상태의 전환은 별도 실기 검증하지 않았다. 근거 없는 Blind 전송 변경은 적용하지 않았다.
- EXE는 코드 서명되지 않아 SmartScreen 경고가 표시될 수 있다.
- 자동 시작은 부팅 직후가 아니라 사용자 로그인 후 동작한다.
