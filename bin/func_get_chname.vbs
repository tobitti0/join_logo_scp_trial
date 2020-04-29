' csvファイルの内容と一致する放送局を標準出力に出力
' 引数１：（入力）出力情報選択（1:放送局名認識用 2:放送局名設定用 3:放送局略称）
' 引数２：（入力）使用するcsvファイル名
' 引数３：（入力）この文字列に含まれている放送局を探す
'
Option Explicit

Const strSymHan1 = "!""#$%&'()*+,-./"
Const strSymHan2 = ":;<=>?[\]^`{|}~"
Const strSymHan3 = " _"
Const strSymZen1 = "！”＃＄％＆’（）＊＋，－．／"
Const strSymZen2 = "：；＜＝＞？［￥］＾‘｛｜｝～"
Const strSymZen3 = "　＿"
Const strSymZen4 = "・☆★"                  ' 比較不要な記号
Const strSymPar1 = "（〔［｛〈《「『【≪"
Const strSymPar2 = "）〕］｝〉》」』】≫"
Const strSymStp  = " _（）"                  ' 放送局区切り検出用


'---------------------------------------------------------------------
' 引数入力
'---------------------------------------------------------------------
Dim oParam, nOutType, strFileRead, strIn1
Set oParam = WScript.Arguments

If (oParam.Count < 2) Then
  WScript.Echo "引数不足"
  WScript.Quit
End If

nOutType     = oParam(0)
strFileRead  = oParam(1)
strIn1       = oParam(2)

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
Dim strBufRead
Dim strInData, strInDataA
Dim nDimItem
Dim strItemData()
Dim strTmp
Dim strPreCh1, strPreCh2
Dim nResultCur
Dim nResultLevel
Dim strResultA
Dim strResultB
Dim strResultC

Dim nMatch
Dim re, matches
Set re = New RegExp

'--- 初期化 ---
nResultLevel = 0

'--- 入力データの文字列から比較文字列を取得 ---
strInData = ProcString(strIn1, 1)
strInDataA = Replace(strInData, "－", "")     ' 略称はハイフンなしで比較

'--- １行目の文字列取得 ---
strBufRead = objStream.ReadLine
strBufRead = Replace(strBufRead, vbCrLf, "")
' 各項目取得・設定
nDimItem = GetCsvData(strItemData,strBufRead, 0)
ReDim strItemData(nDimItem)

'--- ２行目以降の処理 ---
Do While objStream.AtEndOfStream <> True
  strBufRead = objStream.ReadLine
  strBufRead = Replace(strBufRead, vbCrLf, "")

  Call GetCsvData(strItemData,strBufRead, nDimItem)
  nMatch = 1
  nResultCur = 0

  '--- 放送局の一致確認 ---
  If (nResultLevel < 5) Then        ' 一致が未検出の場合
    If (strItemData(0) <> "") Then
      strTmp = ProcString(strItemData(0), 1)
      re.Pattern = "( ?)(.?)" & strTmp
      Set matches = re.Execute(strInData)
      If (matches.Count > 0) Then
        '--- 一致の手前文字が区切りか確認 ---
        strPreCh1 = matches.Item(0).SubMatches.Item(0)
        strPreCh2 = matches.Item(0).SubMatches.Item(1)
        If (strPreCh1 = "" And strPreCh2 = "") Then      ' ファイル先頭時
          nResultCur = 5
        ElseIf (strPreCh1 = " " And strPreCh2 = "") Then ' 空白時
          nResultCur = 1
        ElseIf (InStr(strSymStp, strPreCh2) > 0) Then    ' ファイル区切り
          If (strPreCh1 = " " And strPreCh2 = "_") Then  ' 明確な区切り
            nResultCur = 5
          ElseIf (strPreCh2 = "（") Then                 ' 括弧
            nResultCur = 4
          Else                                           ' 不明確な区切り
            nResultCur = 1
          End If
        End If
      End If
      Set matches = Nothing
    End If
  End If

  '--- 略称の一致確認 ---
  If (nResultLevel < 5) Then        ' 一致が未検出の場合
    If (strItemData(2) <> "") Then
      strTmp = ProcString(strItemData(2), 1)
      strTmp = Replace(strTmp, "－", "")       ' 略称はハイフンなしで比較
      re.Pattern = "(.?)" & strTmp & "(.?)"
      Set matches = re.Execute(strInDataA)
      If (matches.Count > 0) Then
        '--- 一致の前後文字が区切りか確認 ---
        strPreCh1 = matches.Item(0).SubMatches.Item(0)
        strPreCh2 = matches.Item(0).SubMatches.Item(1)
        If ((strPreCh1 = "" Or InStr(strSymStp, strPreCh1) > 0) And _
            (strPreCh2 = "" Or InStr(strSymStp, strPreCh2) > 0)) Then
          If (strPreCh1 = "（") Then    ' 手前が"("の時優先順位を上げる
            nResultCur = 5
          ElseIf (nResultCur < 2) Then  ' それ以外の区切り
            nResultCur = 2
          End If
        End If
      End If
      Set matches = Nothing
    End If
  End If

  '--- 一致時の処理 ---
  If (nResultCur > 0) Then
'    WScript.echo "*** match ***" & nResultCur & " " & strItemData(0)
    If (nResultLevel < nResultCur) Then
      nResultLevel = nResultCur
      strResultA = strItemData(0)
      strResultB = strItemData(1)
      strResultC = strItemData(2)
    End If
  End If
Loop

objStream.Close
Set objStream = Nothing
Set objFileSystem = Nothing
Set re = Nothing

'---------------------------------------------------------------------
' 結果出力
'---------------------------------------------------------------------
If (nResultLevel = 0) Then       ' 一致がなかった時の出力
  WScript.echo ""
ElseIf (nOutType = 1) Then       ' 放送局名(認識用）を出力
  WScript.echo strResultA
ElseIf (nOutType = 2) Then       ' 放送局名（設定用）を出力
  WScript.echo strResultB
Else                             ' 放送局略称を出力
  WScript.echo strResultC
End If

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
