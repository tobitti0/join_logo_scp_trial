' Trimファイルとjoin_logo_scp構成解析ファイルからチャプターを標準出力に出力
' 引数１：（入力）出力チャプター形式（org cut tvtplay tvtcut）
' 引数２：（入力）Trimファイル名
' 引数３：（入力）join_logo_scp構成解析ファイル名

Option Explicit

'--------------------------------------------------
' 定数
'--------------------------------------------------
const PREFIX_TVTI = "ix"     ' カット開始時文字列（tvtplay用）
const PREFIX_TVTO = "ox"     ' カット終了時文字列（tvtplay用）
const PREFIX_ORGI = ""       ' カット開始時文字列（カットなしchapter）
const PREFIX_ORGO = ""       ' カット終了時文字列（カットなしchapter）
const PREFIX_CUTO = ""       ' カット終了時文字列（カット後）
const SUFFIX_CUTO = ""       ' カット終了時末尾追加文字列（カット後）

const MODE_ORG = 0
const MODE_CUT = 1
const MODE_TVT = 2
const MODE_TVC = 3

const MSEC_DIVMIN = 100      ' チャプター位置を同一としない時間間隔（msec単位）

'--------------------------------------------------
' 引数読み込み
'--------------------------------------------------
Dim strFormat, strFile1, strFile2
Dim nOutFormat

If WScript.Arguments.Unnamed.Count < 3 Then
  WScript.StdErr.WriteLine "usage:func_chapter_jls.vbs org|cut|tvtplay <TrimFile> <jlsFile>"
  WScript.Quit
End If

strFormat = WScript.Arguments(0)
strFile1  = WScript.Arguments(1)
strFile2  = WScript.Arguments(2)

'--- 出力形式 ---
If StrComp(strFormat, "cut") = 0 Then           'カット後のchapter
  nOutFormat = MODE_CUT
ElseIf StrComp(strFormat, "tvtplay") = 0 Then   'カットしないTvtPlay
  nOutFormat = MODE_TVT
ElseIf StrComp(strFormat, "tvtcut") = 0 Then    'カット後のTvtPlay
  nOutFormat = MODE_TVC
Else                                            'カットしないchapter
  nOutFormat = MODE_ORG
End If

'--------------------------------------------------
' Trimによるカット情報読み込み
' 読み込みデータ。開始位置を表すため終了位置では＋１する。
' nTrimTotal  : Trim位置情報合計（Trim１個につき（開始,終了）で２個）
' nItemTrim() : Trim位置情報（単位はフレーム）
'--------------------------------------------------
'--- 共通変数 ---
Dim objFileSystem, objStream
Dim strBufRead
Dim i
Dim re, matches
Set re = New RegExp
re.Global = True

'--- ファイル読み込み ---
Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
If Not objFileSystem.FileExists(strFile1) Then
  WScript.StdErr.WriteLine "ファイルが見つかりません:" & strFile1
  WScript.Quit
End If
Set objStream = objFileSystem.OpenTextFile(strFile1)
strBufRead = objStream.ReadLine

'--- trimパターン ---
Const strRegTrim = "Trim\((\d+)\,(\d+)\)"
'--- パターンマッチ ---
re.Pattern = strRegTrim
Set matches = re.Execute(strBufRead)
If matches.Count = 0 Then
  WScript.StdErr.WriteLine "Trimデータが読み込めません:" & strBufRead
  WScript.Quit
End If

'--- データ量決定 ---
Dim nTrimTotal
nTrimTotal = matches.Count * 2

'--- 変数に格納 ---
ReDim nItemTrim(nTrimTotal)
For i=0 To nTrimTotal/2 - 1
  nItemTrim(i*2)   = CLng(matches(i).SubMatches(0))
  nItemTrim(i*2+1) = CLng(matches(i).SubMatches(1)) + 1
Next
Set matches = Nothing

'--- ファイルクローズ ---
objStream.Close
Set objStream = Nothing
Set objFileSystem  = Nothing

'--------------------------------------------------
' 構成解析ファイルとカット情報からCHAPTERを作成
'--------------------------------------------------
'--- CHAPTER情報取得に必要な変数 ---
Dim clsChapter
Dim bCutOn, bShowOn, bShowPre, bPartExist
Dim nTrimNum, nType, nLastType, nPart
Dim nFrmTrim, nFrmSt, nFrmEd, nFrmMgn, nFrmBegin
Dim nSecRd, nSecCalc
Dim strCmt, strChapterName, strChapterLast

'--- CHAPTER情報格納用クラス ---
Set clsChapter = New ChapterData

'--- ファイルオープン ---
Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
If Not objFileSystem.FileExists(strFile2) Then
  WScript.StdErr.WriteLine "ファイルが見つかりません:" & strFile2
  WScript.Quit
End If
Set objStream = objFileSystem.OpenTextFile(strFile2)

'--- trimパターン ---
Const strRegJls  = "^\s*(\d+)\s+(\d+)\s+(\d+)\s+([-\d]+)\s+(\d+).*:(\S+)"
'--- 初期設定 ---
re.Pattern = strRegJls
nFrmMgn    = 30          ' Trimと読み込み構成を同じ位置とみなすフレーム数
bShowOn    = 1           ' 最初は必ず表示
nTrimNum   = 0           ' 現在のTrim位置番号
nFrmTrim   = 0           ' 現在のTrimフレーム
nLastType  = 0           ' 直前状態クリア
nPart      = 0           ' 初期状態はAパート
bPartExist = 0           ' 現在のパートは存在なし
nFrmBegin  = 0           ' 次のchapter開始地点

'--- 開始地点設定 ---
' nTrimNum が偶数：次のTrim開始位置を検索
' nTrimNum が奇数：次のTrim終了位置を検索
If (nTrimTotal > 0) Then
  If (nItemTrim(0) <= nFrmMgn) Then  ' 最初の立ち上がりを0フレームと同一視
    nTrimNum   = 1
  End If
Else
  nTrimNum   = 1
End If

'--- 構成情報データを順番に読み出し ---
Do While objStream.AtEndOfLine = false
  strBufRead = objStream.ReadLine
  Set matches = re.Execute(strBufRead)
  If matches.Count > 0 Then
    '--- 読み出しデータ格納 ---
    nFrmSt = CLng(matches(0).SubMatches(0))     ' 開始フレーム
    nFrmEd = CLng(matches(0).SubMatches(1))     ' 終了フレーム
    nSecRd = matches(0).SubMatches(2)           ' 期間秒数
    strCmt = matches(0).SubMatches(5)           ' 構成コメント
    '--- 現在検索中のTrim位置データ取得 ---
    If nTrimNum < nTrimTotal Then
      nFrmTrim = nItemTrim(nTrimNum)
    End If

    '--- 現構成終了位置より手前にTrim地点がある場合の設定処理 ---
    Do While nFrmTrim < nFrmEd - nFrmMgn And nTrimNum < nTrimTotal
      bCutOn  = (nTrimNum+1) Mod 2              ' Trimのカット状態（１でカット）
      '--- CHAPTER文字列取得処理 ---
      nType = ProcChapterTypeTerm(nSecCalc, nFrmBegin, nFrmTrim)
      strChapterName = ProcChapterName(bCutOn, nType, nPart, bPartExist, nSecCalc)
      '--- CHAPTER挿入処理 ---
      Call clsChapter.InsertFrame(nFrmBegin, bCutOn, strChapterName)
      nFrmBegin = nFrmTrim                      ' chapter開始位置変更
      nTrimNum = nTrimNum + 1                   ' Trim番号を次に移行
      If nTrimNum < nTrimTotal Then
        nFrmTrim = nItemTrim(nTrimNum)          ' 次のTrim位置検索に変更
      End If
    Loop

    '--- 現構成位置の判断開始 ---
    bShowPre = 0
    bShowOn = 0
    bCutOn  = (nTrimNum+1) Mod 2                ' Trimのカット状態（１でカット）
    '--- 現終了位置にTrim地点があるか判断（あればCHAPTER表示確定） ---
    If (nFrmTrim <= nFrmEd + nFrmMgn) And (nTrimNum < nTrimTotal) Then
      nFrmEd  = nFrmTrim              ' Trim位置にフレームを変更
      bShowOn = 1                     ' 表示を行う
      nTrimNum = nTrimNum + 1         ' Trim位置を次に移行
    End If

    '--- コメントからCHAPTER表示種類を判断 ---
    ' nType 0:スルー 1:CM部分 10:独立構成 11:part扱いにしない独立構成
    nType = ProcChapterTypeCmt(strCmt, nSecRd)
    '--- CHAPTER区切りを確認（前回と今回の構成で区切るか判断） ---
    If bCutOn <> 0 Then                  ' カットする部分
      If nType = 1 Then                  ' 明示的なCM時
        If nLastType <> 1 Then           ' 前回CM以外だった場合表示
          bShowPre = 1                   ' 前回終了（今回開始）にchapter表示
        End If
      Else                               ' 明示的なCM以外
        If nLastType = 1 Then            ' 前回CMだった場合表示
          bShowPre = 1                   ' 前回終了（今回開始）にchapter表示
        End If
      End If
    End If

    '--- CHAPTER挿入（前回終了位置） ---
    If bShowPre > 0 Or nType >= 10 Then      ' 位置確定のフラグ確認
      If nFrmBegin < nFrmSt - nFrmMgn Then   ' chapter開始位置が今回開始より前
        If nLastType <> 1 Then               ' 前回CM以外の時は種類再確認
          nLastType = ProcChapterTypeTerm(nSecCalc, nFrmBegin, nFrmSt)
        End If
        '--- CHAPTER名文字列を決定し挿入 ---
        strChapterLast = ProcChapterName(bCutOn, nLastType, nPart, bPartExist, nSecCalc)
        Call clsChapter.InsertFrame(nFrmBegin, bCutOn, strChapterLast)
        nFrmBegin = nFrmSt                   ' chapter開始位置を今回開始位置に
      End If
    End If
    '--- CHAPTER挿入（現終了位置） ---
    If bShowOn > 0 Or nType >= 10 Then
      If nFrmEd > nFrmBegin + nFrmMgn Then   ' chapter開始位置が今回終了より前
        '--- CHAPTER名文字列を決定し挿入 ---
        strChapterName = ProcChapterName(bCutOn, nType, nPart, bPartExist, nSecRd)
        Call clsChapter.InsertFrame(nFrmBegin, bCutOn, strChapterName)
        nFrmBegin = nFrmEd                   ' chapter開始位置を今回終了位置に
      End If
    End If

    '--- 次回確認用の処理 ---
    nLastType = nType

  End If
  Set matches = Nothing
Loop

'--- Trim位置の出力完了していない場合の処理 ---
Do While nTrimNum < nTrimTotal
  nFrmTrim = nItemTrim(nTrimNum)

  '--- Trim位置をchapterへ出力 ---
  bCutOn  = (nTrimNum+1) Mod 2                   ' Trimのカット状態（１でカット）
  nType = ProcChapterTypeTerm(nSecCalc, nFrmBegin, nFrmTrim)
  strChapterName = ProcChapterName(bCutOn, nType, nPart, bPartExist, nSecCalc)
  '--- CHAPTER挿入処理 ---
  Call clsChapter.InsertFrame(nFrmBegin, bCutOn, strChapterName)
  nTrimNum = nTrimNum + 1                            ' Trim番号を次に移行
Loop

'--- 最終chapterの出力 ---
If nFrmBegin < nFrmEd - nFrmMgn Then
  bCutOn  = (nTrimNum+1) Mod 2                   ' Trimのカット状態（１でカット）
  nType = ProcChapterTypeTerm(nSecCalc, nFrmBegin, nFrmEd)
  strChapterName = ProcChapterName(bCutOn, nType, nPart, bPartExist, nSecCalc)
  '--- CHAPTER挿入処理 ---
  Call clsChapter.InsertFrame(nFrmBegin, bCutOn, strChapterName)
End If

'--- 結果出力 ---
Call clsChapter.OutputChapter(nOutFormat)

'--- ファイルクローズ ---
objStream.Close
Set objStream = Nothing
Set objFileSystem  = Nothing

Set clsChapter = Nothing

'--- 完了 ---


'--------------------------------------------------
' Chapter種類を取得（開始終了位置から秒数も取得する）
'   nSecRd : （出力）期間秒数
'   nFrmS  : 開始フレーム
'   nFrmE  : 終了フレーム
'  出力
'   nType  : 0:通常 1:明示的にCM 2:part扱いの判断迷う構成
'            10:単独構成 11:part扱いの判断迷う単独構成 12:空欄
'--------------------------------------------------
Function ProcChapterTypeTerm(nSecRd, nFrmS, nFrmE)
  Dim nType

  nSecRd = ProcGetSec(nFrmE - nFrmS)
  If nSecRd = 0 Then
    nType = 12
  ElseIf nSecRd = 90 Then
    nType = 11
  ElseIf CInt(nSecRd) < 15 Then
    nType = 2
  Else
    nType = 0
  End If

  ProcChapterTypeTerm = nType
End Function


'--------------------------------------------------
' Chapter種類を取得（コメント情報を使用する）
'   strCmt : コメント文字列
'   nSecRd : コメントの秒数
'  出力
'   nType  : 0:通常 1:明示的にCM 2:part扱いの判断迷う構成
'            10:単独構成 11:part扱いの判断迷う単独構成 12:空欄
'--------------------------------------------------
Function ProcChapterTypeCmt(strCmt, nSecRd)
  Dim nType

  '--- CHAPTER表示内容か判断 ---
  ' nType  : 0:通常 1:明示的にCM 2:part扱いの判断迷う構成
  '          10:単独構成 11:part扱いの判断迷う単独構成 12:空欄
  If InStr(strCmt, "Trailer(cut)") > 0 Then
    nType   = 0
  ElseIf InStr(strCmt, "Trailer") > 0 Then
    nType   = 10
  ElseIf InStr(strCmt, "Sponsor") > 0 Then
    nType   = 11
  ElseIf InStr(strCmt, "Endcard") > 0 Then
    nType   = 11
  ElseIf InStr(strCmt, "Edge") > 0 Then
    nType   = 11
  ElseIf InStr(strCmt, "Border") > 0 Then
    nType   = 11
  ElseIf InStr(strCmt, "CM") > 0 Then
    nType   = 1             ' 15秒単位CMとそれ以外を分ける必要なければ0にする
  ElseIf nSecRd = 90 Then
    nType   = 11
  ElseIf nSecRd = 60 Then
    nType   = 10
  ElseIf CInt(nSecRd) < 15 Then
    nType   = 2
  Else
    nType   = 0
  End If

  ProcChapterTypeCmt = nType
End Function


'--------------------------------------------------
' CHAPTER名の文字列を決める
'   bCutOn : 0=カットしない部分 1=カット部分
'   nType  : 0:通常 1:明示的にCM 2:part扱いの判断迷う構成
'            10:単独構成 11:part扱いの判断迷う単独構成 12:空欄
'   nPart  : Aパートから順番に数字0～（function内で更新あり）
'   bPartExist : part構成の要素があれば2（function内で更新あり）
'   nSecRd     : 単独構成時の秒数
' 戻り値はCHAPTER名
'--------------------------------------------------
Function ProcChapterName(bCutOn, nType, nPart, bPartExist, nSecRd)
  Dim strChapterName

  If bCutOn = 0 Then                           ' 残す部分
    strChapterName = Chr(Asc("A") + (nPart Mod 23))
    If nType >= 10 Then
      strChapterName = strChapterName & nSecRd & "Sec"
    Else
      strChapterName = strChapterName
    End If
    If nType = 11 Or nType = 2 Then            ' part扱いの判断迷う構成
      If bPartExist = 0 Then
        bPartExist = 1
      End If
    ElseIf nType <> 12 Then
      bPartExist = 2
    End If
  Else                                         ' カットする部分
    If nType >= 10 Then
      strChapterName = "X" & nSecRd & "Sec"
    ElseIf nType = 1 Then
      strChapterName = "XCM"
    Else
      strChapterName = "X"
    End If
    If bPartExist > 0 And nType <> 12 Then
      nPart = nPart + 1
      bPartExist = 0
    End If
  End If
  ProcChapterName = strChapterName
End Function


'--------------------------------------------------
' フレーム数に対応する秒数取得
'--------------------------------------------------
Function ProcGetSec(nFrame)
  '29.97fpsの設定で固定
  ProcGetSec = Int((CLng(nFrame) * 1001 + 30000/2) / 30000)
End Function


'--------------------------------------------------
' CHAPTER格納用クラス
'  InsertMSec     : CHAPTERに追加（ミリ秒で指定）
'  InsertFrame    : CHAPTERに追加（フレーム位置指定）
'  OutputChapter  : CHAPTER情報を標準出力に出力
'--------------------------------------------------
Class ChapterData
  Private m_nMaxList        ' 現在の格納最大
  Private m_nList           ' CHAPTER格納個数
  Private m_nMSec()         ' CHAPTER位置（ミリ秒単位）
  Private m_bCutOn()        ' 0:カットしない位置 1:カット位置
  Private m_strName()       ' チャプター名
  Private m_strOutput       ' 出力格納

  Private Sub Class_Initialize()
    m_nMaxList = 0
    m_nList    = 0
    m_strOutput = ""
  End Sub

  Private Sub Class_Terminate()
  End Sub

  '------------------------------------------------------------
  ' CHAPTER表示用文字列を１個分作成（m_strOutputに格納）
  ' num     : 格納chapter通し番号
  ' nCount  : 出力用chapter番号
  ' nTime   : 位置ミリ秒単位
  ' strName : chapter名
  '------------------------------------------------------------
  Private Sub GetDispChapter(num, nCount, nTime, strName)
    Dim strBuf
    Dim strCount, strTime
    Dim strHour, strMin, strSec, strMsec
    Dim nHour, nMin, nSec, nMsec

    '--- チャプター番号 ---
    strCount = CStr(nCount)
    If (Len(strCount) = 1) Then
      strCount = "0" & strCount
    End If
    '--- チャプター時間 ---
    nHour = Int(nTime / (60*60*1000))
    nMin  = Int((nTime Mod (60*60*1000)) / (60*1000))
    nSec  = Int((nTime Mod (60*1000))    / 1000)
    nMsec = nTime Mod 1000
    strHour = Right("0" & CStr(nHour), 2)
    strMin  = Right("0" & CStr(nMin),  2)
    strSec  = Right("0" & CStr(nSec),  2)
    strMsec = Right("00" & CStr(nMsec), 3)
    StrTime = strHour & ":" & strMin & ":" & strSec & "." & strMsec
    '--- 出力文字列（１行目） ---
    strBuf = "CHAPTER" & strCount & "=" & strTime & vbCRLF
    '--- 出力文字列（２行目） ---
    strBuf = strBuf & "CHAPTER" & strCount & "NAME=" & strName & vbCRLF
    m_strOutput = m_strOutput & strBuf
  End Sub


  '---------------------------------------------
  ' CHAPTERに追加（ミリ秒で指定）
  ' nMSec   : 位置ミリ秒
  ' bCutOn  : 1の時カット
  ' strName : chapter表示用文字列
  '---------------------------------------------
  Public Sub InsertMSec(nMSec, bCutOn, strName)
    If m_nList >= m_nMaxList Then      ' 配列満杯時は再確保
      m_nMaxList = m_nMaxList + 100
      ReDim Preserve m_nMSec(m_nMaxList)
      ReDim Preserve m_bCutOn(m_nMaxList)
      ReDim Preserve m_strName(m_nMaxList)
    End If
    m_nMSec(m_nList)   = nMSec
    m_bCutOn(m_nList)  = bCutOn
    m_strName(m_nList) = strName
    m_nList = m_nList + 1
  End Sub

  '---------------------------------------------
  ' CHAPTERに追加（フレーム位置指定）
  ' nFrame  : フレーム位置
  ' bCutOn  : 1の時カット
  ' strName : chapter表示用文字列
  '---------------------------------------------
  Public Sub InsertFrame(nFrame, bCutOn, strName)
    Dim nTmp
    '29.97fpsの設定で固定
    nTmp = Int((CLng(nFrame) * 1001 + 30/2) / 30)
    Call InsertMSec(nTmp, bCutOn, strName)
  End Sub


  '---------------------------------------------
  ' CHAPTER情報を標準出力に出力
  ' nCutType : MODE_ORG / MODE_CUT / MODE_TVT / MODE_TVC
  '---------------------------------------------
  Public Sub OutputChapter(nCutType)
    Dim i, inext, nCount
    Dim bCutState, bSkip
    Dim nSumTime
    Dim strName

    nSumTime  = CLng(0)      ' 現在の位置（ミリ秒単位）
    nCount    = 1            ' CHAPTER出力番号
    bCutState = 0            ' 前回の状態（0:非カット用 1:カット用）
    m_strOutput = ""         ' 出力
    '--- tvtplay用初期文字列 ---
    If nCutType = MODE_TVT Or nCutType = MODE_TVC Then
      m_strOutput = "c-"
    End If

    '--- CHAPTER設定数だけ繰り返し ---
    inext = 0
    For i=0 To m_nList - 1
      '--- 次のCHAPTERと重なっている場合は除く ---
      bSkip = 0
      If (inext > i) Then
        bSkip = 1
      Else
        inext = i+1
        If (inext < m_nList-1) Then
          If (m_nMSec(inext+1) - m_nMSec(inext) < MSEC_DIVMIN) Then
            inext = inext + 1
          End If
        End If
      End If
      If (bSkip = 0) Then
        '--- 全部表示モードorカットしない位置の時に出力 ---
        If nCutType = MODE_ORG Or nCutType = MODE_TVT Or m_bCutOn(i) = 0 Then
          '--- 最初が0でない時の補正 ---
          If nCutType = MODE_ORG Or nCutType = MODE_TVT Then
            If i = 0 And m_nMSec(i) > 0 Then
              nSumTime  = nSumTime + m_nMSec(i)
            End If
          End If
          '--- tvtplay用 ---
          If nCutType = MODE_TVT Or nCutType = MODE_TVC Then
            '--- CHAPTER名を設定 ---
            If nCutType = MODE_TVC Then                    ' カット済み
              If bCutState > 0 And m_bCutOn(i) = 0 Then    ' カット終了
                strName = m_strName(i) & SUFFIX_CUTO
              Else
                strName = m_strName(i)
              End If
            ElseIf bCutState = 0 And m_bCutOn(i) > 0 Then  ' カット開始
              strName = PREFIX_TVTI & m_strName(i)
            ElseIf bCutState > 0 And m_bCutOn(i) = 0 Then  ' カット終了
              strName = PREFIX_TVTO & m_strName(i)
            Else
              strName = m_strName(i)
            End If
            strName = Replace(strName, "-", "－")
            '--- tvtplay用CHAPTER出力文字列設定 ---
            m_strOutput = m_strOutput & nSumTime & "c" & strName & "-"
          '--- 通常のchapter用 ---
          Else
            '--- CHAPTER名を設定 ---
            If bCutState = 0 And m_bCutOn(i) > 0 Then      ' カット開始
              strName = PREFIX_ORGI & m_strName(i)
            ElseIf bCutState > 0 And m_bCutOn(i) = 0 Then  ' カット終了
              If nCutType = MODE_CUT Then
                strName = PREFIX_CUTO & m_strName(i) & SUFFIX_CUTO
              Else
                strName = PREFIX_ORGO & m_strName(i)
              End If
            Else
              strName = m_strName(i)
            End If
            '--- CHAPTER出力文字列設定 ---
            Call GetDispChapter(i, nCount, nSumTime, strName)
          End If
          '--- 書き込み後共通設定 ---
          nSumTime  = nSumTime + (m_nMSec(inext) - m_nMSec(i))
          nCount    = nCount + 1
        End If
        '--- 現CHAPTERに状態更新 ---
        bCutState = m_bCutOn(i)
      End If
    Next

    '--- tvtplay用最終文字列 ---
    If nCutType = MODE_TVT Then
      If bCutState > 0 Then   ' CM終了処理
        m_strOutput = m_strOutput & "0e" & PREFIX_TVTO & "-"
      Else
        m_strOutput = m_strOutput & "0e-"
      End If
      m_strOutput = m_strOutput & "c"
    ElseIf nCutType = MODE_TVC Then
      m_strOutput = m_strOutput & "c"
    End If
    '--- 結果出力 ---
    WScript.StdOut.Write m_strOutput
  End Sub
End Class
