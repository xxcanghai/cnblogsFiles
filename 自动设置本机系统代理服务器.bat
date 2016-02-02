@echo off
title 自动更改IE代理服务器IP  By:小小沧海  2010.9.15
::color 80&mode con cols=60 lines=20

::请自行将set host=xxx更改为要ping的主机名称
set host=BJ-CLT-003
::请自行修改目标服务器端口号
set port=8888
for /f "tokens=2 delims=[]" %%i in ('ping %host% /n 1 -4 ^| findstr "Ping"') do echo 主机名称：%host%   IP地址：%%i:%port%&set ip=%%i
set ip>nul 2>nul
if %errorlevel%==1 echo 主机%host%没有找到,请检查主机名称是否正确!&goto end
::如果需要直接指定IP地址则可删除上述for命令行和if命令行，直接修改set ip=x.x.x.x即可


echo 正在写入注册值...
echo ==============================
REG ADD "HKCU\SOFTWARE\MICROSOFT\Windows\CURRENTVERSION\Internet Settings\Connections" /v "DefaultConnectionSettings" /t  REG_BINARY /d "3C000000AA0100000B0000000F000000" /f 
REG ADD "HKCU\SOFTWARE\MICROSOFT\Windows\CURRENTVERSION\Internet Settings" /v "ProxyEnable" /t  REG_DWORD /d "1" /f 
REG ADD "HKCU\SOFTWARE\MICROSOFT\Windows\CURRENTVERSION\Internet Settings" /v "ProxyServer" /t  REG_SZ /d "%ip%:%port%" /f 
REG ADD "HKLM\System\CurrentControlSet\Hardware Profiles\0001\SOFTWARE\MICROSOFT\Windows\CURRENTVERSION\Internet Settings" /v "ProxyEnable" /t  REG_DWORD /d "1" /f 
REG ADD "HKCU\SOFTWARE\MICROSOFT\Windows\CURRENTVERSION\Internet Settings\Connections" /v "SavedLegacySettings" /t  REG_BINARY /d "3C000000AE0100000B0000000F000000" /f 
REG ADD "HKCU\SOFTWARE\MICROSOFT\Windows\CURRENTVERSION\Internet Settings" /v "ProxyOverride" /t  REG_SZ /d "<local>" /f 
echo.
echo ==============================
echo 完成! 重启IE后生效
:end
ping 127.1 /n 3 >nul&exit