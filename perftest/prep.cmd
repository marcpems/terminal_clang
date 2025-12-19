call "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\VsDevCmd.bat"
e:
cd e:\terminal\terminal_clang
git clean -fdx
call tools\razzle.cmd


REM msbuild openconsole.slnx /p:platform=x64;configuration=release /t:Conhost\Host_EXE /m 
REM msbuild openconsole.slnx /p:platform=x64;configuration=debug /t:Conhost\Host_EXE /m 
REM msbuild openconsole.slnx /p:platform=x64;configuration=release /p:WindowsTerminalClangBuild=true /t:Conhost\Host_EXE /m 
REM msbuild openconsole.slnx /p:platform=x64;configuration=debug /p:WindowsTerminalClangBuild=true /t:Conhost\Host_EXE /m 

REM msbuild openconsole.slnx /p:platform=arm64;configuration=release /t:Conhost\Host_EXE /m 
REM msbuild openconsole.slnx /p:platform=arm64;configuration=debug /t:Conhost\Host_EXE /m 
REM msbuild openconsole.slnx /p:platform=arm64;configuration=release /p:WindowsTerminalClangBuild=true /t:Conhost\Host_EXE /m 
msbuild openconsole.slnx /p:platform=arm64;configuration=debug /p:WindowsTerminalClangBuild=true /t:Conhost\Host_EXE /m 


REM msbuild openconsole.slnx /p:platform=x64;configuration=release /t:_Tools\ConsoleBench /m 