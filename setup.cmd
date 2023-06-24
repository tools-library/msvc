@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION



:PROCESS_CMD
    SET "utility_folder=%~dp0"

    REM Load dependent tools...
    CALL "%utility_folder%..\win-utils\setup.cmd" cecho vswhere

    SET help_val=false
    SET vs_version_val=
    SET arch_val=
    :LOOP
        SET current_arg=%1
        IF [%current_arg%] EQU [-h] (
            SET help_val=true
        )
        IF [%current_arg%] EQU [--help] (
            SET help_val=true
        )
        IF [%current_arg%] EQU [--vs-version] (
            SHIFT
            CALL SET "vs_version_val=%%1"
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
    REM Validate some arguments.
    IF [%vs_version_val%] EQU [] (
        CALL :SHOW_ERROR "Argument '--vs-version' must be provided."
        EXIT /B -3
    )

    IF [%arch_val%] EQU [] (
        CALL :SHOW_ERROR "Argument '--arch' must be provided."
        EXIT /B -3
    )

    CALL :SHOW_INFO "Initialize command prompt."

    FOR /f "usebackq tokens=*" %%i IN (`vswhere -nologo -version %vs_version_val% -property installationPath`) DO (
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
        CALL :SHOW_ERROR "Unable to find 'vcvarsall.bat' installed on your system based on the supplied arguments."
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
    cecho {olive}[TOOLSET - MSVC]{default} INFO: %~1{\n}
EXIT /B 0

:SHOW_ERROR
    cecho {olive}[TOOLSET - MSVC]{red} ERROR: %~1 {default} {\n}
EXIT /B 0



:SHOW_HELP
    SET "script_name=%~n0%~x0"
    ECHO #######################################################################
    ECHO #                                                                     #
    ECHO #                        T O O L   S E T U P                          #
    ECHO #                                                                     #
    ECHO #        'MSVC' is a script to setup the Microsoft Visual C++         #
    ECHO #         toolset.                                                    #
    ECHO #                                                                     #
    ECHO #         After running the %SCRIPT_NAME%, with the appropriate           #
    ECHO #         arguments, we can use the Microsoft C++ toolset from the    #
    ECHO #         command line. The Microsoft Visual C++ toolset must be      #
    ECHO #         installed beforehand.                                       #
    ECHO #                                                                     #
    ECHO # TOOL   : MSVC                                                       #
    ECHO # VERSION: 1.0.0                                                      #
    ECHO # ARCH   : x32                                                        #
    ECHO #                                                                     #
    ECHO # USAGE:                                                              #
    ECHO #   %SCRIPT_NAME% {-h^|--help ^| --vs-version "version" --arch arch }       #
    ECHO #                                                                     #
    ECHO # EXAMPLES:                                                           #
    ECHO #     %script_name% -h                                                    #
    ECHO #     %script_name% --vs-version "[15,]" --arch x64                       #
    ECHO #                                                                     #
    ECHO # ARGUMENTS:                                                          #
    ECHO #     -h^|--help    Print this help and exit.                          #
    ECHO #                                                                     #
    ECHO #     --vs-version    A version range for instances of VS to          #
    ECHO #         find. Example: '[16.6,)' will find a VS with version equal  #
    ECHO #         to or greater than '16.6'. OBS: Arg must be "quoted". More  #
    ECHO #         info about this version format can be found at the          #
    ECHO #         following url                                               #
    ECHO #         https://github.com/microsoft/vswhere/wiki/Examples.         #
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
