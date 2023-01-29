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
	echo static const char* b_output_dll_filename = "%~n0.dll";
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
static const int b_create_c_file = 0;
static const int b_create_preprocessed_builder = 0;
static const int b_compile_dll = 1;
static const int b_compile_source = 1;
static const int b_create_exe_file = 1;
static const int b_run_after_build = 1;
static const char* b_run_arguments = "-!h --dll";
static const int b_verbose = 1;

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FATAL(x, ...) do { if (x) break; fprintf(stderr, "[builder] %s:%d: FATAL: ", __FILE__, __LINE__); fprintf(stderr, __VA_ARGS__ ); fprintf(stderr, "\n(%s)\n", #x); void exit(int); exit(1); } while(0)

static char buffer[1024 * 1024];

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

	fputs("\nchar b_source_buffer[] = \"\"\n", outfile);
	insert_file_as_string(infile, outfile);
	fputc(';', outfile);
	fputs("\nchar* b_source_string = b_source_buffer;\n", outfile);

	fclose(infile);
	fclose(outfile);
}

int compile(const char* output_c, const char* output_exe)
{
	snprintf(buffer, sizeof(buffer), "%s %s -o %s %s %s %s", b_compiler_exe_path, output_c, output_exe, b_compiler_arguments);
	int result = system(buffer);
	FATAL(result == 0, "Error while compiling '%s'. Error value: %d", output_c, result);
	return result;
}

FILE* create_compilation_process()
{
	snprintf(buffer, sizeof(buffer), "%s - -o %s %s", b_compiler_exe_path, b_output_exe_filename, b_compiler_arguments);
	FILE* compiler_pipe = popen(buffer, "w");
	if (compiler_pipe)
		return compiler_pipe;

	FATAL(0, "Couldn't create a compiler process with '%s'.", buffer);
	return 0;
}

FILE* create_dll_compilation_process()
{
	snprintf(buffer, sizeof(buffer), "%s - -o %s %s -shared", b_compiler_exe_path, b_output_dll_filename, b_compiler_arguments);
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
		// TODO: Rename
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

	if (b_compile_source)
	{
		FILE* compiler_pipe = b_create_c_file ? 0 : create_compilation_process();

		const char* input_filename = b_source_filename && sizeof(b_source_filename) > 1 ? b_source_filename : 0;
		const char* output_c = b_output_c_filename && sizeof(b_output_c_filename) > 1 ? b_output_c_filename : 0;
		//printf("parse_code\n");
		put_source_code("#ifdef SOURCE", "#endif // SOURCE", input_filename, output_c, compiler_pipe);
		//printf("end parse_code\n");

		int err = compiler_pipe ? 0 : compile(output_c, b_output_exe_filename);
		if (err != 0)
			exit(err);

		if (compiler_pipe)
		{
			err = pclose(compiler_pipe);
			FATAL(err == 0, "Failed to close compiler pipe. Error code: %d", err);
		}
	}

	if (b_compile_dll)
	{
		FILE* infile = fopen(b_source_filename, "r");
		FILE* compiler_pipe = create_dll_compilation_process();
		FATAL(compiler_pipe, "Failed to create a compiler_pipe for '%s'.", b_output_dll_filename);

		insert_snippet("#ifdef DLL", "#endif // DLL", infile, compiler_pipe, b_source_filename);

		int err = pclose(compiler_pipe);
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
		printf("%s builder successfully finished.\n", b_source_filename);

	exit(0);
}
void _runmain() { _start(); }
#endif // BUILDER

///////////////////////////////////////////////////////////////////////////////

#ifdef SOURCE
#include <stdio.h>
#include <windows.h>
#include <sys/stat.h>

//#error test error on line 257

#define FATAL(x, ...) do { if (x) break; fprintf(stderr, "[source] %s:%d: FATAL: ", __FILE__, __LINE__); fprintf(stderr, __VA_ARGS__ ); fprintf(stderr, "\n(%s)\n", #x); void exit(int); exit(1); } while(0)

int cmp_modified_times(const char* file1, const char* file2)
{
	struct stat buf1;
	stat(file1, &buf1);
	
	struct stat buf2;
	stat(file2, &buf2);
	
	if (buf1.st_mtime == buf2.st_mtime)
		return 0;
	
	if (buf1.st_mtime < buf2.st_mtime)
		return -1;
	
	return 1;
}

char exe_filename[1024];
char bat_filename[1024];
char bat_new_filename[1024];
char dll_filename[1024];
static void finished()
{
	void exit(int);
	exit(0);
}

void* load_func(HMODULE hModule, const char* dll_filename, const char* func_name)
{
	void* func = GetProcAddress(hModule, func_name);
	FATAL(func, "Couldn't load '%s' from '%s'.", func_name, dll_filename);
	return func;
}

void replace(const char* string, const char* original, const char* replacement)
{
	FATAL(strlen(original) == strlen(replacement), "Non-equal length string replacements not implemented: %d != %d, (%s != %s)", strlen(original), strlen(replacement), original, replacement);

	char* match = strstr(string, original);
	if (!match)
		return;
	
	int len = strlen(original);
	for (int i = 0; i < len; ++i)
		match[i] = replacement[i];
}

void handle_commandline_arguments()
{
	char* commandLine = GetCommandLine();

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
		memcpy(exe_filename, head, len + 1);
		
		memcpy(dll_filename, exe_filename, len - 3);
		sprintf(dll_filename + len - 3, "dll");
		
		memcpy(bat_filename, exe_filename, len - 3);
		sprintf(bat_filename + len - 3, "bat");
		
		memcpy(bat_new_filename, exe_filename, len - 4);
		sprintf(bat_new_filename + len - 4, "_new.bat");
	}

	if (strstr(commandLine, " -h") || strstr(commandLine, "help"))
	{
	}
	else if (strstr(commandLine, "--print_source"))
	{
		extern const char* b_source_string;
		printf("%s", b_source_string);
		
		finished();
	}
	else if (strstr(commandLine, "--create_builder"))
	{
		FILE* out = fopen(bat_new_filename, "w");
		FATAL(out, "Failed to get filename from GetCommandLine(): '%s'", commandLine);

		extern const char* b_source_string;
		fputs(b_source_string, out);
		int err = fclose(out);
		FATAL(err == 0, "Failed to close file '%s'. Error code: %d", bat_new_filename, err);
		
		finished();
	}
	else if(strstr(commandLine, "--dll"))
	{
		void* malloc(size_t);
		void* state = malloc(1000);
		
		HMODULE hModule = LoadLibrary(dll_filename);
		FATAL(GetLastError() == 0, "Error loading %s.", dll_filename);

		int i = 1000;
		while (i-- > 0)
		{
			if (cmp_modified_times(dll_filename, bat_filename) < 0)
			{
				printf("Recompiling '%s'\n", dll_filename);
				FreeLibrary(hModule);
				
				printf("-4\n");
				
				const char prefix[] = ""
					"\n" "static const char* b_source_filename = \"%s\";"
					"\n" "static const char* b_output_exe_filename = \"NOT_USED.exe\";"
					"\n" "static const char* b_output_dll_filename = \"%s\";"
					"\n" "static const char* b_output_c_filename = \"NOT_USED.c\";"
					"\n" "static const char* b_compiler_exe_path = \"tcc.exe\";"
					"\n" "#define BUILDER"
					"\n" "#line 0 \"%s\""
					"\n" "#if GOTO_BOOTSTRAP_BUILDER"
					"\n";

				extern char* b_source_string;

				replace(b_source_string, "b_compile_source = 1;", "b_compile_source = 0;");
				replace(b_source_string, "b_create_exe_file = 1;", "b_create_exe_file = 0;");
				replace(b_source_string, "b_compile_dll = 0;", "b_compile_dll = 1;");
				replace(b_source_string, "b_verbose = 1;", "b_verbose = 0;");
				replace(b_source_string, "b_run_after_build = 1;", "b_run_after_build = 0;");

				FILE* compiler_pipe = popen("tcc.exe - -run -nostdlib -lmsvcrt -nostdinc -Iinclude -Iinclude/winapi", "w");
				fprintf(compiler_pipe, prefix, bat_filename, dll_filename, bat_filename); 
				fputs(b_source_string, compiler_pipe);
				
				int err = pclose(compiler_pipe);
				FATAL(err == 0, "Failed to recompile %s using included source code.", dll_filename);
				
				hModule = LoadLibrary(dll_filename);
				FATAL(GetLastError() == 0, "Error loading %s.", dll_filename);
			}

			FATAL(NULL != hModule, "Couldn't load '%s'. Error: 0x%X.", dll_filename, GetLastError());

			typedef void (*SetupFunc)(void* state);
			SetupFunc setup = (SetupFunc)load_func(hModule, dll_filename, "setup");

			typedef int (*UpdateFunc)(void* state, float deltatime);
			UpdateFunc update = (UpdateFunc)load_func(hModule, dll_filename, "update");

			setup(state);
			int stop = update(state, 0.016);
			if (stop != 0)
				break;

			Sleep(16);
		}
		
		FreeLibrary(hModule);
		finished();
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
		
		finished();
	}
}

void _start()
{
	handle_commandline_arguments();
}

void _runmain() { _start(); }
#endif // SOURCE

///////////////////////////////////////////////////////////////////////////////

#ifdef DLL
#include <stdio.h>
#include <windows.h>

#define FATAL(x, ...) do { if (x) break; fprintf(stderr, "[dll] %s:%d: FATAL: ", __FILE__, __LINE__); fprintf(stderr, __VA_ARGS__ ); fprintf(stderr, "\n(%s)\n", #x); void exit(int); exit(1); } while(0)
	
#define DLL_FUNC __declspec(dllexport)

typedef struct
{
	int initialized;
	float time;
} State;
enum { StateInitializedMagicNumber = 12345 };

DLL_FUNC void setup(void* state_ptr)
{
	State* state = state_ptr;
	
	if (state->initialized == StateInitializedMagicNumber)
		return;

	printf("Init state.\n");
	memset(state, 0, sizeof(*state));
	state->initialized = StateInitializedMagicNumber;
	state->time = 0.0f;
}

DLL_FUNC int update(void* state_ptr, float deltatime)
{
	State* state = state_ptr;
	FATAL(state->initialized == StateInitializedMagicNumber, "Calling update with uninitialized state.");
	
	state->time += deltatime;
	printf("dt: %f\n", state->time);
	return 0;
}

void _dllstart()
{
	static int started = 0;
	if (!started)
	{
		printf("Starting dll!\n");
		started = 1;
	}
	else
	{
		printf("Stopping dll.\n");
	}
}

#endif // DLL

