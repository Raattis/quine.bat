@goto build
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>
#include <windows.h>

void _start()
{
	char* commandLine = GetCommandLine();
	printf("Hello, world! %s\n", commandLine);
	int main(int, char**);
	int ret = main(1, &commandLine);
	printf("Lobbu!\n");
	void exit(int);
	exit(ret);
}

const char* _source_string;
int main(int argc, char **argv)
{
	if (strstr(argv[0], "--source"))
	{
		printf("Here's my source (in stderr):\n\"\"\"\n");
		fprintf(stderr, "%s", _source_string);
		printf("\"\"\"\n");
	}
    return 0;
}

/*
:build
@echo off

set filename=%~n0%~x0
set c_filename=%~n0.c
set output_filename=%~n0.exe

if NOT EXIST %filename% (
	echo This file is missing?!
	exit 1
)

set compiler=static-tcc
if EXIST static-tcc.exe (
	echo Using static-tcc.exe as compiler
) else if EXIST tcc.exe (
	echo Using tcc.exe as compiler
	set compiler=tcc
) else (
	echo tcc.exe needs to be in the same folder as %filename%.
	exit 1
)

if EXIST ../../tcc.c (
	echo Rebuilding Tiny C Compiler. '../../tcc.c' was found so why not.
	if EXIST %compiler%.exe ( MOVE /Y %compiler%.exe %compiler%-old.exe 1> nul )
	rem ../../tcc.c -- The compiler file is outside of the 
	rem -DTCC_TARGET_PE -- Output using Windows' executable format
	rem -DTCC_TARGET_X86_64 -- Output x64 machine code
	rem -I../include & -I../include/winapi -- paths that #include <...> directives can refer to
	rem -L../lib -- Paths that linker uses to find .def and .a files to link against
	rem -nostdinc -- Prevent any default include paths being used for compiling.
	rem -nostdlib -- Prevent any default libraries being used for linking.
	rem -lmsvcrt -- Excplicitly state that we will use MSVC's C Runtime library
	rem -lkernel32 & -ltcc1-64 -- Libraries required for common functions
	.\%compiler%-old.exe -o static-tcc.exe ../../tcc.c -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -I../include -I../include/winapi -L../lib -nostdinc -lmsvcrt -lkernel32 -ltcc1-64

	if ERRORLEVEL 1 (
		echo/
		echo Building compiler failed. Error code: %ERRORLEVEL%
		exit 1
	)
)

echo/
echo Concatenating inject.c
> inject.c (
	rem Creating a C program to act as a script to copy some text.
	rem Batch is even worse at handling strings.
	rem About this code:
	rem '^' is a Batch script escape character. Where it is needed seems to be largely
	rem random. There is no logic here, only trial and error.
	echo #include ^<stdio.h^>
	echo #include ^<string.h^>
	echo void _start(^) {
	echo FILE *infile = fopen("%filename%", "r"^), *outfile = fopen("%c_filename%", "w"^);
	echo FILE *start = outfile;
	echo fseek(infile, strlen("@goto build"^)+1, SEEK_SET^);
	echo char buffer[1024], stop[] = ":build";
	echo while (fgets(buffer, sizeof(buffer^), infile^)^) {
	echo if (strncmp(buffer, stop, sizeof(stop^)-1^) == 0^) break;
	echo fputs(buffer, outfile^); }
	echo fseek(infile, 0, SEEK_SET^); fseek(outfile, -6, SEEK_CUR^);
	echo fputs("\nconst char* _source_string =\n\"", outfile);
	echo int c; while ((c = fgetc(infile^)^) != EOF^) {
	echo if (c == '\n'^) { fputs("\"\n\"\\n", outfile^); }
	echo if (c == '\n' ^|^| c == '\r'^) continue;
	echo if (c == '\\' ^|^| c == '"') fputc('\\', outfile);
	echo fputc(c, outfile^); }
	echo fputs("\";", outfile); fclose(infile); fclose(outfile); void exit(int); exit(0); }
)

if ERRORLEVEL 1 (
	echo/
	echo Concatenating inject.c failed. Error code: %ERRORLEVEL%
	exit 1
)

echo Building inject.exe from inject.c
.\%compiler%.exe inject.c -o inject.exe -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -nostdlib -lmsvcrt

if ERRORLEVEL 1 (
	echo/
	echo Building inject.exe failed. Error code: %ERRORLEVEL%
	exit 1
)

echo/
echo Running inject.exe to create %c_filename%
.\inject.exe

if ERRORLEVEL 1 (
	echo/
	echo inject.exe failed to run. Error code: %ERRORLEVEL%
	exit 1
)
del inject.c
del inject.exe

(
	echo Building %output_filename% from %c_filename%
	if EXIST %output_filename% DEL %output_filename%
	rem -DTCC_TARGET_PE -- Output using Windows' executable format
	rem -DTCC_TARGET_X86_64 -- Output x64 machine code
	rem -I. -- Makes both #include <...> and #include \"...\" directives only refer to the root folder
	rem -L. -- Only links against .def and .a files found in the root folder
	rem -nostdinc -- Prevent any default include paths being used for compiling.
	rem -nostdlib -- Prevent any default libraries being used for linking.
	rem -lmsvcrt -- Excplicitly state that we will use MSVC's C Runtime library
	.\%compiler%.exe %c_filename% -o %output_filename% -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -Iinclude -Iinclude/winapi -L. -nostdlib -nostdinc -lmsvcrt -lkernel32
	rem -I. -L.
	rem -nostdinc -nostdlib -lmsvcrt  
)

if ERRORLEVEL 1 (
	echo/
	echo Building %output_filename% from %c_filename% failed. Error code: %ERRORLEVEL%
	exit 1
)

rem Set to 1 to see preprocessor output
if EXIST .\%compiler%.exe (
	echo Generating preprocessor output to %~n0_preprocessed.c
	.\%compiler%.exe %c_filename% -E -o %~n0_preprocessed.c -nostdinc -Iinclude -Iinclude/winapi
	
	if ERRORLEVEL 1 (
		echo/
		echo Building %output_filename% from %c_filename% failed. Error code: %ERRORLEVEL%
		exit 1
	)
)

rem echo/ >> %output_filename%
rem echo/ >> %output_filename%
rem type %~n0_preprocessed.c >> %output_filename%

echo/
echo Running %output_filename%
echo -------------------------------------------------------------------------------
@echo on
.\%output_filename% --source 2> new_%~n0.bat
@echo off
echo -------------------------------------------------------------------------------

if ERRORLEVEL 1 (
	echo/
	echo %output_filename% returned %ERRORLEVEL%.
	exit 1
)
exit 0
*/
