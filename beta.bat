@REM @echo off



:: callback config
setlocal enabledelayedexpansion       
set "args=%*"
for /F "tokens=1,* delims= " %%a in ("%args%") do (
    endlocal & ( set "function=%%a" & set "args=%%b")
)
if defined function call %function% %args% & exit /b



:: tool config
prompt $g$g$s
set "lines=20"
@REM mode con: cols=60 lines=%lines%

title FTP 
set "read="%~f0" :io r"
set "write="%~f0" :io w"
set "append="%~f0" :io ww"



:: FTP Configuration
set PHONE_IP=
set NETWORK_TYPE=
set LOGPATH=%userprofile%\desktop\
set "INI=%USERPROFILE%\Desktop\ftp_settings.ini"


setlocal EnableDelayedExpansion
:: Path to INI on Desktop 
:create
if not exist "%INI%" (
    echo creating config file on your desktop...
    (
      echo FTP_USER=
      echo FTP_PASS=
      echo FTP_PORT=
	  echo.
      echo ; mac address format xx-xx-xx-xx-xx-xx
      echo PHONE_MAC=
	  echo.
      echo ; set debug to 0 for off or 1 to get log file on your desktop folder
      echo debug=
    ) > %INI%
    echo config file created. Press any key to open it for editing.
    pause >nul
    start notepad.exe %INI%
    echo.
    echo Please edit and save the config file, then press any key to continue.
    pause >nul
)

for /f "usebackq delims=" %%A in ("%INI%") do (
	set "line=%%A"

	for /f "tokens=* delims= " %%B in ("!line!") do set "line=%%B"

		if defined line (
		set "firstChar=!line:~0,1!"

			if NOT "!firstChar!"==";" if NOT "!firstChar!"=="#" (

				echo "!line!" | findstr /c:"=" >nul
				if not errorlevel 1 (

				for /f "tokens=1* delims==" %%K in ("!line!") do (
					set "value=%%L"
					for /f "tokens=* delims=" %%Y in ("!value!") do set "value=%%Y"
					
					set "key=%%K"
					for /f "tokens=* delims= " %%X in ("!key!") do set "key=%%X"
					set "keys=!keys! !key!"
					set "!key!=!value!"
)	)	)	)	)

for %%a in (!keys:~1!) do (
  set "x=!x! & set "%%a=!%%a!""
  )

set "x=%x:~3%"
endlocal & %x%

call :debug initial parameters: FTP_USER=%FTP_USER% FTP_PASS=%FTP_PASS% FTP_PORT=%FTP_PORT% PHONE_MAC=%PHONE_MAC%

goto :method_2















::==================================================================================================================================================



:method_2
:: search ip in the local subnet by pinging all possible ips
set "PHONE_IP="
set method_2=1
set "found_ips=found"
set "ping_handler=call "%~f0" :ping_handler"

call :debug starting ip scan method

call :debug fetching gateways

call :get_gateways

call :debug detected gateways: %get_gateways%

set "count=0"
for %%a in (%get_gateways%) do (
	set /a count+=1
)

call :debug gateways to scan: %get_gateways%

echo  please wait...

for %%a in (%get_gateways%) do (
	for /f "tokens=1-2 delims=_" %%b in ("%%a") do (

		call :debug scanning network type %%b with gateway %%c

		echo scanning the %%b gateway for ftp servers

		call :debug attempting connection with ip %%c

		(
		call :connect %%c && goto :eof
		) || (
			call :debug no ftp servers could be found on %%c
		)
	)
)
setlocal enabledelayedexpansion
set /a i=0
for %%a in (%get_gateways%) do (
	set /a i+=1
	for /f "tokens=1-2 delims=_" %%b in ("%%a") do (

		call :debug scanning network type %%b with gateway %%c

		echo scanning the %%b network for ftp servers

		call :network_bits %%c

		call :debug network bits: !network_bits!
		
		call :set_timeout 1 %ping_handler% 4-5 %%c !network_bits!
			
		call :set_timeout 2 %ping_handler% 10-11 %%c !network_bits!
		
		call :check_async

		for /f "usebackq tokens=* delims=" %%d in ("%found_ips%") do (
			set "line=%%d"
			echo _!line!_a
			rem skip empty lines (after trimming leading spaces)
			if not "!line!"=="" (
				rem get first character to detect comment markers
				set "first=!line:~0,1!"
				if not "!first!"=="#" if not "!first!"==";" (
				echo _!line!_b
				)
			)
		)

		@REM call :connect && goto :eof

	)
)
endlocal
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
pause


:method_2a
set "method_2="
call :formatting 5
echo %*
call :selector try again,manual input,exit
if /i "%selector%"=="exit" goto :eof
if /i "%selector%"=="manual input" goto :method_3
if /i "%selector%"=="try again" goto :method_1
goto :menu



::==================================================================================================================================================



























:connect
set "connect=%*"
if defined connect set "PHONE_IP=%*" 
:: (search) && ((found) && (killed) || (unkilled)) || (unfound)
( 
call :check_ftp_simulator %PHONE_IP% %FTP_PORT% 
) && ( 
	::ftp server found
	explorer ftp://%FTP_USER%:%FTP_PASS%@%PHONE_IP%:%FTP_PORT% >nul
	call :debug ftp server found on %PHONE_IP%
	exit /b 0
	) || ( 
		::ftp server not found
		call :debug no ftp on %PHONE_IP%
		exit /b 1		 
		)



:ping_handler
:: use call :ping_handler [#start-stop] [gateway] [networkbits]
set "args=%*"
setlocal enabledelayedexpansion       
for /F "tokens=1,2,3 delims= " %%a in ("%args%") do (

	for /F "tokens=1,2 delims=-" %%d in ("%%a") do (
		endlocal & ( set "p_gateway=%%b" & set "p_network_bits=%%c" & set "start=%%d" & set "stop=%%e" )
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
		call %append% %found_ips% %network_bits%.%%a
		) || (
			:: if ping failed
			call :debug ping failed for %network_bits%.%%a
			:: last network, so if we reach here with d=254 then no ftp servers found
			if %%a equ %stop% (
				call :debug end of method 2, search failed
			)			
		)
	) else (
		call :debug skipping %p_gateway%
	)
)
exit /b



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
pause & exit




:check_ftp
:: Usage: check_ftp <IP_address> <PORT>
set IP=%1
set PORT=%2
(
:: Run PowerShell silently without showing the progress bar
powershell -Command "$ProgressPreference='SilentlyContinue'; if (Test-NetConnection -ComputerName %IP% -Port %PORT% -InformationLevel Quiet -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
) >nul
exit /b %errorlevel%


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
@rem Loop through the new quoted, space-separated list
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



:get_gateways
call :debug entering :get_gateways
set "get_gateways="
for /f "delims=" %%a in ('cscript //NoLogo "GetGateways.vbs"') do set "get_gateways=%%a" >nul
call :debug :get_gateways result: %get_gateways%
exit /b
	

:reset_choice
:: reset errorlevel for correct choice
:: use immediately before choice command
:: call :reset_choice
exit /b 0


:network_bits
:: Usage: network_bits <IP_address>
call :debug entering :network_bits with IP: %1
set "network_bits="
set "ip=%1"
:: parse into four tokens using "." as delimiter
for /f "tokens=1-4 delims=." %%a in ("%ip%") do (
	set network_bits=%%a.%%b.%%c
)
call :debug :network_bits result: %network_bits%
exit /b


:macAddress_lookup
:: Usage: macAddress_lookup <MAC_address>
set "macAddress="
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
	)
exit /b


:debug
@echo off
if "%debug%"=="0" goto :eo_debug
if not defined debug goto :eo_debug
set "log=%*"
set "tstamp="
setlocal enabledelayedexpansion
for /f "tokens=1-2 delims= " %%a in ('time /t') do (
	for /f "tokens=1-3 delims=:" %%b in ("%%a") do (
		endlocal & set "tstamp=[%%b:%%c]"
	)
) 
if not defined newLogFile set "newLogFile=1" & echo %tstamp% : script started > %LOGPATH%debug.log
echo %tstamp% : %log% >> %LOGPATH%debug.log
:eo_debug
echo on >nul
exit /b 0>nul





:set_timeout
:: usage call :set_timeout [time in sec.] [single line command with escaped chars. recommended to be a callback]
:: then call :check_async to wait for all to finish 
if defined check_async ( set /a "set_timeouty+=1" & goto :set_timeout_a ) 
@REM set foo="%~dp0foo"
set foo="foo"
set /a "set_timeouty=1"
set /a "set_timeoutx=0"
call %write% %foo% %set_timeoutx%

:set_timeout_a
set "args=%*"
if not defined args goto :eo_set_timeout
setlocal enabledelayedexpansion       
for /F "tokens=1,* delims= " %%a in ("%args%") do (
    endlocal & ( set "t=%%a" & set "command=%%b")
) 
call %read% %foo% %set_timeoutx% 
set "set_timeoutx=%io%"
call :debug before timeout %set_timeoutx% 
start /b cmd /v:on /c "timeout /t %t% /nobreak >nul && (%command% & (set /a "x=%io%+1") >nul & %write% %foo% ^!x^!)"
set "check_async=v"
pause
call :debug after timeout %set_timeoutx%
call %read% %foo%
set "set_timeoutx=%io%"
call :debug after timeout after fetch  %set_timeoutx% 
goto :eo_set_timeout

:check_async
call %read% %set_timeoutx% %foo%
set "set_timeoutx=%io%"
call :debug checking async tasks %set_timeoutx% of %set_timeouty%
pause
if not "%set_timeoutx%"=="%set_timeouty%" (
	timeout /t 1 /nobreak >nul 2>nul
	goto :check_async
) else (
	set "check_async="
	del %foo% >nul 2>nul
	goto :eo_set_timeout
)
:eo_set_timeout
exit /b



:io
@REM set "read="%~f0" io r"
@REM set "write="%~f0" io w"
@REM set "append="%~f0" io ww"
:: usage call :io [r|w|ww] [filename] [data]
:: stores data in var %io% when doing read operation
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
mkdir %LOCK_DIR%
if %ERRORLEVEL% equ 0 (
    if "!rw!"=="r" (
        set /p "io="<!file!
    ) else if "!rw!"=="w" (
            echo !data! >!file!
	) else if "!rw!"=="ww" (
		echo !data! >>!file!
	)
	call :debug io [!rw!] operation on file [!file!] with data [!data! !io!]
) else (
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


:ping_simulator
:: filters odd number hosts
set "args=%*"
set /a "ddd=args/2"
set /a "dds=args-(ddd*2)"
if %dds% equ 1 (
	echo yes
	exit /b 0
) else (
	echo no
	exit /b 1
)

:check_ftp_simulator
:: filters hosts divisible by 5
set "args=%*"
set /a "ddd=args/5"
set /a "dds=args-(ddd*5)"
if %dds% equ 1 (
	echo yes
	exit /b 0
) else (
	echo no
	exit /b 1
)

:formatting
:: formatting just because
:: Usage: formatting <number_of_blank_lines>
set "args=%*"
set /a spacing=%lines%-%args%
set /a spacing=%spacing%/2

for /L %%a in (1,1,%spacing%) do ( echo.)
exit /b 0


:error
exit /b 1


:eof
exit