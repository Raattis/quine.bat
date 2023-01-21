@goto build
#include <stdio.h>
#include <windows.h>

void _start()
{
	char* commandLine = GetCommandLine();
	printf("%s\n", commandLine);
	printf("Hello, world!\n");
	int main(int, char**);
	int ret = main(1, &commandLine);
	printf("The end!\n");
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

rem <name_of_this_file>.<ext_of_this_file>
set filename=%~n0%~x0
set c_filename=%~n0.c
set output_exe=%~n0.exe

if NOT EXIST %filename% (
	echo This file is missing?!
	exit 1
)

set compiler=
if EXIST static-tcc.exe (
	echo Using static-tcc.exe as compiler
	set compiler=static-tcc
) else if EXIST tcc.exe (
	echo Using tcc.exe as compiler
	set compiler=tcc
) else (
	echo tcc.exe needs to be in the same folder as %filename%.
	exit 1
)

set tcc_c=tcc.c
if EXIST %tcc_c% (
	echo Rebuilding Tiny C Compiler. '%tcc_c%' was found so why not.
	if EXIST %compiler%.exe ( MOVE /Y %compiler%.exe %compiler%-old.exe 1> nul )
	rem tcc.c -- The compiler file
	rem -DTCC_TARGET_PE -- Output using Windows' executable format
	rem -DTCC_TARGET_X86_64 -- Output x64 machine code
	rem -Iinclude & -Iinclude/winapi -- paths that #include <...> directives can refer to
	rem -Llib -- Not necessary as we will manually specify each library
	rem -nostdinc -- Prevent any default include paths being used for compiling.
	rem -nostdlib -- Prevent any default libraries being used for linking.
	rem -lmsvcrt -- Excplicitly state that we will use MSVC's C Runtime library
	rem -lkernel32 & -ltcc1-64 -- Libraries required for common functions
	rem For this to work libtcc1-64 has to be compiled ahead of time... Maybe I'll get to it later.
	.\%compiler%-old.exe -o static-tcc.exe ../../tcc.c -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -Iinclude -Iinclude/winapi -nostdinc -lmsvcrt -lkernel32 -ltcc1-64

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

(
	echo Building inject.exe from inject.c
	.\%compiler%.exe inject.c -o inject.exe -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -nostdlib -lmsvcrt

	if ERRORLEVEL 1 (
		echo/
		echo Building inject.exe failed. Error code: %ERRORLEVEL%
		exit 1
	)
)

(
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
)

(
	echo Building %output_exe% from %c_filename%
	if EXIST %output_exe% DEL %output_exe%
	rem -DTCC_TARGET_PE -- Output using Windows' executable format
	rem -DTCC_TARGET_X86_64 -- Output x64 machine code
	rem -I. -- Makes both #include <...> and #include \"...\" directives only refer to the root folder
	rem -L. -- Only links against .def and .a files found in the root folder
	rem -nostdinc -- Prevent any default include paths being used for compiling.
	rem -nostdlib -- Prevent any default libraries being used for linking.
	rem -lmsvcrt -- Excplicitly state that we will use MSVC's C Runtime library
	.\%compiler%.exe %c_filename% -o %output_exe% -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -Iinclude -Iinclude/winapi -L. -nostdlib -nostdinc -lmsvcrt -lkernel32
	rem -I. -L.
	rem -nostdinc -nostdlib -lmsvcrt  
	
	if ERRORLEVEL 1 (
		echo/
		echo Building %output_exe% from %c_filename% failed. Error code: %ERRORLEVEL%
		exit 1
	)
)

rem Set to 1 to see preprocessor output
rem if NOT EXIST something_that_doesnt_exist (
if EXIST something_that_doesnt_exist (
	echo Generating preprocessor output to %~n0_preprocessed.c
	.\%compiler%.exe %c_filename% -E -o %~n0_preprocessed.c -nostdinc -Iinclude -Iinclude/winapi
	
	if ERRORLEVEL 1 (
		echo/
		echo Building %output_exe% from %c_filename% failed. Error code: %ERRORLEVEL%
		exit 1
	)
)

(
	echo/
	echo Running %output_exe%
	echo -----------------------------------------------------------
	.\%output_exe% --source 2> new_%~n0.bat
	echo -----------------------------------------------------------

	if ERRORLEVEL 1 (
		echo/
		echo %output_exe% returned %ERRORLEVEL%.
		exit 1
	)
	
	if EXIST new_%~n0.bat echo A new_%~n0.bat is born.
)

exit 0
*/
