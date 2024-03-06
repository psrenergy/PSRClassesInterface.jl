@echo off

SET BASEPATH=%~dp0

julia --project=%BASEPATH% %BASEPATH%\format.jl