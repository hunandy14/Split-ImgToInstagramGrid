@echo off
set "1=%~1"
powershell -NoExit -Command "&{ irm bit.ly/sIGgrid | iex; sIGgrid $env:1 }"
