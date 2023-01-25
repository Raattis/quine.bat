@goto build
:build
@echo off
@rem if exist .\%~n0.exe del .\%~n0.exe
(
	echo const char* _source_filename = "%~n0%~x0";
	echo #line 0 "%~n0%~x0"
	echo #if 0
	type %~n0%~x0
) | .\tcc.exe - -DBUILDER -nostdlib -lmsvcrt -nostdinc -Iinclude -Iinclude/winapi -run
if ERRORLEVEL 1 exit ERRORLEVEL
.\%~n0.exe
@exit ERRORLEVEL
#endif

#ifdef BUILDER
const int _variables_set = 0;
const char* _compiler_bin = ".\\tcc.exe";
extern const char* _source_filename;
char* _output_exe;
char* _output_c;
int _create_c_file = 1;
int _create_exe_file = 1;
int _run_exe = 0;
int _verbose = 1;

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

#include <sys/stat.h>
#include <windows.h>

char filename_buffer[1024];

void setGlobalVariables()
{
	if (_variables_set)
		return;

	//printf("_source_filename=%s\n", _source_filename);

	struct stat buf;
	if (stat(_compiler_bin, &buf) < 0)
	{
		if (stat(".\\static-tcc.exe", &buf) >= 0)
			_compiler_bin = ".\\static-tcc.exe";
		else if (stat(".\\tcc.exe", &buf) >= 0)
			_compiler_bin = ".\\static-tcc.exe";
	}

	int filename_size = strlen(_source_filename) + 1;
	_output_exe = filename_buffer + filename_size;
	memcpy(_output_exe, _source_filename, filename_size);
	_output_exe[filename_size - 4] = 'e';
	_output_exe[filename_size - 3] = 'x';
	_output_exe[filename_size - 2] = 'e';

	_output_c = filename_buffer + filename_size * 2;
	memcpy(_output_c, _source_filename, filename_size);
	_output_c[filename_size - 4] = 'c';
	_output_c[filename_size - 3] = 0;

	//printf("%s, %s, %s\n", _source_filename, _output_exe, _output_c);

	int _create_exe_file = 1;
	int _run_exe = 0;
	int _verbose = 1;
}

void _start()
{
	setGlobalVariables();

	signal(SIGSEGV, crash_handler);

	if (_verbose)
		printf("Running %s builder.\n", _output_exe);

	FILE* compiler_pipe = _create_c_file ? 0 : create_compilation_process(_output_exe);

	const char* input_filename = _source_filename && sizeof(_source_filename) > 1 ? _source_filename : 0;
	const char* output_c = _output_c && sizeof(_output_c) > 1 ? _output_c : 0;
	create_code_file("#ifdef SOURCE", "#endif // SOURCE", input_filename, output_c, compiler_pipe);

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
#endif // BUILDER

#ifdef SOURCE
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
#endif // SOURCE
