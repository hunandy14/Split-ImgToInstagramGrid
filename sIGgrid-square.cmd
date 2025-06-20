@echo off & set "1=%~1"
powershell -nop "irm bit.ly/sIGgrid|iex; sIGgrid $env:1 -Layout square"
exit /b %errorlevel%
