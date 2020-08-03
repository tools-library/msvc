@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION



:PROCESS_CMD
    CALL "%utility_folder%..\win-utils\setup.cmd" cecho vswhere

    SET help_val=false
    SET version_val=
    SET arch_val=
    :LOOP
        SET current_arg=%1
        IF [%current_arg%] EQU [-h] (
            SET help_val=true
        )
        IF [%current_arg%] EQU [--help] (
            SET help_val=true
        )
        IF [%current_arg%] EQU [--version] (
            SHIFT
            CALL SET "version_val=%%1"
        )
        IF [%current_arg%] EQU [--arch] (
            SHIFT
            CALL SET "arch_val=%%1"
        )
        SHIFT
    IF NOT "%~1"=="" GOTO :LOOP

    IF [%help_val%] EQU [true] (
        CALL :SHOW_HELP
    ) ELSE (
        CALL :MAIN
        IF !ERRORLEVEL! NEQ 0 (
            EXIT /B !ERRORLEVEL!
        )
    )

    REM All changes to variables within this script, will have local scope. Only
    REM variables specified in the following block can propagates to the outside
    REM world (For example, a calling script of this script).
    ENDLOCAL & (
        SET "TOOLSET_MSVC_INITIALIZED=true"
        CALL %vcvarsall_cmd%
    )
EXIT /B 0



:MAIN
    REM This tool must be initialized only once.
    IF [%version_val%] EQU [] (
        CALL :SHOW_ERROR "Argument '--version' must be provided."
        EXIT /B -3
    )

    IF [%arch_val%] EQU [] (
        CALL :SHOW_ERROR "Argument '--arch' must be provided."
        EXIT /B -3
    )

    IF DEFINED TOOLSET_MSVC_INITIALIZED (
        EXIT /B 0
    )

    CALL :SHOW_INFO "Initialize command prompt."

    FOR /f "usebackq tokens=*" %%i IN (`vswhere -nologo -version %version_val% -property installationPath`) DO (
        SET vs_installation_path=%%i
    )

    SET base_cmd="%vs_installation_path%\VC\Auxiliary\Build\vcvarsall.bat"
    IF EXIST %base_cmd% (
        CALL :DECODE_ARCH %arch_val%, decoded_arch_val
        IF !ERRORLEVEL! NEQ 0 (
            EXIT /B !ERRORLEVEL!
        )
        SET vcvarsall_cmd=%base_cmd% !decoded_arch_val!
    ) ELSE (
        CALL :SHOW_ERROR "Unable to find 'vcvarsall.bat' installed on your system based on your arguments."
        EXIT /B -2
    )
EXIT /B 0



:DECODE_ARCH
    SET "arch_val=%1"
    IF [%arch_val%] EQU [x32] (
        SET "%~2=x86"
        EXIT /B 0
    )
    IF [%arch_val%] EQU [x64] (
        SET "%~2=amd64"
        EXIT /B 0
    )
    IF [%arch_val%] EQU [x32_x64] (
        SET "%~2=x86_amd64"
        EXIT /B 0
    )
    IF [%arch_val%] EQU [x64_x32] (
        SET "%~2=amd64_x86"
        EXIT /B 0
    )
    IF [%arch_val%] EQU [x32_arm32] (
        SET "%~2=x86_arm"
        EXIT /B 0
    )
    IF [%arch_val%] EQU [x32_arm64] (
        SET "%~2=x86_arm64"
        EXIT /B 0
    )
    IF [%arch_val%] EQU [x64_arm32] (
        SET "%~2=amd64_arm"
        EXIT /B 0
    )
    IF [%arch_val%] EQU [x64_arm64] (
        SET "%~2=amd64_arm64"
        EXIT /B 0
    )

    CALL :SHOW_ERROR "Unable to decode an invalid 'architecture'. Provided 'arch' was '%arch_val%'."
EXIT /B -1



:SHOW_INFO
    cecho {olive}[TOOLSET - UTILS - MSVC]{default} INFO: %~1{\n}
EXIT /B 0

:SHOW_ERROR
    cecho {olive}[TOOLSET - UTILS - MSVC]{red} ERROR: %~1 {default} {\n}
EXIT /B 0

:SHOW_HELP
    SET "script_name=%~n0%~x0"
    ECHO #######################################################################
    ECHO #                                                                     #
    ECHO #                      T O O L   S E T U P                            #
    ECHO #                                                                     #
    ECHO #                 'MSVC' a script to setup the                        #
    ECHO #                Microsoft Visual C++ toolchain.                      #
    ECHO #                                                                     #
    ECHO # TOOL   : MSVC                                                       #
    ECHO # VERSION: 2.8.4                                                      #
    ECHO # ARCH   : x32                                                        #
    ECHO #                                                                     #
    ECHO # USAGE:                                                              #
    ECHO #   %SCRIPT_NAME% {-h^|--help ^| --version "version" --arch arch }          #
    ECHO #                                                                     #
    ECHO # EXAMPLES:                                                           #
    ECHO #     %script_name% -h                                                    #
    ECHO #     %script_name% --version "[15,]" --arch x64                          #
    ECHO #                                                                     #
    ECHO # ARGUMENTS:                                                          #
    ECHO #     -h^|--help    Print this help and exit.                          #
    ECHO #                                                                     #
    ECHO #     --version    A version range for instances to find. Example:    #
    ECHO #         [15.0,16.0) will find versions 15.*. OBS: Arg must be       # 
    ECHO #         "quoted". More info about this version format can be found  #
    ECHO #         in the following url                                        #
    ECHO #         https://github.com/microsoft/vswhere/wiki/Examples          #
    ECHO #                                                                     #
    ECHO #     --arch    Must be one of the following values: x32, x64,        #
    ECHO #         x32_x64, x64_x32, x32_arm32, x32_arm64, x64_arm32,          #
    ECHO #         x64_arm64.                                                  #
    ECHO #                                                                     #
    ECHO # EXPORTED ENVIRONMENT VARIABLES:                                     #
    ECHO #     TOOLSET_MSVC_INITIALIZED    A boolean indicating whether this   #
    ECHO #         tool has already been initialized.                          #
    ECHO #                                                                     # 
    ECHO #     Any variables that are changed or added by 'msvc' configuration #
    ECHO #     script (vcvarsall.bat^) will be exported.                        #
    ECHO #                                                                     #
    ECHO #     The environment variables will be exported only if this script  #
    ECHO #     executes without any error.                                     #
    ECHO #                                                                     #
    ECHO #######################################################################
EXIT /B 0