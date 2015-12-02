::NetstatFilter网络连接查看器 @小小沧海 xxcanghai.cnblogs.com By:2015年6月29日
@echo off
:start
title NetstatFilter By:xxcanghai
SETLOCAL ENABLEEXTENSIONS&SETLOCAL ENABLEDELAYEDEXPANSION
cls

::######config######
set PCENAME=
set PID=
set PORT=

::inner config
set ERRORCODE=0

:menu
cls&echo ----------NetstatFilter----------
echo [1]查询指定进程名使用的端口号
echo [2]查看指定端口被哪个进程使用
echo [3]帮助信息
echo.
set /p=请输入对应数字:<nul
set select=3&set /p select=
if /i "%select%"=="q" exit /b
if /i "%select%"=="exit" exit /b
if "%select%"=="1" goto :menuitem1
if "%select%"=="2" goto :menuitem2
if "%select%"=="3" goto :help
cls&goto :menu

:menuitem1
set /p=请输入要查询的进程名称:<nul
set PCENAME=&set /p PCENAME=
if /i "%PCENAME%"=="q" goto :menu
if "%PCENAME%"=="" goto :menuitem1
if "%PCENAME:.=%"=="%PCENAME%" set PCENAME=%PCENAME%.exe
call :getpid "%PCENAME%" PID
echo Process:%PCENAME%,PID:%PID%
call :getnetbypid "%PID%"
echo @1END&pause>nul&goto start


:menuitem2
set /p=请输入要查询的端口号:<nul
set PORT=&set/p PORT=
if /i "%PORT%"=="q" goto :menu
if "%PORT%"=="" goto :menuitem2
call :getnetbyport "%PORT%"
echo @2END&pause>nul&goto start


:help
cls
echo ┏━━━━━━━━━━━━━━NetstatFilter ━━━━━━━━━━━━━━━━┓
echo ┃           netstat命令的辅助工具 @小小沧海 xxcanghai.cnblogs.com          ┃
echo ┃                                                                          ┃
echo ┃1.可查询某个进程在使用哪些端口，包含同名进程的多个实例及所有TCP和UDP端口  ┃
echo ┃2.可查询指定端口正在被哪些进程使用，以及本地/远程IP端口和当前连接状态     ┃
echo ┃                                =注意=                                    ┃
echo ┃※1.若无法使用或查询无反应请用管理员权限执行本批处理，方法参照上述博客文章┃
echo ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

echo 按任意键返回主菜单&pause>nul&goto start

::#####get pid by process#####
::[tasklist] example
::cmd.exe                      11132 Console                    1      3,000 K
::cmd.exe                       8204 Console                    1      2,728 K
::cmd.exe                      10060 Console                    1      2,996 K
:getpid
if not "%~1"=="" (
	set PID=
	for /f "tokens=2 delims= " %%i in ('tasklist /fi "imagename eq %~1" /nh /fo table^|find /i "%~1"') do (
		set PID=!PID!%%i,
	)
	if "!PID!"=="" (
		set ERRORCODE=101
		echo [ERROR]ProcessName "%~1" is not found
		pause>nul&goto start
	) else (
		set PID=!PID:~0,-1!
	)
	set %2=!PID!
	goto :eof
)


::#####get netstat by pid#####
::[netstat] example:
::  Proto  Local Address          Foreign Address        State           PID
::   TCP    0.0.0.0:80             0.0.0.0:0              LISTENING       4
::   UDP    [::1]:50575            *:*                                    5108
:getnetbypid
if not "%~1"=="" (
	set PID=%~1
	for /f "tokens=1,* delims=," %%a in ("!PID!") do (
		set subpid=%%a
		set PID=%%b
		::get TCP
		echo [PID-!subpid!]:
		for /f "delims=" %%z in ('netstat -a -n -o^|find ":"') do (
			set tLine=%%z
			::netstat的IPv6结果中含有%符号，%符号在call传递中会发生错误，遂将%替换为$后再传递
			set tLine=!tLine:%%=$!
			call :getNetInfo "!tLine!" tProto tLocalAdd tForeignAdd tState tPID
			set tLine=!tLine:$=%%!
			::call使用完成后将$符号替换回%符号
			if "!tPID!"=="!subpid!" (
				echo !tLine!
			)
		)
	)
	if not "!PID!"=="" (call %0 "!PID!")
	goto :eof
)


::#####get netstat by port#####
:getnetbyport
if not "%~1"=="" (
	set PORT=%~1
	for /f "tokens=1,* delims=," %%a in ("!PORT!") do (
		set myport=%%a
		set PORT=%%b
		::PORT==8888
		for /f "delims=" %%z in ('netstat -a -n -o^|find /i ":!myport! "') do (
			set tLine=%%z			
			set tLine=!tLine:%%=$!
			call :getNetInfo "!tLine!" tProto tLocalAdd tForeignAdd tState tPID
			set tLine=!tLine:$=%%!			
			echo !tLine!
			for /f "tokens=1 delims= " %%j in ('tasklist /nh /fi "PID eq !tPID!"') do (
				echo [%%j]
			)
		)
	)
)
goto :eof


echo END.&pause>nul&goto start
exit

::#####FUNCTION#####
:getNetInfo
::将netstat -ano的某一行分隔成不同的变量
::call :getNetInfo "<netstat output line>" tProto tLocalAdd tForeignAdd tState tPID
if not "%~1"=="" (
	for /f "tokens=1,2,3,4,5 delims= " %%i in ("%~1") do (
		set %2=%%i
		set %3=%%j
		set %4=%%k
		if "%%i"=="TCP" (
			set %5=%%l
			set %6=%%m
		) else (
			set %5=
			set %6=%%l
		)
	)
)
goto :eof

::#####FUNCTION#####
:split
::%0为函数名称自身:split，%1为传过来的值,%~1为删除变量中的双引号"
::在此子搜索函数中把过滤器按照/符号分割开，并取得分割后的第一个的值
::再把分割后的剩下的值重赋予过滤器，并调用自身，直到过滤器为空为止，返回
set subf=%~1
for /f "tokens=1,* delims=," %%j in ("%subf%") do (

	set subf=%%k
)
if not "!subf!"=="" (call %0 "!subf!")
goto :eof


::#####FUNCTION#####
:FUN1

goto :eof

