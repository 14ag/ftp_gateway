::test
@echo off



:: callback config
setlocal enabledelayedexpansion       
set "args=%*"
for /F "tokens=1,* delims= " %%a in ("%args%") do (
    endlocal & ( set "function=%%a" & set "args=%%b")
)

if defined function call %function% %args% & exit /b




:: tool config
title FTP 
prompt $g$g$s
set "lines=20"
:: test
REM mode con: cols=60 lines=%lines%
del foo >nul 2>&1
del found >nul 2>&1
set "newLogFile="
set "read="%~f0" :io r"
set "write="%~f0" :io w"
set "append="%~f0" :io ww"


:: init
set "ip_address="
:: test
REM set LOGPATH=%userprofile%\desktop\
set "LOGPATH=%userprofile%\sauce\batch_scripts\ftp_gateway\"
set "INI=%USERPROFILE%\Desktop\ftp_settings.ini"


setlocal EnableDelayedExpansion
:create
if not exist "%INI%" (
    echo creating config file on your desktop...
    (
      echo FTP_USER=
      echo FTP_PASS=
      echo FTP_PORT=
	  echo.
      echo ; mac address format xx-xx-xx-xx-xx-xx
      echo MAC_ADDRESS=
	  echo.
      echo ; set debug to 0 ^(default^) for off or 1 to get log file on your desktop folder
      echo debug=0
    ) > %INI%
    echo config file created. Press any key to open it for editing.
    pause >nul
    start notepad.exe %INI%
    echo.
    echo Please edit and save the config file, then press any key to continue.
    pause >nul
    goto :create
)

for /f "usebackq delims=" %%a in ("%INI%") do (
	set "line=%%a"

	for /f "tokens=* delims= " %%b in ("!line!") do set "line=%%b"

		if defined line (
		set "firstChar=!line:~0,1!"

			if NOT "!firstChar!"==";" if NOT "!firstChar!"=="#" (

				echo "!line!" | findstr /c:"=" >nul
				if not errorlevel 1 (

				for /f "tokens=1* delims==" %%c in ("!line!") do (
					set "value=%%d"
					for /f "tokens=* delims=" %%e in ("!value!") do set "value=%%e"
					
					set "key=%%c"
					for /f "tokens=* delims= " %%e in ("!key!") do set "key=%%e"
					set "keys=!keys! !key!"
					set "!key!=!value!"
)	)	)	)	)

for %%a in (!keys:~1!) do (
  set "x=!x! & set "%%a=!%%a!""
  )

set "x=%x:~3%"
endlocal & %x%

call :debug initial parameters: FTP_USER=%FTP_USER% FTP_PASS=%FTP_PASS% FTP_PORT=%FTP_PORT% mac_address=%mac_address%

::==================================================================================================================================================
::test
@REM goto :method_2







































:method_1
:: detecting phone ip from arp table using mac address
call :formatting 8 searching for ftp server ...this won't take long

if not defined mac_address echo setup mac_address for fast connection & goto method_2
set "macAddress_lookup="
if not defined macAddress_lookup (
	call :debug searching ARP table for MAC address %mac_address%

	call :macAddress_lookup %mac_address%
)
call :debug result of MAC address detection: %macAddress_lookup%

if not defined macAddress_lookup (
	goto :method_2
)

set "ip_address=%macAddress_lookup%"

call :debug attempting to connect with ip %ip_address%
(
call :connect %ip_address% && goto :eof
) || (
	echo  retrying...
	if defined method_1 goto :method_2
	netsh interface ip delete arpcache
	set "method_1=1"
	goto :method_1
)


































:method_2
:: search ip in the local subnet by pinging all possible ips
set "ip_address="
set "found_ips=found"
set "ping_handler=call "%~f0" :ping_handler"

call :debug starting ip scan

call :debug fetching gateways

call :get_gateway

call :debug detected gateways: %get_gateway%

echo  please wait...
for %%a in (%get_gateway%) do (
	echo scanning %%a for ftp servers

	call :debug attempting connection to gateway ip %%a

	(
		call :connect %%a && goto :eof
	) || (
		call :debug no ftp servers could be found on gateway %%a
	)
)


setlocal enabledelayedexpansion
for %%a in (%get_gateway%) do (
	echo scanning ips in gateway %%a for ftp servers
	call :debug scanning ips in gateway %%a

	call :network_bits %%a

	call :debug network bits: !network_bits!
	
	call :set_timeout 1 %ping_handler% %%a !network_bits! 1-10
	call :set_timeout 1 %ping_handler% %%a !network_bits! 11-20
	call :set_timeout 1 %ping_handler% %%a !network_bits! 21-30
	call :set_timeout 1 %ping_handler% %%a !network_bits! 31-40
	call :set_timeout 1 %ping_handler% %%a !network_bits! 41-50
	call :check_async
	::test
	cls
	for /f "usebackq tokens=* delims=" %%b in ("%found_ips%") do (
		for %%c in (%%b) do (
			call :connect %%c && goto :eof
		)	)

	del found >nul 2>&1
	call :set_timeout 1 %ping_handler% %%a !network_bits! 51-100
	call :set_timeout 1 %ping_handler% %%a !network_bits! 101-150
	call :set_timeout 1 %ping_handler% %%a !network_bits! 151-200
	call :set_timeout 1 %ping_handler% %%a !network_bits! 201-254
	call :check_async
	for /f "usebackq tokens=* delims=" %%b in ("%found_ips%") do (
		for %%c in (%%b) do (
			call :connect %%c && goto :eof
		)	)


)
endlocal

:method_2a
call :formatting 5 couldnt find ftp server on %get_gateway%

call :selector try auto mode again,manual input,exit

if /i "%selector%"=="exit" goto :eof
if /i "%selector%"=="enter phone ip" goto :method_3
if /i "%selector%"=="try auto mode again" goto :method_1
goto :menu




































:method_3
:: method 3 - quick input ip adress
set "ip_address="

setlocal enabledelayedexpansion
call :debug starting method 3 quick manual input

call :formatting 6 switching to manual input mode.

echo.
call :get_gateway

call :debug user selected !NETWORK_TYPE! gateway=!get_gateway!

call :network_bits !get_gateway!

set /p "host_bits=enter the last digits !network_bits!."
call :debug user entered host_bits: %host_bits%

set "ip_address=%network_bits%.%host_bits%"
call :debug ip_address: %ip_address%

(
	call :connect %ip_address% && goto :eof
	) || (
		echo no ftp servers could be found on %ip_address%
		pause
		goto :method_4
		)
endlocal




































:method_4
:: method 4 - direct input of full phone ip address, im so sorry this is what i tried to avoid pls forgive me
call :debug starting direct input
call :formatting 5 im so sorry this is what i tried to avoid
:input
echo.
set /p "user_ip_address=just enter the full ip address of the phone:"
call :network_bits %user_ip_address% 

set "UIP_network_bits=%network_bits%"
call :debug user input network bits %UIP_network_bits%

call :get_gateway

call :network_bits %get_gateway%

call :debug user device gateway %get_gateway%

if not "%UIP_network_bits%"=="%network_bits%" ( 
	call :formatting 4 it seems like your phone and pc are not on the same network
	goto :input
	)

::test
for /f "tokens=4 delims=." %%a in ("%user_ip_address%") do (
    set "host=%%a"
	)

call :debug pinging %user_ip_address%

(
call :ping_handler %user_ip_address% %UIP_network_bits% %host%-%host%
) && (
	echo. >nul
	(
        ::test
		REM call :connect %user_ip_address% && goto :eof
		call :connect %user_ip_address% && goto :eof

	) || (
		call :method_4a ftp server not found on %user_ip_address%
	)
) || (
	call :method_4a ping failed for %user_ip_address%
	)

:method_4a

call :formatting 5

echo %*
echo.
call :selector try again,quick input,auto mode,exit

if /i "%selector%"=="exit" goto :eof
if /i "%selector%"=="quick input" goto :method_3
if /i "%selector%"=="try again" goto :method_4
if /i "%selector%"=="auto mode" goto :method_2a
goto :menu
































:menu
call :formatting 7

echo  menu
call :selector method 1  fast search,method 2  slow search,method 3  quick input,method 4  manual input,exit

if /i "%selector%"=="exit" goto :eof
for /f "tokens=2 delims= " %%a in ("%selector%") do (

	echo.
	echo you selected %selector%
	echo method_%%a
	pause
	goto :method_%%a
	)

call :error

call :formatting 1

echo something went wrong
start notepad.exe %LOGPATH%
pause & goto :eof



::==================================================================================================================================================

:connect
:: define %FTP_PORT%
:: use connect [ip address]
set "ip_address=%*"
::test
for /f "tokens=4 delims=." %%a in ("%ip_address%") do (
    set "host=%%a"
	)
:: (search) && ((found) && (killed) || (unkilled)) || (unfound)
(
	::test
	REM call :check_ftp %ip_address% %FTP_PORT%
	
	call :check_ftp_simulator %host%

) && ( 
	::ftp server found
	::test
	msg %username% /server:%COMPUTERNAME% /w "connected to ftp://%FTP_USER%:%FTP_PASS%@%ip_address%:%FTP_PORT%"
	::test
	REM explorer ftp://%FTP_USER%:%FTP_PASS%@%ip_address%:%FTP_PORT% >nul
	call :debug ftp server found on _%ip_address%_

	exit /b 0
	) || ( 
		::ftp server not found
		call :debug no ftp on _%ip_address%_
		exit /b 1		 
		)

















:ping_handler
:: use call :ping_handler [#start-stop] [gateway] [networkbits]
set "args=%*"

setlocal enabledelayedexpansion       
for /F "tokens=1,2,3 delims= " %%a in ("%args%") do (

	for /F "tokens=1,2 delims=-" %%d in ("%%c") do (
		endlocal & ( set "p_gateway=%%a" & set "p_network_bits=%%b" & set "start=%%d" & set "stop=%%e" )
	) 
)

for /l %%a in (%start%,1,%stop%) do (
	if not "%p_network_bits%.%%a"=="%p_gateway%" (
					
		echo. >nul
		(
		::ping -n 1 -w 10 %network_bits%.%%a | find "TTL=" >nul
		call :ping_simulator %%a
		) && (
		:: if ping successful
		call :debug ping successful for %network_bits%.%%a

        if %start% equ %stop% exit /b 0
		call %append% %found_ips% %network_bits%.%%a

		) || (
			:: if ping failed
			call :debug no ping response from %network_bits%.%%a

            if %start% equ %stop% exit /b 1
			:: last network, so if we reach here with d=254 then no ftp servers found
			if %%a equ %stop% (
				call :debug end of range
			)			
		)
	)
)

exit /b


















:check_ftp
:: Usage: check_ftp <IP_address> <PORT>
:: returns errorlevel 0 if ftp server is reachable and 1 if not
set "IP=%1"
set "PORT=%2"
(
	:: Run PowerShell silently without showing the progress bar
	powershell -Command "$ProgressPreference='SilentlyContinue'; if (Test-NetConnection -ComputerName %IP% -Port %PORT% -InformationLevel Quiet -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
) >nul
exit /b %errorlevel%












:get_gateway
:: use call :get_gateway
:: returns an array of gateways of your pc in format [abc_123.123.123.123 xyz_456.456.456.456]

setlocal enabledelayedexpansion
set "get_gateway="
::test
REM for /f "delims=" %%a in ('cscript //NoLogo "GetGateways.vbs"') do set "get_gateway=%%a" >nul
set "get_gateway=wifi_192.168.600.1 lan_192.168.900.1"

set /a "count=0"
for %%a in (%get_gateway%) do (
	set /a "count+=1"
    )

if %count% gtr 1 (

	call :debug multiple gateways found, prompting user for selection
	set "x="
	for %%a in (%get_gateway%) do (
		for /f "tokens=1-2 delims=_" %%b in ("%%a") do (
			set "x=%%b %%c,!x!"
		)
	)

    :: removing trailing comma
    if defined x set "x=!x:~0,-1!"
    echo  select the network your ftp server is connected to:
    call :debug starting :selector !x!

    call :selector !x!
	)

for /F "tokens=2 delims= " %%a in ("!selector!") do (
    endlocal & set "get_gateway=%%a" 
	)

call :debug :get_gateway result: %get_gateway%
exit /b %errorlevel%

















:network_bits
:: Usage: network_bits <IP_address>
set "network_bits="
set "ip=%1"
:: parse into four tokens using "." as delimiter
for /f "tokens=1-4 delims=." %%a in ("%ip%") do (
	set "network_bits=%%a.%%b.%%c"
)
call :debug :network_bits result: %network_bits%

exit /b %errorlevel%















:macAddress_lookup
:: Usage: macAddress_lookup <MAC_address>
set "macAddress=%1"
(
arp -a | find /i "%macAddress%" >nul
) && (
	:: found
	for /f "tokens=1" %%a in ('arp -a ^| find /i "%macAddress%"') do (
		set "macAddress_lookup=%%a"
		)
	) || (
	:: phone not found in arp table
	set "macAddress_lookup="
	exit /b 1
	)
exit /b 0

















:selector
:: creates a dynamic list of choices from a command that outputs a list
:: & is just a command separator, while && is a conditional operator
:: call :selector arg1,arg2,arg3,...
setlocal enabledelayedexpansion
set "selector="
set "arg_string=%*"
set "i=0"
set "choicelist="
:: Replace every comma with a quote, a space, and another quote (" ") and Wrap the entire resulting string in quotes
set "arg_list="%arg_string:,=" "%""
rem Loop through the new quoted, space-separated list
for %%a in (%arg_list%) do (
	set /a i+=1

	:: Create dynamic variable names (_1, _2, etc.)
	for %%b in (_!i!) do (

		set "%%b=%%a"
		set "choicelist=!choicelist!!i!"
        set "display_value=%%a"
        set "display_value=!display_value:"=!"
		echo   [!i!].. !display_value!
	)   )

call :reset_choice

choice /c %choicelist% /n /m "pick option btn %choicelist:~0,1% and %choicelist:~-1,1% ::"
for /L %%a in (%choicelist:~-1%,-1,%choicelist:~0,1%) do (
    if errorlevel %%a (

		for %%b in (!_%%a!) do (
				endlocal & set "selector=%%b"
				goto :break
    )   )   )
:break
set "selector=%selector:"=%"
exit /b 0








:reset_choice
:: reset errorlevel for correct choice
:: use immediately before choice command
:: call :reset_choice
exit /b 0













:debug
::define "logpath" and "newLogFile=" before your code
::test
REM @exit /b 0 >nul 2>&1

if "%debug%"=="0" @exit /b 0 >nul 2>&1
if not defined debug @exit /b 0 >nul 2>&1
set "log=%*"
set "tstamp="

setlocal enabledelayedexpansion
for /f "tokens=1-2 delims= " %%a in ('time /t') do (

	for /f "tokens=1-3 delims=:" %%b in ("%%a") do (
		endlocal & set "tstamp=[%%b:%%c]"
		)
	) 
if not defined newLogFile (
	set "newLogFile=1"
	echo %tstamp% : script started > %LOGPATH%debug.log
	) else (
		echo %tstamp% : %log%>>%LOGPATH%debug.log 2>nul
	)
@exit /b 0 >nul 2>&1











:set_timeout
:: usage call :set_timeout [time in sec.] [single line command with escaped chars. recommended to be a callback]
:: then call :check_async to wait for all to finish
if not defined check_async ( 

	set "foo="%~dp0foo""
	set /a "set_timeout=1" 
	) else (
		set /a "set_timeout+=1"
	)

set "args=%*"

setlocal enabledelayedexpansion
set "task_id_%set_timeout%=%random%"
for /F "tokens=1,* delims= " %%a in ("%args%") do (
    set "t=%%a"
	set "command=%%b"
	) 

set "check_async=v"
start /b cmd /v:on /c "timeout /t !t! /nobreak >nul & (!command!) && (call %append% %foo% !task_id_%set_timeout%!)"

for %%a in (task_id_%set_timeout%) do (
	set "x=set "%%a=!%%a!""
	)

endlocal & %x% & set "check_async=v"
goto :eo_set_timeout

:check_async
setlocal enabledelayedexpansion
if not exist "foo" (
	call :debug waiting no task completed yet
	timeout /t 1 /nobreak >nul 2>&1
	goto :check_async
	)
for /f "usebackq delims=" %%a in (%foo%) do (

	set "line=%%a"
	(
	echo !progress_id! | find "!line!" >nul
	) || (
		set "progress_id=!line!!progress_id!"
		)
	)

for /l %%a in (1,1,%set_timeout%) do (
	for /f "tokens=2 delims==" %%b in ('set task_id_%%a') do ( set "task_id=%%b" )
	(
	echo !progress_id! | find "!task_id!" >nul
	) && (
		call :debug !task_id! found in !progress_id!
	) || (
		call :debug waiting for task !task_id!
		timeout /t 7 /nobreak >nul 2>&1
		goto :check_async
	)
	)

set "check_async="
::test
REM del %foo% >nul 2>&1
:eo_set_timeout
endlocal
exit /b 0















:io
:: define "read="%~f0" io r" "write="%~f0" io w" "append="%~f0" io ww" at the beginning of script
:: usage call :io [r|w|ww] [filename] [data]
:: [w] overwrites [ww] appends [r] reads data to/from [filename]
:: stores data in var %io% when doing [r] operation
call :debug entering :io with args [%*]
set "args=%*"
set "MAX_TRY=5"
setlocal enabledelayedexpansion
for /F "tokens=1,2,* delims= " %%a in ("%args%") do (
    set "rw=%%a" 
    set "file=%%b" 
    set "data=%%c"
	)

set "LOCK_DIR="!file:"=!Lock""
set /a TRY_COUNT=0

:TryLock
( 
mkdir %LOCK_DIR% 2>nul
) && (
    if "!rw!"=="r" (
        set /p "io="<!file! || call :debug ERROR reading [!file!]
    ) else if "!rw!"=="w" (
            echo !data!>!file! || call :debug ERROR writing [!data!] to [!file!]
	) else if "!rw!"=="ww" (
		echo !data!>>!file! || call :debug ERROR writing [!data!] to [!file!]
	)
	call :debug io [!rw!] operation on file [!file!] with data [!data!!io!]
) || (
    timeout /t 5 /nobreak >nul
    set /a TRY_COUNT+=1
    if !TRY_COUNT! lss %MAX_TRY% goto TryLock
    echo max wait.
)

rmdir "!LOCK_DIR!" 2>nul
for /F "tokens=* delims= " %%a in ("!io!") do (
    endlocal & set "io=%%a" 
	)
exit /b













:formatting
:: formatting just because
:: Usage: formatting <number_of_blank_lines>
::test
pause
cls
set "args=%*"
for /F "tokens=1,* delims= " %%a in ("%args%") do (
    set "n=%%a" 
    set "i=%%b" 
	)
set /a "spacing=(%lines%-%n%)/2"
for /L %%a in (1,1,%spacing%) do (
	if %%a equ %spacing% (
		echo %i%
	) else (
		echo.
	)
)
exit /b 0





:error
exit /b 1








:ping_simulator
::test
:: filters odd number hosts
set "args=%*"
set /a "ddd=args/2"
set /a "dds=args-(ddd*2)"
if %dds% equ 1 (
	exit /b 0
	) else (
		exit /b 1
	)



:check_ftp_simulator
::test
:: filters hosts divisible by %n%
set "args=%*"
set "n=33"
set /a "ddd=args/%n%"
set /a "dds=args-(ddd*%n%)"
if %dds% equ 0 (
	exit /b 0
	) else (
		exit /b 1
	)



:eof
exit /b 0