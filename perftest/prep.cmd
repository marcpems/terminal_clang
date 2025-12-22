call "C:\Program Files\Microsoft Visual Studio\18\Professional\Common7\Tools\VsDevCmd.bat"
e:
cd e:\terminal\terminal_clang
git clean -fdx
call tools\razzle.cmd


REM msbuild openconsole.slnx /p:platform=x64;configuration=release /t:Conhost\Host_EXE /m 
REM echo X64 MSVC RELEASE

REM msbuild openconsole.slnx /p:platform=x64;configuration=debug /t:Conhost\Host_EXE /m 
REM echo X64 MSVC DEBUG

msbuild openconsole.slnx /p:platform=x64;configuration=release /p:WindowsTerminalClangBuild=true /t:Conhost\Host_EXE /m 
echo X64 LLVM RELEASE

REM msbuild openconsole.slnx /p:platform=x64;configuration=debug /p:WindowsTerminalClangBuild=true /t:Conhost\Host_EXE /m 
REM echo X64 LLVM DEBUG

REM msbuild openconsole.slnx /p:platform=arm64;configuration=release /t:Conhost\Host_EXE /m 
REM echo Arm64 MSVC Release

REM msbuild openconsole.slnx /p:platform=arm64;configuration=debug /t:Conhost\Host_EXE /m 
REM echo Arm64 MSVC Debug

REM msbuild openconsole.slnx /p:platform=arm64;configuration=release /p:WindowsTerminalClangBuild=true /t:Conhost\Host_EXE /m 
REM echo Arm64 LLVM Release

REM msbuild openconsole.slnx /p:platform=arm64;configuration=debug /p:WindowsTerminalClangBuild=true /t:Conhost\Host_EXE /m 
REM echo Arm64 LLVM Debug


REM msbuild openconsole.slnx /p:platform=x64;configuration=release /t:_Tools\ConsoleBench /m 