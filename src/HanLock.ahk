; SPDX-License-Identifier: GPL-2.0-only
; Copyright (C) 2026 lio
;@Ahk2Exe-SetName HanLock
;@Ahk2Exe-SetDescription Caps Lock Korean-English switcher by lio
;@Ahk2Exe-SetCompanyName lapalai
;@Ahk2Exe-SetCopyright Copyright (C) 2026 lio
;@Ahk2Exe-SetVersion 1.0.0
#Requires AutoHotkey v2.0
#SingleInstance Force

; A delayed SendEvent keeps the key-up hotkey busy and can drop queued taps.
SetKeyDelay -1, -1

; Decide on release, using events instead of physical polling for remote input.
SettingsPath := A_AppData "\HanLock\settings.ini"
HoldMilliseconds := Integer(IniRead(SettingsPath, "Keyboard", "HoldMilliseconds", 400))
PressedAt := Map()
ThresholdMenu := "길게 누르기 기준: " DurationSeconds() "초..."
AutoStartLink := A_Startup "\HanLock.lnk"
UpdateTrayTip()
A_TrayMenu.Delete()
A_TrayMenu.Add("HanLock 정보", ShowAbout)
A_TrayMenu.Add(ThresholdMenu, ChangeThreshold)
A_TrayMenu.Add("Windows 로그인 시 자동 시작", ToggleAutoStart)
if AutoStartEnabled()
    A_TrayMenu.Check("Windows 로그인 시 자동 시작")
A_TrayMenu.Add()
A_TrayMenu.Add("일시 중지", TogglePause)
A_TrayMenu.Add("종료", (*) => ExitApp())
A_TrayMenu.Default := "HanLock 정보"

*CapsLock::PressCaps("CapsLock")
*CapsLock up::ReleaseCaps("CapsLock")
; Also accept a Caps Lock already mapped to Hangul (003A -> 00F2).
*sc0F2::PressCaps("sc0F2")
*sc0F2 up::ReleaseCaps("sc0F2")

PressCaps(key) {
    global PressedAt
    ; Auto-repeat must not restart the hold duration or cause another action.
    if !PressedAt.Has(key)
        PressedAt[key] := A_TickCount
}

ReleaseCaps(key) {
    global PressedAt, HoldMilliseconds
    if !PressedAt.Has(key)
        return
    elapsed := A_TickCount - PressedAt[key]
    PressedAt.Delete(key)
    if elapsed >= HoldMilliseconds
        SetCapsLockState !GetKeyState("CapsLock", "T")
    else
        SendEvent "{vk15}"
}

TogglePause(itemName, *) {
    global PressedAt
    Suspend !A_IsSuspended
    PressedAt.Clear()
    A_TrayMenu.ToggleCheck(itemName)
    UpdateTrayTip()
}

DurationSeconds() {
    global HoldMilliseconds
    return Format("{:g}", HoldMilliseconds / 1000)
}

UpdateTrayTip() {
    A_IconTip := A_IsSuspended
        ? "HanLock by lio — 일시 중지됨"
        : "HanLock by lio`n짧게: 한/영 | " DurationSeconds() "초 이상: Caps Lock"
}

ChangeThreshold(*) {
    global HoldMilliseconds, SettingsPath, ThresholdMenu, PressedAt
    result := InputBox("짧게/길게를 나누는 기준을 초 단위로 입력하세요.`n"
        . "입력한 시간 미만: 한/영 전환`n입력한 시간 이상: Caps Lock 전환`n"
        . "두 동작 모두 키를 뗄 때 실행됩니다. (최소 0.001초)",
        "HanLock 설정", "w440 h200", DurationSeconds())
    if result.Result != "OK"
        return
    if !IsNumber(result.Value) || result.Value <= 0 {
        MsgBox "0보다 큰 숫자를 초 단위로 입력하세요.", "HanLock 설정", 0x30
        return
    }
    try {
        milliseconds := Round(result.Value * 1000)
        if milliseconds < 1
            throw ValueError("최소 0.001초 이상이어야 합니다.")
        DirCreate A_AppData "\HanLock"
        IniWrite milliseconds, SettingsPath, "Keyboard", "HoldMilliseconds"
    } catch as problem {
        MsgBox "설정을 저장하지 못했습니다.`n" problem.Message, "HanLock 설정", 0x30
        return
    }
    HoldMilliseconds := milliseconds
    PressedAt.Clear()
    updatedMenu := "길게 누르기 기준: " DurationSeconds() "초..."
    A_TrayMenu.Rename(ThresholdMenu, updatedMenu)
    ThresholdMenu := updatedMenu
    UpdateTrayTip()
}

AutoStartEnabled() {
    global AutoStartLink
    if !FileExist(AutoStartLink)
        return false
    FileGetShortcut AutoStartLink, &target,, &arguments
    expectedTarget := A_IsCompiled ? A_ScriptFullPath : A_AhkPath
    expectedArguments := A_IsCompiled ? "" : '"' A_ScriptFullPath '"'
    return target = expectedTarget && arguments = expectedArguments
}

ToggleAutoStart(itemName, *) {
    global AutoStartLink
    try {
        if AutoStartEnabled() {
            FileDelete AutoStartLink
            A_TrayMenu.Uncheck(itemName)
        } else {
            target := A_IsCompiled ? A_ScriptFullPath : A_AhkPath
            arguments := A_IsCompiled ? "" : '"' A_ScriptFullPath '"'
            FileCreateShortcut target, AutoStartLink, A_ScriptDir, arguments,
                "HanLock by lio", target
            A_TrayMenu.Check(itemName)
        }
    } catch as problem {
        MsgBox "자동 시작 설정을 변경하지 못했습니다.`n" problem.Message,
            "HanLock", 0x30
    }
}

ShowAbout(*) {
    MsgBox "HanLock 1.0.0`n제작: lio · 배포: lapalai`n`n"
        . "짧게 누르고 떼기: 한/영 전환`n"
        . DurationSeconds() "초 이상 누른 뒤 떼기: Caps Lock 전환`n`n"
        . "GPL-2.0 · https://github.com/lapalai/hanlock",
        "HanLock 정보", 0x40
}
