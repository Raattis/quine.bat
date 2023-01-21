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

if NOT EXIST %filename% ( exit 1 )

echo Rebuilding Tiny C Compiler
if EXIST static-tcc.exe ( MOVE /Y static-tcc.exe static-tcc-old.exe 1> nul )
rem ../../tcc.c -- The compiler file is outside of the 
rem -DTCC_TARGET_PE -- Output using Windows' executable format
rem -DTCC_TARGET_X86_64 -- Output x64 machine code
rem -I../include & -I../include/winapi -- paths that #include <...> directives can refer to
rem -L../lib -- Paths that linker uses to find .def and .a files to link against
rem -nostdinc -- Prevent any default include paths being used for compiling.
rem -nostdlib -- Prevent any default libraries being used for linking.
rem -lmsvcrt -- Excplicitly state that we will use MSVC's C Runtime library
rem -lkernel32 & -ltcc1-64 -- Libraries required for common functions
.\static-tcc-old.exe -o static-tcc.exe ../../tcc.c -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -I../include -I../include/winapi -L../lib -nostdinc -lmsvcrt -lkernel32 -ltcc1-64

if ERRORLEVEL 1 (
	echo/
	echo Building compiler failed. Error code: %ERRORLEVEL%
	exit 1
)

echo/
echo Concatenating inject.c
> inject.c (
rem ^ is a Batch script escape character. Where it is needed seems to be largely
rem random. There is no logic to their placement, only trial and error.
echo #include ^<stdio.h^>
echo #include ^<string.h^>
echo void _start(^) {
echo FILE *infile = fopen("%filename%", "r"^), *outfile = fopen("%c_filename%", "w"^);
echo FILE *start = outfile;
echo fseek(infile, strlen("@goto build"^), SEEK_SET^);
echo fputs("const char* _source_string;\n", outfile^);
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

echo Building inject.exe from inject.c
.\static-tcc.exe inject.c -o inject.exe -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -I../include -I../include/winapi -L. -nostdlib -lmsvcrt

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

echo Building %output_filename% from %c_filename%
if EXIST %output_filename% ( DEL %output_filename% )
rem -DTCC_TARGET_PE -- Output using Windows' executable format
rem -DTCC_TARGET_X86_64 -- Output x64 machine code
rem -I. -- Makes both #include <...> and #include \"...\" directives only refer to the root folder
rem -L. -- Only links against .def and .a files found in the root folder
rem -nostdinc -- Prevent any default include paths being used for compiling.
rem -nostdlib -- Prevent any default libraries being used for linking.
rem -lmsvcrt -- Excplicitly state that we will use MSVC's C Runtime library
.\static-tcc.exe %c_filename% -o %output_filename% -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -I../include -I../include/winapi -L.
rem -nostdlib -nostdinc -I../include -I../include/winapi -l../msvcrt -l../kernel32
rem -I. -L.
rem -nostdinc -nostdlib -lmsvcrt  

if ERRORLEVEL 1 (
	echo/
	echo Building %output_filename% from %c_filename% failed. Error code: %ERRORLEVEL%
	exit 1
)

rem Uncomment to see preprocessor output
rem .\static-tcc.exe %c_filename% -E -o %~n0_preprocessed.c -I. -nostdinc

if ERRORLEVEL 1 (
	echo/
	echo Building %output_filename% from %c_filename% failed. Error code: %ERRORLEVEL%
	exit 1
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
