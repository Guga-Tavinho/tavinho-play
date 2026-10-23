@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Atualizar-Player.ps1"
if errorlevel 1 echo Nao foi possivel atualizar o catalogo. Confira a mensagem acima.
pause
endlocal
