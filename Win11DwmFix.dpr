// -----------------------------------------------------------------------------
// Copyright (c) Kuro. All rights reserved.
// Licensed under the MIT License.
// -----------------------------------------------------------------------------

library Win11DwmFix;

{$R 'mPlugin.res' 'mPlugin.rc'}

{$IFDEF DEBUG}
{$R *.res}
{$ENDIF}


uses
  Winapi.Windows,
  Winapi.Messages;

resourcestring
  SName = 'Win11DwmFix';
  SVersion = '1.0.1';

const
  IDS_TEXT = 1;

const
  MP_FIRST = WM_USER + $0500;
  MP_GET_NAME = MP_FIRST + 2;
  MP_GET_VERSION = MP_FIRST + 3;

const
  DWMWA_ALLOW_NCPAINT = 4;

type
  TCallWndHook = record
    ThreadId: Cardinal;
    Hook: HHOOK;
  end;

var
  SaveDllProc: TDLLProc;
  FNcPaint: array of HWND;
  FCallWndHooks: array of TCallWndHook;

function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD;
  pvAttribute: Pointer; cbAttribute: DWORD): HResult; stdcall;
  external 'DWMAPI.DLL' name 'DwmSetWindowAttribute' delayed;

function IndexOfHWND(hwnd: HWND): Integer;
var
  I: Integer;
begin
  for I := 0 to Length(FNcPaint) - 1 do
    if FNcPaint[I] = hwnd then
      Exit(I);
  Result := -1;
end;

function IndexOfThread(AThreadId: Cardinal): Integer;
var
  I: Integer;
begin
  for I := 0 to Length(FCallWndHooks) - 1 do
    if FCallWndHooks[I].ThreadId = AThreadId then
      Exit(I);
  Result := -1;
end;

function CallWindowHook(Code: Integer; wParam: WPARAM;
  Msg: PCWPStruct): LongInt; stdcall;
var
  I, LIndex: Integer;
  LAttribute: BOOL;
begin
  if Code = HC_ACTION then
    case Msg.message of
      WM_SHOWWINDOW:
        if (Msg.wParam <> 0) and ((GetWindowLong(Msg.hwnd, GWL_STYLE) and WS_CHILD) = 0) and (IndexOfHWND(Msg.hwnd) < 0) then
        begin
          LAttribute := True;
          DwmSetWindowAttribute(Msg.hwnd, DWMWA_ALLOW_NCPAINT, @LAttribute, SizeOf(LAttribute));
          SetLength(FNcPaint, Length(FNcPaint) + 1);
          FNcPaint[Length(FNcPaint) - 1] := Msg.hwnd;
        end;
      WM_NCPAINT:
        begin
          LIndex := IndexOfHWND(Msg.hwnd);
          if LIndex > -1 then
          begin
            LAttribute := False;
            DwmSetWindowAttribute(Msg.hwnd, DWMWA_ALLOW_NCPAINT, @LAttribute, SizeOf(LAttribute));
            for I := LIndex to Length(FNcPaint) - 2 do
              FNcPaint[I] := FNcPaint[I + 1];
            SetLength(FNcPaint, Length(FNcPaint) - 1);
          end;
        end;
    end;
  LIndex := IndexOfThread(GetCurrentThreadId);
  if LIndex > -1 then
    Result := CallNextHookEx(FCallWndHooks[LIndex].Hook, Code, wParam, LPARAM(Msg))
  else
    Result := 0;
end;

procedure DllEntry(Reason: Integer);
var
  I, LIndex: Integer;
  LThreadId: Cardinal;
begin
  LThreadId := GetCurrentThreadId;
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        SetLength(FNcPaint, 0);
        SetLength(FCallWndHooks, 0);
      end;
    DLL_THREAD_ATTACH:
      if IndexOfThread(LThreadId) < 0 then
      begin
        SetLength(FCallWndHooks, Length(FCallWndHooks) + 1);
        with FCallWndHooks[Length(FCallWndHooks) - 1] do
        begin
          ThreadId := LThreadId;
          Hook := SetWindowsHookEx(WH_CALLWNDPROC, @CallWindowHook, 0, LThreadId);
        end;
      end;
    DLL_THREAD_DETACH:
      begin
        LIndex := IndexOfThread(LThreadId);
        if LIndex > -1 then
        begin
          UnhookWindowsHookEx(FCallWndHooks[LIndex].Hook);
          for I := LIndex to Length(FCallWndHooks) - 2 do
            FCallWndHooks[I] := FCallWndHooks[I + 1];
          SetLength(FCallWndHooks, Length(FCallWndHooks) - 1);
        end;
      end;
    DLL_PROCESS_DETACH:
      begin
        for I := 0 to Length(FCallWndHooks) - 1 do
          UnhookWindowsHookEx(FCallWndHooks[I].Hook);
        SetLength(FCallWndHooks, 0);
        SetLength(FNcPaint, 0);
      end;
  end;
  if Assigned(SaveDllProc) then
    SaveDllProc(Reason);
end;

procedure OnCommand(hwnd: HWND); stdcall;
begin
  //
end;

function QueryStatus(hwnd: HWND; pbChecked: PBOOL): BOOL; stdcall;
begin
  pbChecked^ := True;
  Result := True;
end;

function GetMenuTextID: Cardinal; stdcall;
begin
  Result := IDS_TEXT;
end;

function GetStatusMessageID: Cardinal; stdcall;
begin
  Result := IDS_TEXT;
end;

function GetIconID: Cardinal; stdcall;
begin
  Result := 0;
end;

function GetIconDarkID: Cardinal; stdcall;
begin
  Result := 0;
end;

procedure OnEvents(hwnd: HWND; nEvent: Cardinal; lParam: LPARAM); stdcall;
begin
  //
end;

function PluginProc(hwnd: HWND; nMsg: Cardinal; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall;
begin
  Result := 0;
  case nMsg of
    MP_GET_NAME:
      begin
        Result := Length(SName);
        if lParam <> 0 then
          lstrcpynW(PChar(lParam), PChar(SName), wParam);
      end;
    MP_GET_VERSION:
      begin
        Result := Length(SVersion);
        if lParam <> 0 then
          lstrcpynW(PChar(lParam), PChar(SVersion), wParam);
      end;
  end;
end;

exports
  OnCommand,
  QueryStatus,
  GetMenuTextID,
  GetStatusMessageID,
  GetIconID,
  GetIconDarkID,
  OnEvents,
  PluginProc;

begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  SaveDllProc := @DllProc;
  DllProc := @DllEntry;
  DllEntry(DLL_PROCESS_ATTACH);
  DllEntry(DLL_THREAD_ATTACH);

end.
