@echo off
setlocal enabledelayedexpansion
title 修改本机IP地址  by:小小沧海20130409
:init
cls&echo ——————————————自动修改本机IP地址——————————————
rem 系统版本，值可为Windows7或是WindowsXP，或是auto（表示自动获取）
set SYSVER=auto
rem 要更改的网卡名称，auto表示自动获取第一块“以太网适配器”
set ETH=auto
rem IP来源，值仅为两个static和dhcp，ques表示询问，由使用者填写
rem 静态IP请填写static，从网关自动获取IP请填写dhcp
set IPSOURCE=ques
rem 要改成的IP地址，ques同上
set IPADDR=ques
rem 要改成的子网掩码，ques同上
set MASK=ques
rem 要使用的默认网关，ques同上
set GATEWAY=ques
rem DNS模式，值仅为两个static和dhcp
rem 静态DNS请填写static，从网关自动获取DNS请填写dhcp
set DNSSOURCE=ques
rem 要使用的首选DNS，ques同上
set DNS1=ques
rem 要使用的备用DNS，ques同上
set DNS2=ques
set LOG=%TEMP%\changeIP_log.txt
echo 运行日期:%date% %time%>%LOG%


:start
rem ===============使用者填写参数值=======================
rem 自动获取系统版本，结果为 Windows7 或是 WindowsXP(只测试了这两个系统)
if "%SYSVER%"=="auto" (
    set /p=正在自动获取系统版本...<nul
    for /f "skip=1 tokens=2-3 delims= " %%i in ('wmic os get caption') do set SYSVER=%%i%%j
    if /i "!SYSVER!"=="Windows7" (
        echo 成功！[Win7]
    ) else (
        if /i "!SYSVER!"=="WindowsXP" (
            echo 成功！[WinXP]
        ) else (
            echo [!SYSVER!]
            echo 【注意】非Win7和XP系统不保证能执行成功！&pause>nul
        )
    )
)

rem 自动获取网卡名称
if "%ETH%"=="auto" (
    echo 正在自动获取网络适配器信息...
    set index=0
    set select=1
    for /f "skip=3 tokens=4* delims= " %%i in ('netsh interface ipv4 show interfaces^|find /i /v "Loopback"') do (
        set /a index=!index!+1
        set ethname=%%j
        echo [!index!]!ethname!
    )
    if !index!==1 (
        set ETH=!ethname!
    ) else ( if !index! GTR 1 (
        :select
        set /p=请选择要设置的网卡编号:<nul
        set select=0&set /p select=
        if /i !select! LSS 1 goto select
        if /i !select! GTR !index! goto select
        set index=0
        for /f "skip=3 tokens=4* delims= " %%i in ('netsh interface ipv4 show interfaces^|find /i /v "Loopback"') do (
            set /a index=!index!+1
            if !index!==!select! (
                set ETH=%%j
            )
        )
    ))

    if "!ETH!"=="auto" (
        echo 自动获取网卡名称失败，请右键编辑本批处理，手动填写网卡名称！&pause>nul&exit
    ) else (
        rem set/p=[!ETH!]<nul
        echo 成功！
    )
)

:quesIP
if "%IPSOURCE%"=="ques" (
    echo →请填写【IP地址来源】^(值仅为两个static和dhcp，直接回车为static^)
    set /p IPSOURCE=
    if "!IPSOURCE!"=="ques" set IPSOURCE=static
    if /i "!IPSOURCE!" NEQ "static" (if /i "!IPSOURCE!" NEQ "dhcp" (
        set IPSOURCE=static
        echo IP来源填写错误，将变更为static模式
        pause>nul
    ))
)
if /i "%IPSOURCE%"=="dhcp" goto quesDNS

if "%IPADDR%"=="ques" (
    echo →请填写【IP地址】^(直接回车为192.168.1.100^)
    set /p IPADDR=
    if "!IPADDR!"=="ques" set IPADDR=192.168.1.100
)

if "%MASK%"=="ques" (
    echo →请填写【子网掩码】^(直接回车为255.255.255.0^)
    set /p MASK=
    if "!MASK!"=="ques" set MASK=255.255.255.0
)

if "%GATEWAY%"=="ques" (
    echo →请填写【默认网关】^(直接回车为192.168.1.1^)
    set /p GATEWAY=
    if "!GATEWAY!"=="ques" set GATEWAY=192.168.1.1
)

:quesDNS
if "%DNSSOURCE%"=="ques" (
    echo →请填写【DNS来源】^(值仅为两个static和dhcp，直接回车为static^)
    set /p DNSSOURCE=
    if "!DNSSOURCE!"=="ques" set DNSSOURCE=static
    if /i "!DNSSOURCE!" NEQ "static" (if /i "!DNSSOURCE!" NEQ "dhcp" (
        set DNSSOURCE=static
        echo DNS来源填写错误，将变更为static模式
        pause>nul
    ))
)
if /i "%DNSSOURCE%"=="dhcp" goto checkInfo

if "%DNS1%"=="ques" (
    echo →请填写【首选DNS地址】^(直接回车为8.8.8.8^)
    set /p DNS1=
    if "!DNS1!"=="ques" set DNS1=8.8.8.8
)

if "%DNS2%"=="ques" (
    echo →请填写【备用DNS地址】^(直接回车为8.8.4.4^)
    set /p DNS2=
    if "!DNS2!"=="ques" set DNS2=8.8.4.4
)


:checkInfo
cls
echo 即将应用以下配置：
call :showInfo
echo 请确认信息是否正确，输入Y继续，输入N退出，输入Q显示本机网络信息
set choose=nul&set /p choose=
if /i "%choose%"=="nul" goto checkInfo
if /i "%choose%"=="N" exit
if /i "%choose%"=="Q" call :getInfo & pause & goto checkInfo
if /i "%choose%" NEQ "Y" goto checkInfo
echo ★注意★请关闭防火墙或允许所有弹出的安全软件提示，否则无法成功执行！

:changeIP
rem 通过dhcp删除原有IP配置
echo →设置"%ETH%"的IP源为DHCP，以删除原有IP地址 >>%LOG%
netsh -c interface ip set address name="%ETH%" source=dhcp >>%LOG%
if /i "%IPSOURCE%"=="static" (
    echo →设置IP为"%IPADDR%"，掩码为"%MASK%"，网关为"%GATEWAY%" >>%LOG%
    netsh -c interface ip set address name="%ETH%" source=static address="%IPADDR%" mask="%MASK%" gateway="%GATEWAY%" gwmetric=1 >>%LOG%
)
rem 删除原有DNS配置
echo →删除原有DNS配置 >>%LOG%
netsh -c interface ip delete dns "%ETH%" all >>%LOG%
if /i "%DNSSOURCE%"=="static" (
    echo →设置首选DNS为%DNS1% >>%LOG%
    netsh -c interface ip add dns name="%ETH%" addr="%DNS1%" index=1 >>%LOG%
    echo →设置备用DNS为%DNS2% >>%LOG%
    netsh -c interface ip add dns name="%ETH%" addr="%DNS2%" index=2 >>%LOG%
    rem ↑此处可继续增加多个DNS服务器地址
) else (if /i "%DNSSOURCE%"=="dhcp" (
    echo →设置DNS为DHCP模式 >>%LOG%
    netsh -c interface ip set dns name="%ETH%" dhcp >>%LOG%
))

:end
cls
rem echo 【要设定的信息】
rem call :showInfo
echo 【当前本机信息】
call :getInfo
echo ======================================
echo 如果上下一致则说明修改成功！
echo 如果不一致则请查看日志文件！
echo 输入L查看日志文件，输入E退出程序。
set choose=nul&set /p choose=
if /i "%choose%"=="L" start %LOG%&goto end
if /i "%choose%"=="E" exit
if /i "%choose%"=="nul" goto end


echo 程序执行结束，按任意键退出...
pause>nul
exit


:showInfo
echo 【本机系统】：%SYSVER%
echo 【网卡名称】：%ETH%
echo 【IP来源  】：%IPSOURCE%
if "%IPSOURCE%"=="static" (
    echo 【IP地址  】：%IPADDR%
    echo 【子网掩码】：%MASK%
    echo 【默认网关】：%GATEWAY%
)
echo 【DNS来源 】：%DNSSOURCE%
if "%DNSSOURCE%"=="static" (
    echo 【首选DNS 】：%DNS1%
    echo 【备用DNS 】：%DNS2%
)
rem goto :eof等于返回return
goto :eof


:getInfo
netsh -c interface ip show address name="%ETH%"
netsh -c interface ip show dns name="%ETH%"
goto :eof

:windows7

==============================================
接口 "本地连接" 的配置
    DHCP 已启用:                       否
    IP 地址:                           192.168.1.253
    子网前缀:                          192.168.1.0/24 (掩码 255.255.255.0)
    默认网关:                          192.168.1.1
    网关跃点数:                        1
    InterfaceMetric:                   20
    
    
接口 "本地连接" 的配置
   静态配置的 DNS 服务器:            8.8.8.8
                                     8.8.4.4
   用哪个前缀注册:                   只是主要