@echo off

rem filename=<name_of_this_file>.<ext_of_this_file>
set filename=%~n0%~x0
set c_filename=%~n0.c
set output_exe=%~n0.exe
set verbose=

if NOT EXIST %filename% (
	echo This file is missing?!
	exit 1
)

set compiler=static-tcc
if EXIST %compiler%.exe (
	rem nop
) else if EXIST static-tcc.exe (
	set compiler=static-tcc
) else if EXIST tcc.exe (
	set compiler=tcc
) else (
	echo tcc.exe needs to be in the same folder as %filename%.
	exit 1
)
if defined verbose echo Using %compiler%.exe as compiler

set step=Rebuilding Tiny C Compiler
set tcc_c=tcc.c
if EXIST %tcc_c% (
	if defined verbose echo %step%. '%tcc_c%' was found so why not.
	if EXIST %compiler%.exe ( COPY /Y %compiler%.exe %compiler%-old.exe 1> nul )
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
		COPY /Y %compiler%-old.exe %compiler%.exe 1> nul
		DEL %compiler%-old.exe
		goto error
	)
)

set step=Concatenating bootstrap_builder.c
(
	echo/
	if defined verbose echo %step%
	> bootstrap_builder.c (
		rem Creating a C program to act as a script to copy some text.
		rem Batch is even worse at handling strings.
		rem About this code:
		rem '^' is a Batch script escape character. Where it is needed seems to be largely
		rem random. There is no logic here, only trial and error.
		echo #include ^<stdio.h^>
		echo #include ^<string.h^>
		echo void _start(^) {
		echo FILE*in=fopen("%filename%","r"^),*out=fopen("%filename%_builder.c","w"^);
		echo char b[32], s[]="// builder_start", e[]="// builder_end";
		echo while (fgets(b, sizeof(b^), in^)^)
		echo if (strncmp(b, s, sizeof(s^)-1^) == 0^) break;
		echo while (fgets(b, sizeof(b^), in^)^) {
		echo if (strncmp(b, e, sizeof(e^)-1^) == 0^) break;
		echo fputs(b, out^); }
		echo fseek(in, 0, SEEK_SET^);
		echo fputs("\nconst char* _source_filename=\"%filename%\";", out^);
		echo fputs("\nconst char* _output_c=\"%c_filename%\";", out^);
		echo fputs("\nconst char* _output_exe=\"%output_exe%\";", out^);
		echo fputs("\nconst char* _compiler_bin=\".\\\\%compiler%.exe\";", out^);
		echo fclose(in^); fclose(out^); void exit(int^); exit(0^); }
	)

	if ERRORLEVEL 1 goto error
)

set step=Building bootstrap_builder.exe from bootstrap_builder.c
(
	if defined verbose echo %step%
	.\%compiler%.exe bootstrap_builder.c -o bootstrap_builder.exe -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -nostdlib -lmsvcrt

	if ERRORLEVEL 1 goto error
)

set step=Running bootstrap_builder.exe to create %filename%_builder.c
(
	if defined verbose echo %step%
	.\bootstrap_builder.exe
	if ERRORLEVEL 1 goto error
	del bootstrap_builder.c
	del bootstrap_builder.exe
)

set step=Building %filename%_builder.exe from %filename%_builder.c
(
	if defined verbose echo %step%
	.\%compiler%.exe %filename%_builder.c -o %filename%_builder.exe -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -nostdlib -lmsvcrt
	
	if ERRORLEVEL 1 goto error
)

set step=Running %filename%_builder.exe to create %c_filename%, compile it into %output_exe% and run it
(
	if defined verbose echo %step%.
	.\%filename%_builder.exe
	if ERRORLEVEL 1 goto error
	del %filename%_builder.c
	del %filename%_builder.exe
)

exit 0

:error
echo/
echo %step% failed. Error code: %ERRORLEVEL%
exit 1

// builder_start
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char buffer[1024 * 1024];
int insert_snippet(const char* start, const char* stop, FILE* infile, FILE* outfile, const char* input_filename)
{
	int line_number = 1;
	if (start) {
		int start_len = strlen(start);
		while (fgets(buffer, sizeof(buffer), infile)) {
			if (strncmp(buffer, start, start_len) == 0) break;
			++line_number;
		}
	}

	if (input_filename) {
		if (input_filename[0] == '"')
			fprintf(outfile, "#line %d %s\n", line_number, input_filename);
		else
			fprintf(outfile, "#line %d \"%s\"\n", line_number, input_filename);
	}

	if (stop) {
		int stop_len = stop ? strlen(stop) : 0;
		while (fgets(buffer, sizeof(buffer), infile)) {
			if (stop && strncmp(buffer, stop, stop_len) == 0) break;
			fputs(buffer, outfile);
		}
	}
	else
	{
		while (fgets(buffer, sizeof(buffer), infile))
			fputs(buffer, outfile);
	}
}

void insert_file_as_string(FILE* infile, FILE* outfile)
{
	fputc('"', outfile);
	int c;
	while ((c = fgetc(infile)) != EOF) {
		if (c == '\n') fputs("\"\n\"\\n", outfile);
		if (c == '\n' || c == '\r') continue;
		if (c == '\\' || c == '"') fputc('\\', outfile);
		fputc(c, outfile);
	}
	fputc('"', outfile);
}

int create_code_file(const char* start, const char* stop, const char* input_filename, const char* output_c)
{
	FILE *infile = fopen(input_filename, "r");
	FILE *outfile = fopen(output_c, "w");

	insert_snippet(start, stop, infile, outfile, input_filename);

	fseek(infile, 0, SEEK_SET);

	fputs("\nconst char* _source_string = \"\"\n", outfile);
	insert_file_as_string(infile, outfile);
	fputc(';', outfile);

	fclose(infile);
	fclose(outfile);
}

int compile(const char* output_c, const char* output_exe)
{
	extern const char* _compiler_bin;
	snprintf(buffer, sizeof(buffer), "%s %s -o %s -DTCC_TARGET_PE -DTCC_TARGET_X86_64 -Iinclude -Iinclude/winapi -nostdlib -nostdinc -lmsvcrt -lkernel32 -bench", _compiler_bin, output_c, output_exe);
	// -L. -vv 
	int result = system(buffer);
	if (result != 0)
		printf("Error while compiling '%s'. Error value: %d\n", output_c, result);
	return result;
}

void _start()
{
	extern const char* _output_c;
	extern const char* _output_exe;
	extern const char* _source_filename;
	create_code_file("// source_start", "// source_end", _source_filename, _output_c);

	int err = compile(_output_c, _output_exe);
	if (err != 0)
		exit(err);

	snprintf(buffer, sizeof(buffer), "%s --!compile --!source", _output_exe);
	printf("---------------------------------------\n");
	int result = system(buffer);
	printf("---------------------------------------\n");
	printf("%s returned %d\n", _output_exe, result);

	exit(0);
}
// builder_end

// source_start
#include <stdio.h>
#include <windows.h>

void _start()
{
	void exit(int);
	char* commandLine = GetCommandLine();
	printf("Hello, world!\n");

	if (strstr(commandLine, "--source"))
	{
		printf("Here's my source (in stderr):\n\"\"\"\n");
		extern const char* _source_string;
		fprintf(stderr, "%s", _source_string);
		printf("\"\"\"\n");
	}

	if (strstr(commandLine, "--compile"))
	{
		char bat_filename[1024];
		char* head = bat_filename;
		int len = 0;
		int err = sscanf(commandLine, "%s%n", bat_filename, &len);
		if (err != 1) exit(1);
		printf("bat_filename:'%s' %d\n", bat_filename, len);
		if (bat_filename[len-1] == '"')
			sprintf(bat_filename + len - 4, "bat\"");
		else
			sprintf(bat_filename + len - 3, "bat");

		printf("bat_filename:'%s' %d\n", bat_filename, len);
		int system(char*);
		system(bat_filename);
	}

	printf("The end!\n");
	exit(0);
}
// source_end
