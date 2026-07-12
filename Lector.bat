@echo off
start /b powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0reader_gui.ps1" -ConversationId auto
