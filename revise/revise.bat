@echo off

SET BASEPATH=%~dp0

julia --project=%BASEPATH% --load=%BASEPATH%\revise.jl
