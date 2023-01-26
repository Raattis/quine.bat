@goto bootstrap_builder
#error Remember to insert "#if 0" into the compiler input pipe or skip the 3 first lines when compiling this file.
#endif // GOTO_BOOTSTRAP_BUILDER

///////////////////////////////////////////////////////////////////////////////

#ifdef BOOTSTRAP_BUILDER
:bootstrap_builder
@echo off
set compiler_exe=tcc.exe
@rem if exist .\%~n0.exe del .\%~n0.exe
(
	echo static const char* b_source_filename = "%~n0%~x0";
	echo static const char* b_output_exe_filename = "%~n0.exe";
	echo static const char* b_output_c_filename = "%~n0.c";
	echo static const char* b_compiler_exe_path = "%compiler_exe%";
	echo #define BUILDER
	echo #line 0 "%~n0%~x0"
	echo #if GOTO_BOOTSTRAP_BUILDER
	type %~n0%~x0 
) | %compiler_exe% - -run -nostdlib -lmsvcrt -nostdinc -Iinclude -Iinclude/winapi -bench
@exit ERRORLEVEL
#endif // BOOTSTRAP_BUILDER

///////////////////////////////////////////////////////////////////////////////

//#error test error on line 27

#ifdef BUILDER
static const char* b_compiler_arguments = "-Iinclude -Iinclude/winapi -nostdlib -nostdinc -lmsvcrt -lkernel32";
static const int b_create_c_file = 1;
static const int b_create_preprocessed_builder = 1;
static const int b_create_exe_file = 1;
static const int b_run_after_build = 1;
static const char* b_run_arguments = "-h";
static const int b_verbose = 1;

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FATAL(x, ...) do { if (x) break; fprintf(stderr, "%d: ", __LINE__); fprintf(stderr, __VA_ARGS__ ); fprintf(stderr, "\n(%s)\n", #x); void exit(int); exit(1); } while(0)

char buffer[1024 * 1024];

//int enable_print = 0;
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
			fprintf(outfile, "#line %d %s\n", line_number + 1, input_filename);
		else
			fprintf(outfile, "#line %d \"%s\"\n", line_number + 1, input_filename);
	}

	if (stop) {
		int stop_len = stop ? strlen(stop) : 0;
		while (fgets(buffer, sizeof(buffer), infile)) {
			//if (enable_print) printf("%s", buffer);
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

int put_source_code(const char* start, const char* stop, const char* input_filename, const char* output_c, FILE* compiler_pipe)
{
	FILE *infile = fopen(input_filename, "r");
	FILE *outfile = compiler_pipe ? compiler_pipe : fopen(output_c, "w");

	insert_snippet(start, stop, infile, outfile, input_filename);

	fseek(infile, 0, SEEK_SET);

	fputs("\nconst char* b_source_string = \"\"\n", outfile);
	insert_file_as_string(infile, outfile);
	fputc(';', outfile);

	fclose(infile);
	fclose(outfile);
}

int compile(const char* output_c, const char* output_exe)
{
	snprintf(buffer, sizeof(buffer), "%s %s -o %s %s %s %s", b_compiler_exe_path, output_c, output_exe, b_compiler_arguments, b_create_exe_file ? "" : "-run");
	int result = system(buffer);
	FATAL(result == 0, "Error while compiling '%s'. Error value: %d", output_c, result);
	return result;
}

FILE* create_compilation_process()
{
	snprintf(buffer, sizeof(buffer), "%s - -o %s %s %s", b_compiler_exe_path, b_output_exe_filename, b_compiler_arguments, b_create_exe_file ? "" : "-run");
	FILE* compiler_pipe = popen(buffer, "w");
	if (compiler_pipe)
		return compiler_pipe;

	FATAL(0, "Couldn't create a compiler process with '%s'.", buffer);
	return 0;
}

FILE* create_preprocessor_process(const char* input_file)
{
	snprintf(buffer, sizeof(buffer), "%s -P %s -E %s", b_compiler_exe_path, input_file, b_compiler_arguments);
	FILE* compiler_pipe = popen(buffer, "r");
	if (compiler_pipe)
		return compiler_pipe;

	FATAL(0, "Couldn't create a preprocessor process with '%s'.", buffer);
	return 0;
}

void crash_handler(int sig)
{
	FATAL(0, "!!!! crash_handler: %d", sig);
}

void _start()
{
	signal(SIGSEGV, crash_handler);

	if (b_verbose)
		printf("Running %s builder.\n", b_output_exe_filename);

	if (b_create_preprocessed_builder)
	{
		const char* package_filename = "quine_packaged.bat";
		FILE* out = fopen(package_filename, "w");
		FILE* infile = fopen(b_source_filename, "r");
		
		insert_snippet(0, "#endif // SOURCE", infile, out, 0);
		fputs("#endif // SOURCE\n", out);
		
		{
			fputs("\n///////////////////////////////////////////////////////////////////////////////\n\n", out);
			fputs("#ifdef PREPROCESSED\n", out);
			
			// TODO: Delete this temp file
			FILE* source_for_preprocessor = fopen("source_for_preprocessor.c", "w");
			fseek(infile, 0, SEEK_SET);

			insert_snippet("#ifdef SOURCE", "#endif // SOURCE", infile, source_for_preprocessor, 0);
		
			fclose(source_for_preprocessor);
		
			if (b_verbose) printf("Creating preprocessor\n");
			FILE* preprocessor_result = create_preprocessor_process("source_for_preprocessor.c");
			while (fgets(buffer, sizeof(buffer), preprocessor_result))
				fputs(buffer, out);
			fclose(preprocessor_result);
		
			fputs("#endif // PREPROCESSED\n", out);
		}
		
		fclose(infile);
		fclose(out);
		
		if (b_verbose) printf("Finished creating a package.");
		exit(0);
	}

	FILE* compiler_pipe = b_create_c_file ? 0 : create_compilation_process();

	const char* input_filename = b_source_filename && sizeof(b_source_filename) > 1 ? b_source_filename : 0;
	const char* output_c = b_output_c_filename && sizeof(b_output_c_filename) > 1 ? b_output_c_filename : 0;
	put_source_code("#ifdef SOURCE", "#endif // SOURCE", input_filename, output_c, compiler_pipe);

	int err = compiler_pipe ? 0 : compile(output_c, b_output_exe_filename);
	if (err != 0)
		exit(err);

	if (compiler_pipe)
	{
		err = pclose(compiler_pipe);
		FATAL(err == 0, "Failed to close compiler pipe. Error code: %d", err);
	}

	if (b_run_after_build)
	{
		FATAL(b_create_exe_file, "Can't run exe if it wasn't built.");

		snprintf(buffer, sizeof(buffer), "%s %s", b_output_exe_filename, b_run_arguments);
		printf("---------------------------------------\n");
		int result = system(buffer);
		printf("---------------------------------------\n");
		printf("%s returned %d\n", b_output_exe_filename, result);
	}

	if (b_verbose)
		printf("%s builder successfully finished.\n", b_output_exe_filename);

	exit(0);
}
void _runmain() { _start(); }
#endif // BUILDER

///////////////////////////////////////////////////////////////////////////////

#ifdef SOURCE
#include <stdio.h>
#include <windows.h>

//#error test error on line 180

#define FATAL(x, ...) do { if (x) break; fprintf(stderr, "\n(%s)\n", #x); fprintf(stderr, "%d: ", __LINE__); fprintf(stderr, __VA_ARGS__ ); fprintf(stderr, "\n"); void exit(int); exit(1); } while(0)

void handle_commandline_arguments()
{
	char* commandLine = GetCommandLine();

	char exe_filename[1024];
	char bat_filename[1024];
	{
		int len = 0;
		int err = sscanf(commandLine, "%s%n", exe_filename, &len);
		FATAL(err == 1, "Failed to get filename from GetCommandLine(): '%s', err: %d", commandLine, err);

		if (exe_filename[len - 1] == '"')
		{
			len -= 2;
			memcpy(exe_filename, exe_filename+1, len);
			exe_filename[len] = 0;
		}
		char* start = exe_filename;
		char* head = exe_filename + len;
		while (head > start && *(head - 1) != '\\' && *(head - 1) != '/')
			--head;
		len = strlen(head);
		memcpy(bat_filename, head, len - 4);
		memcpy(exe_filename, head, len + 1);
		sprintf(bat_filename + len - 4, "_new.bat");
	}

	if (strstr(commandLine, " -h") || strstr(commandLine, "help"))
	{
	}
	else if (strstr(commandLine, "--print_source"))
	{
		extern const char* b_source_string;
		printf("%s", b_source_string);
		void exit(int);
		exit(0);
	}
	else if (strstr(commandLine, "--create_builder"))
	{
		FILE* out = fopen(bat_filename, "w");
		FATAL(out, "Failed to get filename from GetCommandLine(): '%s'", commandLine);

		extern const char* b_source_string;
		fputs(b_source_string, out);
		int err = fclose(out);
		FATAL(err == 0, "Failed to close file '%s'. Error code: %d", bat_filename, err);
		void exit(int);
		exit(0);
	}

	{
		printf("\n" "  How to build?");
		printf("\n" "    1. Get 'Tiny C Compiler' (links below)");
		printf("\n" "    2. Run `> .\\%s --create_builder` to produce `%s`", exe_filename, bat_filename);
		printf("\n" "    3. Place it into tcc\\%s", bat_filename);
		printf("\n" "    4. Run `.\\%s`", bat_filename);
		printf("\n");
		printf("\n" "  Tiny C Compiler:");
		printf("\n" "    tcc is required for the %s to work as intended.", bat_filename);
		printf("\n" "    Not many compilers have its feature set such as");
		printf("\n" "    accepting source code via stdin.");
		printf("\n");
		printf("\n" "    Windows download: http://download.savannah.gnu.org/releases/tinycc/");
		printf("\n" "    Source code: https://github.com/Tiny-C-Compiler/mirror-repository");
		printf("\n" "    Tested with: tcc-0.9.27-win64-bin.zip");
		printf("\n");
		printf("\n" "  Flags:");
		printf("\n" "    --print_source\tPrint the source code this program was built with into stdout.");
		printf("\n" "    --create_builder\tOutputs a '%s_new.bat' file that can build this executable.", bat_filename);
		printf("\n\n");
		void exit(int);
		exit(0);
	}
}

void _start()
{
	handle_commandline_arguments();
}

void _runmain() { _start(); }
#endif // SOURCE
