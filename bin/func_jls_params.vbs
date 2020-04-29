' csvファイルの内容（放送局、タイトル）と一致したら変数を標準出力に出力
' 引数１：（入力）使用するcsvファイル名
' 引数２：（入力）今回の放送局略称
' 引数３：（入力）今回のタイトル文字列
'
Option Explicit

Const strSymHan1 = "!""#$%&'()*+,-./"
Const strSymHan2 = ":;<=>?[\]^`{|}~"
Const strSymHan3 = " _-"
Const strSymZen1 = "！”＃＄％＆’（）＊＋，－．／"
Const strSymZen2 = "：；＜＝＞？［￥］＾‘｛｜｝～"
Const strSymZen3 = "　＿－"
Const strSymZen4 = "・☆★"                  ' 比較不要な記号
Const strSymPar1 = "（〔［｛〈《「『【≪"
Const strSymPar2 = "）〕］｝〉》」』】≫"
Const strSymStp  = " _（）"                  ' 放送局区切り検出用
Const strSymRExp = ".*+?|[]^"                ' 正規表現扱い検出用

'---------------------------------------------------------------------
' 引数入力
'---------------------------------------------------------------------
Dim oParam, strFileRead, strIn1, strIn2
Set oParam = WScript.Arguments

If (oParam.Count < 3) Then
  WScript.Echo "引数不足"
  WScript.Quit
End If

strFileRead  = oParam(0)
strIn1       = oParam(1)
strIn2       = oParam(2)

Set oParam   = Nothing

'---------------------------------------------------------------------
' ファイルオープン
'---------------------------------------------------------------------
Dim objFileSystem, objStream

Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
Set objStream = objFileSystem.OpenTextFile(strFileRead)

'---------------------------------------------------------------------
' 項目取得
'---------------------------------------------------------------------
Dim i
Dim strBufRead
Dim strInData1, strInData2
Dim nDimItem
Dim nLocComment
Dim strItemHead()
Dim strItemData()
Dim nMatch

'--- 初期化 ---
nLocComment = -1

'--- 入力データの文字列から比較文字列を取得 ---
strInData1 = ProcString(strIn1, 2)
strInData2 = ProcString(strIn2, 2)

'--- １行目の文字列取得 ---
strBufRead = objStream.ReadLine
strBufRead = Replace(strBufRead, vbCrLf, "")
' 各項目取得・設定
nDimItem = GetCsvData(strItemHead,strBufRead, 0)
ReDim strItemHead(nDimItem)
ReDim strItemData(nDimItem)
Call GetCsvData(strItemHead, strBufRead, nDimItem)
' コメント表示列を取得
For i=0 To nDimItem-1
  If (Left(strItemHead(i), 1) = "#") Then
    If (nLocComment < 0) Then
      nLocComment = i
    End If
  End If
Next

'--- ２行目以降の処理 ---
Do While objStream.AtEndOfStream <> True
  strBufRead = objStream.ReadLine
  strBufRead = Replace(strBufRead, vbCrLf, "")

  '--- csvデータ読み込み ---
  Call GetCsvData(strItemData,strBufRead, nDimItem)
  nMatch = 1

  '--- 放送局の一致確認 ---
  If (strItemData(0) <> "") Then
    If (CompareString(strInData1, strItemData(0), 1) = 0) Then
      nMatch = 0
    ElseIf (Left(strItemData(0), 1) = "#") Then
      nMatch = 0
    End If
  End If

  '--- タイトルの一致確認 ---
  If (strItemData(1) <> "") Then
    If (CompareString(strInData2, strItemData(1), 2) = 0) Then
      nMatch = 0
    End If
  End If

  '--- 一致時の処理 ---
  If (nMatch > 0) Then
    ' コメント行表示
    If (nLocComment >= 0) Then
      If (strItemData(nLocComment) <> "") Then
        WScript.echo "rem ## " & strItemData(nLocComment)
      End If
    End If

    ' 各項目表示
    For i=2 To nDimItem-1
      If (strItemHead(i) <> "" And strItemData(i) <> "") Then
        If (Left(strItemHead(i), 1) <> "#") Then
          If (StrComp(strItemData(i), "@") = 0) Then
            WScript.echo "set " & strItemHead(i) & "="
          Else
            WScript.echo "set " & strItemHead(i) & "=" & strItemData(i)
          End If
        End If
      End If
    Next

    WScript.echo
  End If
Loop

objStream.Close


Set objStream = Nothing
Set objFileSystem = Nothing


'---------------------------------------------------------------------
' ２つの文字列を比較
' 引数
'   strSrc  : 検索先の文字列
'   strCmp  : 検索する文字列
'   nType   : 1=放送局比較用  2=タイトル比較用
' 戻り値： 0=不一致  1=一致
'---------------------------------------------------------------------
Function CompareString(strSrc, strCmp, nType)
  Dim i
  Dim nLen
  Dim nRegExp
  Dim nResult
  Dim strTmp
  Dim ary
  Dim nChk
  Dim re, matches
  Set re = New RegExp

  nResult = 1
  nLen = Len(strCmp)
  If (nLen > 0) Then
    '--- 正規表現にするかチェック ---
    nRegExp = 0
    i = 1
    Do While (i <= nLen And nRegExp = 0)
      if (InStr(strSymRExp, Mid(strCmp, i, 1)) > 0) Then
        nRegExp = 1              ' 正規表現比較を行う
      End If
      i = i + 1
    Loop
    '--- 文字列の比較 ---
    If (nRegExp > 0) Then        ' 正規表現時の比較
      strTmp = ProcString(strCmp, 3)     ' 半角記号はそのまま
      If (nType = 1) Then
        re.Pattern = "^" & strTmp & "$"
      Else
        re.Pattern = strTmp
      End If
      Set matches = re.Execute(strSrc)
      If (matches.Count = 0) Then
        nResult = 0
      End If
      Set matches = Nothing
    Else                          ' スペース区切り検索時
      If (nType = 1) Then         ' 放送局検出時はORを取るため初期状態を不一致
        nResult = 0
      End If
      strTmp = ProcString(strCmp, 2)     ' タイトル検索用文字列変換
      ary = Split(strTmp)                 ' スペース区切り
      For i=0 To UBound(ary)
        strTmp = ary(i)
        If (nType = 1) Then                     ' 放送局
          If (StrComp(strSrc, strTmp) = 0) Then ' 文字列完全一致
            nResult = 1
          End If
        Else                                    ' タイトル
          If (InStr(strSrc, strTmp) = 0) Then   ' 文字列検出なし
            nResult = 0
          End If
        End If
      Next
    End If
  End If

  CompareString = nResult
  Set re = Nothing
End Function


'---------------------------------------------------------------------
' csv形式の文字列から各項目を取得
' 引数
'   strItem : 取得した各項目の文字列配列（出力）
'   strLine : csv形式の文字列（入力）
'   nDim    : 文字列を格納する項目数（入力）
' 戻り値は、取得した項目数
'---------------------------------------------------------------------
Function GetCsvData(strItem, strLine, nDimItem)
  Dim i
  Dim str1, str2
  Dim nCount
  Dim nDQ, nPDQ, nAdd

  str1 = ""
  nCount = 0
  nDQ = 0
  nPDQ = 0
  '--- 文字列を順番に確認 ---
  For i=1 To Len(strLine)
    str2 = Mid(strLine, i, 1)
    nAdd = 1
    '--- １つ前がダブルクォートの時、項目終了判断 ---
    If (nPDQ > 0) Then
      If (str2 = "," And nDQ = 1) Then
        nDQ = 0
      End If
    End If
    '--- 項目区切りがあれば項目確定処理 ---
    If (str2 = "," And nDQ = 0) Then
      If (nCount < nDimItem) Then    ' 取得した文字列を出力
        strItem(nCount) = str1
      End If
      str1 = ""
      nCount = nCount + 1
      nAdd = 0
      nPDQ = 0
    '--- ダブルクォートの時 ---
    ElseIf (str2 = """") Then
      If (nPDQ = 0) Then
        nPDQ = 1
        nAdd = 0
      ElseIf (nPDQ = 1 And nDQ = 0 And str1 = "") Then
        nPDQ = 2
        nAdd = 0
      End If
    End If
    '--- 項目に文字追加 ---
    If (nAdd > 0) Then
      If (nPDQ > 0) Then
        nPDQ = 0
        If (str1 = "") Then
          nDQ  = 1
        End If
      End If
      str1 = str1 & str2
    End If
  Next
  '--- 項目最後まで格納 ---
  Do While(nCount < nDimItem)
    strItem(nCount) = str1
    str1 = ""
    nCount = nCount + 1
  Loop

  GetCsvData = nCount + 1
End Function


'---------------------------------------------------------------------
' 文字列比較のため、全角英数字は半角大文字に変換、記号は引数による処理
' 引数
'   strData : 加工する文字列（入力）
'   nType   : 文字列処理（入力）
'              0:そのまま出力
'              1:放送局文字列検索用（記号は全角化＋加工あり）
'              2:タイトル検索用（記号は全角化）
'              3:正規表現タイトル検索用（半角記号はそのまま）
'
' 戻り値は、変換後の文字列
'---------------------------------------------------------------------
Function ProcString(strData, nType)
  Dim i
  Dim strNew, strCh

  strNew = ""
  For i=1 To Len(strData)
    strCh = Mid(strData, i, 1)
    Call ConvChar(strCh, nType)
    strNew = strNew & strCh
  Next
  ProcString = strNew
End Function


'---------------------------------------------------------------------
' 文字を主に全角半角の変換をする
' 引数
'   strCh : チェック対象の文字（入力＋出力）
'   nType : 文字列処理（入力）
' 戻り値は、記号検出した場合は1、それ以外は0
'---------------------------------------------------------------------
Function ConvChar(strCh, nType)
  Dim j, k
  Dim nDet

  nDet = 0
  ' 半角記号は全角に変換
  If (nType = 1 Or nType = 2) Then
    j = InStr(strSymHan1, strCh)         ' 半角記号１パターン目
    If (j > 0) Then
      strCh = Mid(strSymZen1, j, 1)
      nDet = 1
    End If

    j = InStr(strSymHan2, strCh)         ' 半角記号２パターン目
    If (j > 0) Then
      strCh = Mid(strSymZen2, j, 1)
      nDet = 1
    End If
  End If

  '全角記号を加工
  If (nType = 1) Then
    j = InStr(strSymPar1, strCh)
    If (j > 0) Then
      strCh = "（"
      nDet = 1
    End If

    j = InStr(strSymPar2, strCh)
    If (j > 0) Then
      strCh = "）"
      nDet = 1
    End If

    j = InStr(strSymZen4, strCh)
    If (j > 0) Then
      strCh = ""
      nDet = 1
    End If
  End If

  ' 英数字の全角文字を半角にする
  If (nType >= 0 And nType <= 3) Then
    '英数字扱いの全角文字を半角にする
    j = InStr(strSymZen3, strCh)
    If (j > 0) Then
      strCh = Mid(strSymHan3, j, 1)
      nDet = 1
    End If

    If (nDet = 0) Then
      k = Asc(strCh)
      If (k >= Asc("０") And k <= Asc("９")) Then
        strCh = Chr(k - Asc("０") + Asc("0"))
        nDet = 1
      ElseIf (k >= Asc("Ａ") And k <= Asc("Ｚ")) Then
        strCh = Chr(k - Asc("Ａ") + Asc("A"))
        nDet = 1
      ElseIf (k >= Asc("ａ") And k <= Asc("ｚ")) Then
        strCh = Chr(k - Asc("ａ") + Asc("a"))
        nDet = 1
      End If
    End If
  End If

  ' 小文字を大文字にする
  If (nType >= 0 And nType <= 3) Then
    k = Asc(strCh)
    If (k >= Asc("a") And k <= Asc("z")) Then
      strCh = Chr(k - Asc("a") + Asc("A"))
      nDet = 1
    End If
  End If

  ConvChar = nDet

End Function
