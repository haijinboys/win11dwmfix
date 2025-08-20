# Win11DwmFix

Windows 11 環境において、Win32 アプリケーションのウィンドウを開いた際に発生する、非クライアント領域の残像が一瞬表示される現象を回避するための DLL です。

## 特徴

- DLL を LoadLibrary するだけで、アプリに簡単に適用できます。
- Mery のプラグインとしても使用できます。

## 環境

**動作環境**
- Windows 11

**ビルド環境**
- Delphi XE2 .. 12

## 使い方

**Delphi**
```delphi
var
  FModule: HMODULE;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FModule := LoadLibrary('Win11DwmFix.dll');
end;
```

**C++**
```cpp
HMODULE hModule = LoadLibrary(L"Win11DwmFix.dll");
```

**Mery のプラグインとして使用する場合**
1. アーカイブを展開し、`Win11DwmFix.dll` を `Mery.exe` のインストール先の `Plugins` フォルダーにコピーしてください。
2. Mery を起動すると、自動的に適用されます。

## 注意事項

- 本 DLL により、当該現象が必ずしも解消されることを保証するものではありません。
- 将来的に Microsoft により当該現象が修正される可能性があります。その場合は、本 DLL を速やかに削除してください。