@echo off

rem filename=<name_of_this_file>.<ext_of_this_file>
set filename=%~n0%~x0
set c_filename=%~n0.c
set output_exe=%~n0.exe
set builder_exe=%~n0_builder.exe
set create_builder_exe=
set create_source_file=
set create_exe_file=1
set run_exe=
set verbose=1

if NOT EXIST %filename% (
	echo This file is missing?!
	exit 1
)

set compiler=tcc
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

set step=Creating a bootstrap builder

echo/
if defined verbose echo %step%

if defined verobse set c_start=fprintf(stderr,"Running bootstrap builder.\n"^);

set c_options=fputs("\nconst char* _source_filename=\"%filename%\";",out^);fputs("\nconst char* _output_c=\"%c_filename%\";",out^);fputs("\nconst char* _output_exe=\"%output_exe%\";",out^);fputs("\nconst char* _compiler_bin=\".\\\\%compiler%.exe\";",out^);

if defined verbose set c_options=%c_options%fputs("\nint _verbose=1;",out^);
if not defined verbose set c_options=%c_options%fputs("\nint _verbose=0;",out^);

if defined create_source_file set c_options=%c_options%fputs("\nint _create_source_file=1;",out^);
if not defined create_source_file set c_options=%c_options%fputs("\nint _create_source_file=0;",out^);

if defined create_exe_file set c_options=%c_options%fputs("\nint _create_exe_file=1;",out^);
if not defined create_exe_file set c_options=%c_options%fputs("\nint _create_exe_file=0;",out^);

if defined run_exe set c_options=%c_options%fputs("\nint _run_exe=1;",out^);
if not defined run_exe set c_options=%c_options%fputs("\nint _run_exe=0;",out^);

set build_or_run=-run
if defined create_builder_exe set build_or_run=-o %builder_exe%

rem Running a C script to output text from between builder_start and builder_end markers later in this file into stdout, which is piped to another run of TCC. That run either builds a builder.exe or runs immediately depeding if create_builder_exe is defined. Regardless which mode is used, the builder takes the code between source_start and source_end markers and outputs it into a .c file and then compiles it.
rem About this code:
rem '^' is a Batch script escape character. Where it is needed seems to be largely
rem random. There is no logic here, only trial and error.

echo #include ^^^<stdio.h^^^> #include ^^^<string.h^^^> char b[1024*1024]; void _runmain(^){%c_start%FILE*in=fopen("%filename%","r"^),*out=stdout;char s[]="// builder_start",e[]="// builder_end";int l=1;while(fgets(b,sizeof(b),in^)^){++l;if(strncmp(b, s, sizeof(s^)-1^) == 0^)break;}fprintf(out,"#line %%d \"%filename%\"\n",l^);while(fgets(b,32,in^)^){if(strncmp(b,e,sizeof(e^)-1^)==0^)break;fputs(b,out^);}{%c_options%}fclose(in^);fclose(out^);void exit(int^);exit(0^);} | .\%compiler%.exe -run -nostdlib -lmsvcrt - | .\%compiler%.exe -lmsvcrt -g -bt 8 - %build_or_run%

if ERRORLEVEL 1 goto error

set step=Running %output_exe% builder.
if defined create_builder_exe .\%builder_exe%

if ERRORLEVEL 1 goto error

if defined verbose echo %filename% finished successfully!
exit 0

:error
echo/
echo %step% failed. Error code: %ERRORLEVEL%
exit 1

// builder_start
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>

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

int create_code_file(const char* start, const char* stop, const char* input_filename, const char* output_c, FILE* compiler_pipe)
{
	FILE *infile = fopen(input_filename, "r");
	FILE *outfile = compiler_pipe ? compiler_pipe : fopen(output_c, "w");

	insert_snippet(start, stop, infile, outfile, input_filename);

	fseek(infile, 0, SEEK_SET);

	//extern int _create_exe_file;;
	//if (!_create_exe_file)
	//	fputs("_runmain() { _start(); }\n", outfile);

	fputs("\nconst char* _source_string = \"\"\n", outfile);
	insert_file_as_string(infile, outfile);
	fputc(';', outfile);

	fclose(infile);
	fclose(outfile);
}

int compile(const char* output_c, const char* output_exe)
{
	extern int _create_exe_file;
	extern const char* _compiler_bin;
	snprintf(buffer, sizeof(buffer), "%s %s -o %s -Iinclude -Iinclude/winapi -nostdlib -nostdinc -lmsvcrt -lkernel32 %s", _compiler_bin, output_c, output_exe, _create_exe_file ? "" : "-run");
	// -L. -vv -bench
	int result = system(buffer);
	if (result != 0)
		fprintf(stderr, "Error while compiling '%s'. Error value: %d\n", output_c, result);
	return result;
}

FILE* create_compilation_process(const char* output_exe)
{
	extern int _create_exe_file;
	extern const char* _compiler_bin;
	snprintf(buffer, sizeof(buffer), "%s - -o %s -Iinclude -Iinclude/winapi -nostdlib -nostdinc -lmsvcrt -lkernel32 %s", _compiler_bin, output_exe, _create_exe_file ? "" : "-run");
	// -L. -vv -bench
	FILE* compiler_pipe = popen(buffer, "w");
	if (compiler_pipe)
		return compiler_pipe;
	
	fprintf(stderr, "Couldn't create a compiler process with '%s'.\n", buffer);
	exit(1);
	return 0;
}

void crash_handler(int sig)
{
	printf("!!!! crash_handler: %d", sig);
	exit(sig > 0 ? sig : 1);
}

void _start()
{	
	extern int _verbose;
	extern int _create_source_file;
	extern const char* _output_c;
	extern const char* _output_exe;
	extern const char* _source_filename;

	signal(SIGSEGV, crash_handler);

	if (_verbose)
		printf("Running %s builder.\n", _output_exe);

	FILE* compiler_pipe = _create_source_file ? 0 : create_compilation_process(_output_exe);

	const char* input_filename = _source_filename && sizeof(_source_filename) > 1 ? _source_filename : 0;
	const char* output_c = _output_c && sizeof(_output_c) > 1 ? _output_c : 0;
	create_code_file("// source_start", "// source_end", input_filename, output_c, compiler_pipe);

	int err = compiler_pipe ? 0 : compile(output_c, _output_exe);
	if (err != 0)
		exit(err);
	
	if (compiler_pipe)
	{
		err = pclose(compiler_pipe);
		if (err != 0)
		{
			fprintf(stderr, "Failed to close compiler pipe. Error code: %d\n", err);
			exit(1);
		}
	}

	extern int _run_exe;
	if (_run_exe)
	{
		snprintf(buffer, sizeof(buffer), "%s --!compile --!source", _output_exe);
		printf("---------------------------------------\n");
		int result = system(buffer);
		printf("---------------------------------------\n");
		printf("%s returned %d\n", _output_exe, result);
	}
	else if (_verbose)
	{
		printf("%s builder successfully ended.\n", _output_exe);
	}

	exit(0);
}
void _runmain() { _start(); }
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

	if (strstr(commandLine, "--builder"))
	{
		char bat_filename[1024];
		char* head = bat_filename;
		int len = 0;
		int err = sscanf(commandLine, "%s%n", bat_filename, &len);
		if (err != 1) exit(1);
		printf("exe_filename:'%s' %d\n", bat_filename, len);
		if (bat_filename[len-1] == '"')
		{
			sprintf(bat_filename + len - 5, "_new.bat");
			bat_filename[0] = ' ';
			memcpy(bat_filename, bat_filename + 1, sizeof(bat_filename) - 1);
		}
		else
			sprintf(bat_filename + len - 4, "_new.bat");

		printf("bat_filename:'%s' %d\n", bat_filename, len);
		
		FILE* out = fopen(bat_filename, "w");
		if (!out)
		{
			fprintf(stderr, "Failed to write into '%s'", bat_filename);
			exit(1);
		}
		
		// FIXME: Doesn't work? No errors, just doesn't produce a file.
		// Probably a problem with "-characters in the filename.
		// Should discard "-symbols and only use the filename.
		extern const char* _source_string;
		fputs(_source_string, out);
		//fputs("hi!", out);
		err = fclose(out);
		if (err != 0)
		{
			fprintf(stderr, "Failed to close file '%s'. Error code: %d", bat_filename, err);
			exit(1);
		}
	}

	printf("The end!\n");
	exit(0);
}
void _runmain() { _start(); }

// source_end
