Option Explicit
' unicodeで文字列をファイルに出力
' 引数１：（入力）出力ファイル名
' 引数２：（入力）出力文字列

Dim oParam
Dim strFileName
Dim strTextData
Set oParam = WScript.Arguments
If (oParam.Count < 2) Then
  WScript.Echo "引数不足"
  WScript.Quit
End If
strFileName = oParam(0)
strTextData = oParam(1)
Set oParam = Nothing

Dim objFS
Dim objStreamW
Set objFS = WScript.CreateObject("Scripting.FileSystemObject")
Set objStreamW = objFS.OpenTextFile(strFileName, 2, 1, -1)

objStreamW.WriteLine strTextData

objStreamW.Close

Set objStreamW = Nothing
Set objFS = Nothing

