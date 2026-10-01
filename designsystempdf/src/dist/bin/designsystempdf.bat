@echo off
rem This file is part of DesignSystemPDF, in the govuk-dita-plugin project.
rem Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
rem
rem Launcher: runs the generator in its own Java process with only its own lib\
rem on the class path. Java 17 or later is the one requirement - taken from
rem JAVA_HOME when set, otherwise from the PATH.
setlocal
set "DESIGNSYSTEMPDF_HOME=%~dp0.."
set "DESIGNSYSTEMPDF_JAVA=java"
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" set "DESIGNSYSTEMPDF_JAVA=%JAVA_HOME%\bin\java.exe"
"%DESIGNSYSTEMPDF_JAVA%" %DESIGNSYSTEMPDF_OPTS% -Djava.awt.headless=true "-Ddesignsystempdf.home=%DESIGNSYSTEMPDF_HOME%" -cp "%DESIGNSYSTEMPDF_HOME%\lib\*" org.istanduk.designsystempdf.Main %*
exit /b %ERRORLEVEL%
