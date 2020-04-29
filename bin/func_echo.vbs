Option Explicit
'“ü—Í•¶š—ñ‚ğ“Áê•¶š‚Í•ÏŠ·A‚»‚êˆÈŠO‚Í‚»‚Ì‚Ü‚Ü•Ô‚·

Dim oParam
Dim oStr
Set oParam = WScript.Arguments
oStr = oParam(0)
oStr = Replace(oStr, "&", "•")
oStr = Replace(oStr, "^", "O")
oStr = Replace(oStr, "%", "“")
WScript.echo oStr
Set oParam   = Nothing
