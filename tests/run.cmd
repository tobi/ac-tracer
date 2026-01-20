@echo off
setlocal

set ROOT=%~dp0..
pushd "%ROOT%"

set LUAJIT=%LOCALAPPDATA%\Programs\LuaJIT\bin\luajit.exe
if exist "%LUAJIT%" (
  "%LUAJIT%" "tests/test_runner.lua"
) else (
  luajit "tests/test_runner.lua"
)

set EXITCODE=%ERRORLEVEL%
popd
exit /b %EXITCODE%
