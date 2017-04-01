#include <Array.au3>
#include <WinHTTQ.au3>

Global $hSession = _WinHTTPOpen()
Global $Wi_ReadBufferSize = 262144
Dim $cookies[100][2]


;;;;;;;;;;;;; PARAMETERS

$creds = "brainiac94:whigger94"
$x = 404
$y = 632
$color = 3

;;;;;;;;;;;;; code starts here


; Debug lines are tabbed off to the right. Hopefully this makes it slightly more readable.

								ConsoleWrite("Logging in as " & $creds & @CRLF)
$modhash = get_session($creds, $cookies)
If @error Then ConsoleWrite("!> Error logging in. Invalid credentials or banned" & @CRLF)
								ConsoleWrite("+> modhash: " & $modhash & @CRLF & @CRLF & @CRLF)

								ConsoleWrite("Waiting a bit")
For $i = 0 To 5
								ConsoleWrite(".")
	Sleep(1000)
Next
								ConsoleWrite(@CRLF)

				;_ArrayDisplay($cookies)

								ConsoleWrite("Requesting to draw" & @CRLF)

$http = do_draw($x, $y, $color, $cookies, $modhash)

								ConsoleWrite("Result: " & @CRLF)
								ConsoleWrite(BinaryToString($http[0]))

;;;;;;; end of main

Func get_session($creds, ByRef $cookies)
	$_creds = StringSplit($creds, ":")
	$user = $_creds[1]
	$passwd = $_creds[2]
	$a = _https("www.reddit.com", "api/login/" & $user, "op=login-main&user=" & $user & "&passwd=" & $passwd & "&api_type=json")
	;ConsoleWrite("-> " & BinaryToString($a[0]) & @CRLF)
	$http = BinaryToString($a[0])
	ConsoleWrite($http & @CRLF)

	ProcessCookies($a[1], $cookies)

	SetCookie("eu_cookie_v2", "2", $cookies)
	SetCookie("loidcreated", "", $cookies)
	SetCookie("_recent_srs", "t5_2sxhs", $cookies)
	SetCookie($user & "_recent_srs", "t5_2sxhs", $cookies)
	SetCookie("pc", "in", $cookies)

	ConsoleWrite("-> " & CompileCookies($cookies) & @CRLF)

	$modhash = stringextract($http, '"modhash": "', '",')
	Return $modhash
EndFunc   ;==>get_session

Func do_draw($x, $y, $color, $session_cookies, $modhash)
	$paint_http = _https("www.reddit.com", "api/place/draw.json", "x=474&y=659&color=5", CompileCookies($session_cookies), "x-modhash: " & $modhash & @CRLF & _
			"x-requested-with: XMLHttpRequest" & @CRLF)
	Return $paint_http
EndFunc   ;==>do_draw

Func ProcessCookies($header, ByRef $cookies)
	$header = StringSplit($header, @CRLF)
	For $line In $header
		If StringLeft($line, 12) = "Set-Cookie: " Then
			$line = StringTrimLeft($line, 12)
			$line = StringSplit($line, ";")
			$cookie = $line[1]
			$cookie = StringSplit($cookie, "=")
			If $cookie[2] = "deleted" Then
				DeleteCookie($cookie[1], $cookies)
			Else
				SetCookie($cookie[1], $cookie[2], $cookies)
			EndIf
		EndIf
	Next
EndFunc   ;==>ProcessCookies

Func SetCookie($name, $value, ByRef $cookies)
	For $i = 0 To 99
		If $cookies[$i][0] = $name Or $cookies[$i][0] = "" Then
			$cookies[$i][0] = $name
			$cookies[$i][1] = $value
			For $j = $i + 1 To 99
				If $cookies[$j][0] = $name Then $cookies[$j][0] = ""
			Next
			Return
		EndIf
	Next
EndFunc   ;==>SetCookie

Func CompileCookies(ByRef $cookies)
	$cookiestring = ""
	For $i = 0 To 99
		If $cookies[$i][0] <> "" Then
			$cookiestring &= $cookies[$i][0] & "=" & $cookies[$i][1] & "; "
		EndIf
	Next
	$cookiestring = StringTrimRight($cookiestring, 2)
	Return $cookiestring
EndFunc   ;==>CompileCookies

Func DeleteCookie($name, ByRef $cookies)
	For $i = 0 To 99
		If $cookies[$i][0] = $name Then
			$cookies[$i][0] = ""
			$cookies[$i][1] = ""
		EndIf
	Next
EndFunc   ;==>DeleteCookie

Func GetCookie($name, ByRef $cookies)
	For $i = 0 To 99
		If $cookies[$i][0] = $name Then Return $cookies[$i][1]
	Next
	Return ""
EndFunc   ;==>GetCookie

Func stringextract($string, $start, $end, $offset = 1)
	$left_bound = StringInStr($string, $start, 0, 1, $offset)
	If $left_bound = 0 Then Return SetExtended(-1, "")
	$left_bound += StringLen($start)
	$right_bound = StringInStr($string, $end, 0, 1, $left_bound)
	If $right_bound = 0 Then Return SetExtended(-1, "")
	Return SetExtended($left_bound, StringMid($string, $left_bound, $right_bound - $left_bound))
EndFunc   ;==>stringextract

Func _http($Domain_Name, $URI = "", $content = "", $http_cookies = "", $Additional_Header = "")
	Local $HTTP_Header, $Received_Content, $Content_Length, $Received_Piece, $Previous_Size, $Content_Type = "application/x-www-form-urlencoded"
	Dim $Return[2]
	Dim $aReceived_Content[2]
	$init = TimerInit()
	If StringInStr($Domain_Name, ":") Then
		$Domain_Name = StringSplit($Domain_Name, ":")
		$Port = $Domain_Name[2]
		$Domain_Name = $Domain_Name[1]
	Else
		$Port = 80
	EndIf
	Local $retr = ""

	If $content <> "" Then
		$hConnect = _WinHttpConnect($hSession, $Domain_Name, $Port)
		If @error Then
			$Return[1] = "Connection refused"
			Return $Return
		EndIf
		$hRequest = _WinHTTPOpenRequest($hConnect, "POST", $URI, Default, Default, Default, 0x40)
		$sHeader = "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" & @CRLF & _
				"User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64; rv:33.0) Gecko/20100101 Firefox/33.0" & @CRLF & _
				$Additional_Header
		_WinHttpSendRequest($hRequest, $sHeader, $content)
		If @error Then
			$Return[1] = "Connection refused"
			Return $Return
		EndIf
		_WinHttpReceiveResponse($hRequest)
		If @error Then
			$Return[1] = "Connection refused"
			Return $Return
		EndIf
		$headers = _WinHttpQueryHeaders($hRequest)
		$Received_Content = Binary("")
		Do
			$Received_Content &= _WinHttpReadData($hRequest, 2, $Wi_ReadBufferSize)
		Until @error
	Else
		$hConnect = _WinHttpConnect($hSession, $Domain_Name, $Port)
		If @error Then
			$Return[1] = "Connection refused"
			Return $Return
		EndIf
		$hRequest = _WinHTTPOpenRequest($hConnect, "GET", $URI, Default, Default, Default, 0x40)
		$sHeader = "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" & @CRLF & _
				"User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64; rv:33.0) Gecko/20100101 Firefox/33.0" & @CRLF & _
				$Additional_Header
		_WinHttpSendRequest($hRequest, $sHeader)
		If @error Then
			$Return[1] = "Connection refused"
			Return $Return
		EndIf
		_WinHttpReceiveResponse($hRequest)
		If @error Then
			$Return[1] = "Connection refused"
			Return $Return
		EndIf
		$headers = _WinHttpQueryHeaders($hRequest)
		$Received_Content = Binary("")
		Do
			$Received_Content &= _WinHttpReadData($hRequest, 2, $Wi_ReadBufferSize)
		Until @error
	EndIf
	$Return[0] = $Received_Content
	$Return[1] = $headers
	Return $Return
EndFunc   ;==>_http

Func _https($Domain_Name, $URI = "", $content = "", $http_cookies = "", $Additional_Header = "")
	Local $HTTP_Header, $Received_Content, $Content_Length, $Received_Piece, $Previous_Size, $Content_Type = "application/x-www-form-urlencoded"
	Dim $Return[2]
	Dim $aReceived_Content[2]
	$init = TimerInit()
	If StringInStr($Domain_Name, ":") Then
		$Domain_Name = StringSplit($Domain_Name, ":")
		$Port = $Domain_Name[2]
		$Domain_Name = $Domain_Name[1]
	Else
		$Port = 443
	EndIf
	Local $retr = ""

	If $content <> "" Then
		$hConnect = _WinHttpConnect($hSession, $Domain_Name, $Port)
		If @error Then
			$Return[1] = "Connection refused 0"
			Return $Return
		EndIf
		$hRequest = _WinHTTPOpenRequest($hConnect, "POST", $URI, Default, Default, Default, 0x800040)
		$sHeader = "Content-Type: application/x-www-form-urlencoded" & @CRLF & _
				"User-Agent: Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" & @CRLF & _
				"Content-Length: " & BinaryLen($content)
		If $http_cookies <> "" Then $sHeader &= @CRLF & "Cookie: " & $http_cookies
		If $Additional_Header <> "" Then $sHeader &= @CRLF & $Additional_Header
		_WinHttpSendRequest($hRequest, $sHeader, $content)
		If @error Then
			$Return[1] = "Connection refused 1"
			Return $Return
		EndIf
		_WinHttpReceiveResponse($hRequest)
		If @error Then
			$Return[1] = "Connection refused 2"
			Return $Return
		EndIf
		$headers = _WinHttpQueryHeaders($hRequest)
		$Received_Content = _WinHttpReadData($hRequest, 2, $Wi_ReadBufferSize)
	Else
		$hConnect = _WinHttpConnect($hSession, $Domain_Name, $Port)
		If @error Then
			$Return[1] = "Connection refused 3"
			Return $Return
		EndIf
		$hRequest = _WinHTTPOpenRequest($hConnect, "GET", $URI, Default, Default, Default, 0x800040)
		$sHeader = "User-Agent: Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" & @CRLF & _
				$Additional_Header
		If $http_cookies <> "" Then $sHeader &= @CRLF & "Cookie: " & $http_cookies
		_WinHttpSendRequest($hRequest, $sHeader)
		If @error Then
			$Return[1] = "Connection refused 4"
			Return $Return
		EndIf
		_WinHttpReceiveResponse($hRequest)
		If @error Then
			$Return[1] = "Connection refused 5"
			Return $Return
		EndIf
		$headers = _WinHttpQueryHeaders($hRequest)
		$Received_Content = _WinHttpReadData($hRequest, 2, $Wi_ReadBufferSize)
	EndIf
	$Return[0] = $Received_Content
	$Return[1] = $headers
	Return $Return
EndFunc   ;==>_https

Func _http_fast($Domain_Name, $URI = "", $content = "", $http_cookies = "", $Additional_Header = "")
	Local $HTTP_Header, $Received_Content, $Content_Length, $Received_Piece, $Previous_Size, $Content_Type = "application/x-www-form-urlencoded"
	$init = TimerInit()
	If StringInStr($Domain_Name, ":") Then
		$Domain_Name = StringSplit($Domain_Name, ":")
		$Port = $Domain_Name[2]
		$Domain_Name = $Domain_Name[1]
	Else
		$Port = 80
	EndIf
	$Domain_Name = TCPNameToIP($Domain_Name)
	Local $retr = ""

	If $content <> "" Then
		$sock = TCPConnect($Domain_Name, $Port)
		If @error Then Return 0

		$sHeader = "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" & @CRLF & _
				"Host: " & $Domain_Name & @CRLF & _
				"Content-Length: " & BinaryLen($content) & @CRLF & _
				$Additional_Header
		TCPSend($sock, "POST " & $URI & " HTTP/1.1" & @CRLF & _
				$sHeader & @CRLF & _
				$content)
	Else
		$sock = TCPConnect($Domain_Name, $Port)
		If @error Then Return 0

		$sHeader = "Host: " & $Domain_Name & @CRLF & _
				$Additional_Header
		TCPSend($sock, "GET " & $URI & " HTTP/1.1" & @CRLF & _
				$sHeader & @CRLF)
	EndIf
	Return 1
EndFunc   ;==>_http_fast

Func _http_header_disassemble($HTTP_Header)
	$HTTP_Header = StringSplit($HTTP_Header, @CRLF, 1)
	Dim $lines[$HTTP_Header[0] - 1][2]
	$lines[0][0] = $HTTP_Header[0] - 2
	For $i = 1 To $lines[0][0]
		$Delimiter = StringInStr($HTTP_Header[$i], " ")
		If $Delimiter Then
			$lines[$i][0] = StringLeft($HTTP_Header[$i], $Delimiter - 1)
			$lines[$i][1] = StringMid($HTTP_Header[$i], $Delimiter + 1)
		EndIf
	Next
	Return $lines
EndFunc   ;==>_http_header_disassemble

Func _http_header_getvalue(ByRef $HTTP_Header, $Variable_Name)
	For $i = 1 To $HTTP_Header[0][0]
		If $HTTP_Header[$i][0] = $Variable_Name Then Return $HTTP_Header[$i][1]
	Next
	Return -1
EndFunc   ;==>_http_header_getvalue

Func _BOM_Remove(ByRef $string)
	If StringLeft($string, 3) = BinaryToString(0xBFBBEF) Then $string = StringTrimLeft($string, 3)
	Return $string
EndFunc   ;==>_BOM_Remove

Func _httpSetReadBufferSize($size = 262144)
	$Wi_ReadBufferSize = $size
EndFunc   ;==>_httpSetReadBufferSize