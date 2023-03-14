: " In sh this is the beginning of a multiline comment, in batch this is a valid label.
@goto batch_bootstrap_builder "
if false; then */
#error Remember to insert "#if 0" into the compiler input pipe or skip the first 5 lines when compiling this file.
#endif // GOTO_BOOTSTRAP_BUILDER

///////////////////////////////////////////////////////////////////////////////

#ifdef BOOTSTRAP_BUILDER
/*
fi # sh_bootstrap_builder

#Did you know that hashbang doesn't have to be on the first line of a file? Wild, right! "
#!/bin/sh

compiler_executable=gcc
me=`basename "$0"`
no_ext=`echo "$me" | cut -d'.' -f1`
builder_executable="${no_ext}_builder.exe"
echo "static const char* b_source_filename = \"$me\";
static const char* b_output_exe_filename = \"$no_ext.exe\";
static const char* b_output_dll_filename = \"$no_ext.dll\";
static const char* b_output_c_filename = \"$no_ext.c\";
static const char* b_compiler_executable_path = \"$compiler_executable\";
#define HELLO_WORLD
#line 1 \"$me\"
#if GOTO_BOOTSTRAP_BUILDER /*" | cat - $me | $compiler_executable -x c - -o $builder_executable

compiler_exit_status=$?
if test $compiler_exit_status -ne 0; then echo "Failed to compile $me. Exit code: $compiler_exit_status"; exit $compiler_exit_status; fi

chmod +x $builder_executable
./$builder_executable

execution_exit_status=$?
if test $execution_exit_status -ne 0; then echo "$builder_executable exited with status $execution_exit_status"; exit $execution_exit_status; fi

# -run -bench -nostdlib -lmsvcrt(?) -nostdinc -Iinclude
exit 0


:batch_bootstrap_builder
@echo off
set compiler_executable=tcc.exe
set compiler_zip_name=tcc-0.9.27-win64-bin.zip
set download_tcc=n
if not exist %compiler_executable% if not exist %compiler_zip_name% set /P download_tcc="Download Tiny C Compiler? Please, try to avoid unnecessary redownloading. [y/n] "

if not exist %compiler_executable% (
	if not exist %compiler_zip_name% (
		if %download_tcc% == y (
			powershell -Command "Invoke-WebRequest http://download.savannah.gnu.org/releases/tinycc/%compiler_zip_name% -OutFile %compiler_zip_name%"
			if exist %compiler_zip_name% (
				echo Download complete!
			) else (
				echo Failed to download %compiler_zip_name%
			)
		)

		if not exist %compiler_zip_name% (
			echo Download Tiny C Compiler manually from http://download.savannah.gnu.org/releases/tinycc/ and unzip it here.
			pause
			exit 1
		)
	)

	if not exist tcc (
		echo Unzipping %compiler_zip_name%
		powershell Expand-Archive %compiler_zip_name% -DestinationPath .

		if exist %compiler_executable% (
			echo It seems the %compiler_zip_name% contained the %compiler_executable% directly. Thats cool.
		) else if not exist tcc (
			echo Unzipping %compiler_zip_name% did not yield the expected "tcc" folder.
			echo Move the contents of the archive here manually so that tcc.exe is in the same folder as %~n0%~x0.
			pause
			exit 1
		)
	)

	if not exist %compiler_executable% (
		echo Moving files from .\tcc\* to .\*
		robocopy /NJH /NJS /NS /NC /NFL /NDL /NP /MOVE /E tcc .

		if not exist %compiler_executable% (
			echo %compiler_executable% still not found.
			echo Download Tiny C Compiler manually and unzip it here.
			pause
			exit 1
		)
	)

	echo Tiny C Compiler Acquired!
) 

(
	echo static const char* b_source_filename = "%~n0%~x0";
	echo static const char* b_output_exe_filename = "%~n0.exe";
	echo static const char* b_output_dll_filename = "%~n0.dll";
	echo static const char* b_output_c_filename = "%~n0.c";
	echo static const char* b_compiler_executable_path = "%compiler_executable%";
	echo #define BUILDER
	echo #line 0 "%~n0%~x0"
	echo #if GOTO_BOOTSTRAP_BUILDER
	type %~n0%~x0 
) | %compiler_executable% - -run -nostdlib -lmsvcrt -nostdinc -Iinclude -Iinclude/winapi -bench
@exit ERRORLEVEL
*/
#endif // BOOTSTRAP_BUILDER

///////////////////////////////////////////////////////////////////////////////

#ifdef HELLO_WORLD

#include <stdio.h>

int main()
{
	printf("Hello, World!\n");
	return 0;
}

#endif // HELLO_WORLD

///////////////////////////////////////////////////////////////////////////////

#ifdef BUILDER

static const char* b_compiler_arguments = "-Iinclude -Iinclude/winapi -nostdlib -nostdinc -lmsvcrt -lkernel32 -luser32 -lgdi32";
static const int b_create_c_file = 0;
static const int b_create_preprocessed_builder = 0;
static const int b_compile_dll = 1;
static const int b_compile_source = 0;
static const int b_create_exe_file = 1;
static const int b_run_after_build = 1;
static const char* b_run_arguments = "--dll --!print_source --!create_builder --!help";
static const int b_verbose = 1;

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SEGMENT_NAME "builder"
#define FATAL(x, ...) do { if (x) break; fprintf(stderr, "%s:%d: (" SEGMENT_NAME "/%s) FATAL: ", __FILE__, __LINE__, __FUNCTION__); fprintf(stderr, __VA_ARGS__ ); fprintf(stderr, "\n(%s)\n", #x); void exit(int); exit(1); } while(0)

static char buffer[1024 * 1024];

int insert_snippet(const char* start, const char* stop, FILE* infile, FILE* outfile, const char* input_filename, int* line_number)
{
	FATAL(infile, "Infile is not falid: %s.", input_filename);
	if (start) {
		int start_len = strlen(start);
		while (fgets(buffer, sizeof(buffer), infile)) {
			if (line_number)
				++*line_number;
			if (strncmp(buffer, start, start_len) == 0) break;
		}
	}

	if (input_filename && line_number) {
		++*line_number;
		if (input_filename[0] == '"')
			fprintf(outfile, "#line %d %s\n", *line_number, input_filename);
		else
			fprintf(outfile, "#line %d \"%s\"\n", *line_number, input_filename);
	}

	if (stop) {
		int stop_len = stop ? strlen(stop) : 0;
		while (fgets(buffer, sizeof(buffer), infile)) {
			if (stop && strncmp(buffer, stop, stop_len) == 0) break;
			fputs(buffer, outfile);
			if (line_number)
				++*line_number;
		}
	}
	else
	{
		while (fgets(buffer, sizeof(buffer), infile))
		{
			if (line_number)
				++*line_number;
			fputs(buffer, outfile);
		}
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

int compile(const char* output_c, const char* output_exe)
{
	snprintf(buffer, sizeof(buffer), "%s %s -o %s %s", b_compiler_executable_path, output_c, output_exe, b_compiler_arguments);
	int result = system(buffer);
	FATAL(result == 0, "Error while compiling '%s'. Error value: %d", output_c, result);
	return result;
}

FILE* create_compilation_process()
{
	snprintf(buffer, sizeof(buffer), "%s -x c - -o %s %s", b_compiler_executable_path, b_output_exe_filename, b_compiler_arguments);
	FILE* compiler_pipe = popen(buffer, "w");
	if (compiler_pipe)
		return compiler_pipe;

	FATAL(0, "Couldn't create a compiler process with '%s'.", buffer);
	return 0;
}

FILE* create_dll_compilation_process()
{
	snprintf(buffer, sizeof(buffer), "%s - -o %s %s -shared", b_compiler_executable_path, b_output_dll_filename, b_compiler_arguments);
	FILE* compiler_pipe = popen(buffer, "w");
	if (compiler_pipe)
		return compiler_pipe;

	FATAL(0, "Couldn't create a compiler process with '%s'.", buffer);
	return 0;
}

FILE* create_preprocessor_process(const char* input_file)
{
	snprintf(buffer, sizeof(buffer), "%s %s -E %s", b_compiler_executable_path, input_file, b_compiler_arguments);
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

void main()
{
	signal(SIGSEGV, crash_handler);

	if (b_verbose)
		printf("Running %s builder.\n", b_output_exe_filename);

	if (b_create_preprocessed_builder)
	{
		char package_filename[1000] = {0};
		sprintf(package_filename, "%.*s_preprocessed.bat", (int)(strlen(b_source_filename) - 4), b_source_filename);

		FILE* out = fopen(package_filename, "w");
		FILE* infile = fopen(b_source_filename, "r");

		insert_snippet(0, "static const int b_create_preprocessed_builder = 1;", infile, out, 0, 0);
		fputs("static const int b_create_preprocessed_builder = 0;\n", out);

		insert_snippet(0, "#endif // BUILDER", infile, out, 0, 0);
		fputs("#endif // BUILDER\n", out);

		fputs("\n///////////////////////////////////////////////////////////////////////////////\n\n", out);
		fputs("#ifdef SHARED_PREFIX\n", out);
		fputs("// Contents already included in the preprocessed SOURCE and DLL sections\n", out);
		fputs("#endif // SHARED_PREFIX\n", out);

		{
			fputs("\n///////////////////////////////////////////////////////////////////////////////\n\n", out);
			fputs("#ifdef SOURCE\n", out);

			const char temp_filename[] = "temp_source_file_to_preprocess.c";
			FILE* temp_file = fopen(temp_filename, "w");
			fseek(infile, 0, SEEK_SET);

			insert_snippet("#ifdef SHARED_PREFIX", "#endif // SHARED_PREFIX", infile, temp_file, 0, 0);
			insert_snippet("#ifdef SOURCE", "#endif // SOURCE", infile, temp_file, 0, 0);
			fclose(temp_file);

			if (b_verbose) printf("Creating preprocessor for SOURCE\n");
			FILE* preprocessor_result = create_preprocessor_process(temp_filename);

			{
				// Skip first line as it's the #line directive with the temp_filename
				fgets(buffer, sizeof(buffer), preprocessor_result);
			}

			while (fgets(buffer, sizeof(buffer), preprocessor_result))
				fputs(buffer, out);
			pclose(preprocessor_result);
			remove(temp_filename);

			fputs("#endif // SOURCE\n", out);
		}

		{
			fputs("\n///////////////////////////////////////////////////////////////////////////////\n\n", out);
			fputs("#ifdef DLL\n", out);

			const char temp_filename[] = "temp_dll_file_to_preprocess.c";
			FILE* temp_file = fopen(temp_filename, "w");
			fseek(infile, 0, SEEK_SET);

			insert_snippet("#ifdef SHARED_PREFIX", "#endif // SHARED_PREFIX", infile, temp_file, 0, 0);
			insert_snippet("#ifdef DLL", "#endif // DLL", infile, temp_file, 0, 0);
			fclose(temp_file);

			if (b_verbose) printf("Creating preprocessor for DLL\n");
			FILE* preprocessor_result = create_preprocessor_process(temp_filename);

			{
				// Skip first line as it's the #line directive with the temp_filename
				fgets(buffer, sizeof(buffer), preprocessor_result);
			}

			while (fgets(buffer, sizeof(buffer), preprocessor_result))
				fputs(buffer, out);
			pclose(preprocessor_result);
			remove(temp_filename);

			fputs("#endif // DLL\n", out);
		}

		fseek(infile, 0, SEEK_SET);

		{
			fputs("\n///////////////////////////////////////////////////////////////////////////////\n\n", out);
			fputs("#ifdef ORIGINAL_SHARED_PREFIX\n", out);

			insert_snippet("#ifdef SHARED_PREFIX", "#endif // SHARED_PREFIX", infile, out, 0, 0);
			fputs("\n#endif // ORIGINAL_SHARED_PREFIX\n", out);
		}

		{
			fputs("\n///////////////////////////////////////////////////////////////////////////////\n\n", out);
			fputs("#ifdef ORIGINAL_SOURCE\n", out);
			insert_snippet("#ifdef SOURCE", "#endif // SOURCE", infile, out, 0, 0);
			fputs("\n#endif // ORIGINAL_SOURCE\n", out);
		}
		{
			fputs("\n///////////////////////////////////////////////////////////////////////////////\n\n", out);
			fputs("#ifdef ORIGINAL_DLL\n", out);
			insert_snippet("#ifdef DLL", "#endif // DLL", infile, out, 0, 0);
			fputs("\n#endif // ORIGINAL_DLL\n", out);
		}

		fclose(infile);
		fclose(out);

		if (b_verbose) printf("Finished creating a package.");

		exit(0);
	}

	if (b_compile_source || b_create_c_file || b_create_exe_file)
	{
		FILE* infile = fopen(b_source_filename, "r");
		FILE* outfile = b_create_c_file ? fopen(b_output_c_filename, "w") : create_compilation_process();

		int line_number = 0;
		insert_snippet("#ifdef SHARED_PREFIX", "#endif // SHARED_PREFIX", infile, outfile, b_source_filename, &line_number);

		insert_snippet("#ifdef SOURCE", "#endif // SOURCE", infile, outfile, b_source_filename, &line_number);

		fseek(infile, 0, SEEK_SET);
		fputs("\nchar b_source_buffer[] = \"\"\n", outfile);
		insert_file_as_string(infile, outfile);
		fputc(';', outfile);
		fputs("\nchar* b_source_string = b_source_buffer;\n", outfile);

		if (b_create_c_file)
		{
			fclose(outfile);

			if (b_create_exe_file)
			{
				int err = compile(b_output_c_filename, b_output_exe_filename);
				if (err != 0)
					FATAL(0, "Failed to compile created %s.", b_output_c_filename);
			}
		}
		else
		{
			int err = pclose(outfile);
			FATAL(err == 0, "Failed to close compiler pipe. Error code: %d", err);
		}
	}

	if (b_compile_dll)
	{
		FILE* infile = fopen(b_source_filename, "r");
		FILE* compiler_pipe = create_dll_compilation_process();
		FATAL(compiler_pipe, "Failed to create a compiler_pipe for '%s'.", b_output_dll_filename);

		int line_number = 0;
		insert_snippet("#ifdef SHARED_PREFIX", "#endif // SHARED_PREFIX", infile, compiler_pipe, b_source_filename, &line_number);
		insert_snippet("#ifdef DLL", "#endif // DLL", infile, compiler_pipe, b_source_filename, &line_number);

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
void _runmain() { main(); }
//void _start() { main(); }
#endif // BUILDER

///////////////////////////////////////////////////////////////////////////////

#ifdef SHARED_PREFIX

typedef struct
{
	int stop;
	int request_recompile;
	int was_recompiled;
	unsigned long long buffer_size;
	char* buffer;
} Communication;

#endif // SHARED_PREFIX

///////////////////////////////////////////////////////////////////////////////

#ifdef SOURCE

#include <stdio.h>
#include <windows.h>
#include <sys/stat.h>

#define SEGMENT_NAME "source"
#define FATAL(x, ...) do { if (x) break; fprintf(stderr, "%s:%d: (" SEGMENT_NAME "/%s) FATAL: ", __FILE__, __LINE__, __FUNCTION__); fprintf(stderr, __VA_ARGS__ ); fprintf(stderr, "\n(%s)\n", #x); void exit(int); exit(1); } while(0)

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

size_t scan_includes(char* source_file, char** files_to_watch, size_t files_to_watch_count, size_t written)
{
	if (written == 0 && files_to_watch[0] == 0)
		printf("Watching '%s' for changes.\n", source_file);

	files_to_watch[written] = source_file;
	written += 1;

	char buffer[1024] = {0};

	FILE* infile = fopen(source_file, "r");
	while (fgets(buffer, sizeof(buffer), infile))
	{
		if (strstr(buffer, "#include \"") == 0)
			continue;

		char* begin = buffer + strlen("#include \"");
		char* end = begin;
		while(end < buffer + files_to_watch_count && *end != '"' && *end != 0)
			end += 1;

		int found = 0;
		for (size_t i = 0; i < written; i++)
		{
			if (strncmp(files_to_watch[i], begin, end - begin) == 0)
			{
				found = 1;
				break;
			}
		}

		if (found)
			continue;

		char* include_file = files_to_watch[written];
		if (include_file == 0 || strncmp(include_file, begin, end - begin) != 0)
		{
			if (include_file != 0)
				free(include_file);

			include_file = (char*)malloc(end - begin);
			strncpy(include_file, begin, end - begin);
			include_file[end - begin] = 0;

			printf("Watching '%s' for changes.\n", include_file);
		}
		written = scan_includes(include_file, files_to_watch, files_to_watch_count, written);
	}

	return written;
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

	if (strstr(commandLine, " -h") || strstr(commandLine, "--help"))
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
		void* user_buffer = malloc(1000);
		int force_recompile = 0;

		HMODULE hModule = LoadLibrary(dll_filename);
		FATAL(hModule, "Error loading %s. Error: %d", dll_filename, GetLastError());

		char* files_to_watch[256] = {0};
		size_t files_to_watch_count = scan_includes(bat_filename, files_to_watch, 256, 0);

		while (1)
		{
			int was_recompiled = 0;

			int any_file_modified = 0;
			for (size_t i = 0; i < files_to_watch_count; ++i)
			{
				if (cmp_modified_times(dll_filename, files_to_watch[i]) < 0)
				{
					printf("Timestamp of '%s' was newer than '%s'\n", files_to_watch[i], dll_filename);
					any_file_modified = 1;
					break;
				}
			}

			if (force_recompile || any_file_modified)
			{
				printf("Recompiling '%s'\n", dll_filename);
				if (hModule)
					FreeLibrary(hModule);

				const char prefix[] = ""
					"\n" "static const char* b_source_filename = \"%s\";"
					"\n" "static const char* b_output_exe_filename = \"NOT_USED.exe\";"
					"\n" "static const char* b_output_dll_filename = \"%s\";"
					"\n" "static const char* b_output_c_filename = \"NOT_USED.c\";"
					"\n" "static const char* b_compiler_executable_path = \"tcc.exe\";"
					"\n" "#define BUILDER"
					"\n" "#line 0 \"%s\""
					"\n" "#if GOTO_BOOTSTRAP_BUILDER"
					"\n";

				extern char* b_source_string;

				replace(b_source_string, "b_create_c_file = 1;", "b_create_c_file = 0;");
				replace(b_source_string, "b_create_preprocessed_builder = 1;", "b_create_preprocessed_builder = 0;");
				replace(b_source_string, "b_compile_source = 1;", "b_compile_source = 0;");
				replace(b_source_string, "b_create_exe_file = 1;", "b_create_exe_file = 0;");
				replace(b_source_string, "b_compile_dll = 0;", "b_compile_dll = 1;");
				replace(b_source_string, "b_verbose = 1;", "b_verbose = 0;");
				replace(b_source_string, "b_run_after_build = 1;", "b_run_after_build = 0;");

				FILE* compiler_pipe = popen("tcc.exe - -run -nostdlib -lmsvcrt -nostdinc -Iinclude -Iinclude/winapi", "w");
				fprintf(compiler_pipe, prefix, bat_filename, dll_filename, bat_filename); 
				fputs(b_source_string, compiler_pipe);

				int err = pclose(compiler_pipe);
				if (err != 0)
				{
					fprintf(stderr, "Failed to recompile %s using included source code.", dll_filename);
					Sleep(5000);
					continue;
				}

				hModule = LoadLibrary(dll_filename);
				if (!hModule)
				{
					fprintf(stderr, "Error while loading %s. Error: 0x%X\n", dll_filename, GetLastError());
					Sleep(5000);
					continue;
				}

				files_to_watch_count = scan_includes(bat_filename, files_to_watch, 256, 0);

				force_recompile = 0;
				was_recompiled = 1;
			}

			if (!hModule)
			{
				fprintf(stderr, "'%s' not loaded. Last error: 0x%X\n.", dll_filename, GetLastError());
				force_recompile = 1;
				Sleep(500);
				continue;
			}

			typedef int (*UpdateFunc)(Communication* communication);
			UpdateFunc update = (UpdateFunc)load_func(hModule, dll_filename, "update");

			Communication communication = {0};
			communication.was_recompiled = was_recompiled;
			communication.buffer = user_buffer;
			communication.buffer_size = 1000;
			update(&communication);
			if (communication.stop != 0)
				break;

			if (communication.request_recompile != 0)
				force_recompile = 1;
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

LONG exception_handler(LPEXCEPTION_POINTERS p)
{
	FATAL(0, "Exception!!!\n");
	return EXCEPTION_EXECUTE_HANDLER;
}

void _start()
{
	SetUnhandledExceptionFilter((LPTOP_LEVEL_EXCEPTION_FILTER)&exception_handler);
	handle_commandline_arguments();
}

void _runmain() { _start(); }

#endif // SOURCE

///////////////////////////////////////////////////////////////////////////////

#ifdef DLL

#include <stdio.h>
#include <windows.h>

#define SEGMENT_NAME "dll"
#define FATAL(x, ...) do { if (x) break; fprintf(stderr, "%s:%d: (" SEGMENT_NAME "/%s) FATAL: ", __FILE__, __LINE__, __FUNCTION__); fprintf(stderr, __VA_ARGS__ ); fprintf(stderr, "\n(%s)\n", #x); void exit(int); exit(1); } while(0)

// Have this up here to prevent moving the function address due to resizing other functions when recompiling.
LRESULT CALLBACK window_message_handler(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	extern int window_message_handler_impl(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);
	return window_message_handler_impl(hWnd, message, wParam, lParam);
}

int _dllstart()
{
	static int started = 0;
	if (!started)
	{

		printf("Starting dll!\n");
		started = 1;
	}
	else
	{
		printf("_dllstart() called: %dth time\n", started + 1);
		started += 1;
	}
	return 1;
}

typedef struct
{
	int initialized;
	unsigned tick;
	HWND hWnd;
	int x, y;
	int window_closed;
	unsigned long long old_window_proc;
} State;
enum { StateInitializedMagicNumber = 12347 };

#define WINDOW_CREATION_ENABLED 1

void paint(HWND hWnd, State* state)
{
	PAINTSTRUCT ps;
	HDC hdc = BeginPaint(hWnd, &ps);

	HDC hdcMem = CreateCompatibleDC(hdc);
	HBITMAP hbm = CreateCompatibleBitmap(hdc, 1, 1);
	HGDIOBJ hOld = SelectObject(hdcMem, hbm);

	SetPixel(hdcMem, 0, 0, RGB(255, 0, 0));

	if (state)
	{
		for (int x = state->x - 50; x < state->x + 50; ++x)
			BitBlt(hdc, x, state->y, 1, 1, hdcMem, 0, 0, SRCCOPY);
		for (int y = state->y - 50; y < state->y + 50; ++y)
			BitBlt(hdc, state->x, y, 1, 1, hdcMem, 0, 0, SRCCOPY);
	}

	SelectObject(hdcMem, hOld);
	DeleteObject(hbm);
	DeleteDC(hdcMem);

	EndPaint(hWnd, &ps);
}

int window_message_handler_impl(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
		case WM_CREATE:
		{
			if (!SetWindowPos(hWnd, NULL, 2000, 70, 0, 0, SWP_NOSIZE | SWP_NOZORDER))
				FATAL(0, "Failed to position window. Error: ", GetLastError());

			CREATESTRUCT *pCreate = (CREATESTRUCT*)lParam;
			State* state = (State*)pCreate->lpCreateParams;
			FATAL(state->initialized == StateInitializedMagicNumber, "State not initialized in message loop.");
			SetLastError(0);
			if (!SetWindowLongPtr(hWnd, GWLP_USERDATA, (LONG_PTR)state) && GetLastError() != 0)
				printf("State set failed. Error: %d\n", GetLastError());

			break;
		}
		case WM_PAINT:
		{
			printf("WM_PAINT");
			State *state = (State*)GetWindowLongPtr(hWnd, GWLP_USERDATA);
			if (!state)
				printf("No state.\n");

			paint(hWnd, state);
			break;
		}
		case WM_KEYDOWN:
		{
			WORD keyFlags = HIWORD(lParam);
			WORD repeatCount = LOWORD(lParam);
			if ((keyFlags & KF_REPEAT) != KF_REPEAT)
			{
				printf("*click* *whrrrrrrrr*\n");
				extern int take_screenshot(HWND);
				take_screenshot(hWnd);
			}
			else
			{
				printf("Key repeat. Repeat count since last handled message: %d\n", LOWORD(lParam));
			}
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
		case WM_DESTROY:
		{
			//PostQuitMessage(0);
			State *state = (State*)GetWindowLongPtr(hWnd, GWLP_USERDATA);
			if (state)
				state->window_closed = 1;
			// fallthrough
		}
		default:
			printf("%x\n", message);
			return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}

int take_screenshot(HWND hWnd)
{
	HDC hdcScreen;
	HDC hdcWindow;
	HDC hdcMemDC = NULL;
	HBITMAP hbmScreen = NULL;
	BITMAP bmpScreen;
	DWORD dwBytesWritten = 0;
	DWORD dwSizeofDIB = 0;
	HANDLE hFile = NULL;
	char* lpbitmap = NULL;
	HANDLE hDIB = NULL;
	DWORD dwBmpSize = 0;

	// Retrieve the handle to a display device context for the client 
	// area of the window. 
	hdcScreen = GetDC(NULL);
	hdcWindow = GetDC(hWnd);

	// Create a compatible DC, which is used in a BitBlt from the window DC.
	hdcMemDC = CreateCompatibleDC(hdcWindow);

	if (!hdcMemDC)
	{
		MessageBox(hWnd, TEXT("CreateCompatibleDC has failed"), TEXT("Failed"), MB_OK);
		goto done;
	}

	// Get the client area for size calculation.
	RECT rcClient;
	GetClientRect(hWnd, &rcClient);

	// This is the best stretch mode.
	SetStretchBltMode(hdcWindow, HALFTONE);

	// The source DC is the entire screen, and the destination DC is the current window (HWND).
	if (!StretchBlt(hdcWindow,
		0, 0,
		rcClient.right, rcClient.bottom,
		hdcScreen,
		0, 0,
		GetSystemMetrics(SM_CXSCREEN),
		GetSystemMetrics(SM_CYSCREEN),
		SRCCOPY))
	{
		MessageBox(hWnd, TEXT("StretchBlt has failed"), TEXT("Failed"), MB_OK);
		goto done;
	}

	// Create a compatible bitmap from the Window DC.
	hbmScreen = CreateCompatibleBitmap(hdcWindow, rcClient.right - rcClient.left, rcClient.bottom - rcClient.top);

	if (!hbmScreen)
	{
		MessageBox(hWnd, TEXT("CreateCompatibleBitmap Failed"), TEXT("Failed"), MB_OK);
		goto done;
	}

	// Select the compatible bitmap into the compatible memory DC.
	SelectObject(hdcMemDC, hbmScreen);

	// Bit block transfer into our compatible memory DC.
	if (!BitBlt(hdcMemDC,
		0, 0,
		rcClient.right - rcClient.left, rcClient.bottom - rcClient.top,
		hdcWindow,
		0, 0,
		SRCCOPY))
	{
		MessageBox(hWnd, TEXT("BitBlt has failed"), TEXT("Failed"), MB_OK);
		goto done;
	}

	// Get the BITMAP from the HBITMAP.
	GetObject(hbmScreen, sizeof(BITMAP), &bmpScreen);

	BITMAPFILEHEADER bmfHeader;
	BITMAPINFOHEADER bi;

	bi.biSize = sizeof(BITMAPINFOHEADER);
	bi.biWidth = bmpScreen.bmWidth;
	bi.biHeight = bmpScreen.bmHeight;
	bi.biPlanes = 1;
	bi.biBitCount = 32;
	bi.biCompression = BI_RGB;
	bi.biSizeImage = 0;
	bi.biXPelsPerMeter = 0;
	bi.biYPelsPerMeter = 0;
	bi.biClrUsed = 0;
	bi.biClrImportant = 0;

	dwBmpSize = ((bmpScreen.bmWidth * bi.biBitCount + 31) / 32) * 4 * bmpScreen.bmHeight;

	// Starting with 32-bit Windows, GlobalAlloc and LocalAlloc are implemented as wrapper functions that 
	// call HeapAlloc using a handle to the process's default heap. Therefore, GlobalAlloc and LocalAlloc 
	// have greater overhead than HeapAlloc.
	hDIB = GlobalAlloc(GHND, dwBmpSize);
	lpbitmap = (char*)GlobalLock(hDIB);

	// Gets the "bits" from the bitmap, and copies them into a buffer 
	// that's pointed to by lpbitmap.
	GetDIBits(hdcWindow, hbmScreen, 0,
		(UINT)bmpScreen.bmHeight,
		lpbitmap,
		(BITMAPINFO*)&bi, DIB_RGB_COLORS);

	// A file is created, this is where we will save the screen capture.
	hFile = CreateFile(TEXT("captureqwsx.bmp"),
		GENERIC_WRITE,
		0,
		NULL,
		CREATE_ALWAYS,
		FILE_ATTRIBUTE_NORMAL, NULL);

	// Add the size of the headers to the size of the bitmap to get the total file size.
	dwSizeofDIB = dwBmpSize + sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);

	// Offset to where the actual bitmap bits start.
	bmfHeader.bfOffBits = (DWORD)sizeof(BITMAPFILEHEADER) + (DWORD)sizeof(BITMAPINFOHEADER);

	// Size of the file.
	bmfHeader.bfSize = dwSizeofDIB;

	// bfType must always be BM for Bitmaps.
	bmfHeader.bfType = 0x4D42; // BM.

	WriteFile(hFile, (LPSTR)&bmfHeader, sizeof(BITMAPFILEHEADER), &dwBytesWritten, NULL);
	WriteFile(hFile, (LPSTR)&bi, sizeof(BITMAPINFOHEADER), &dwBytesWritten, NULL);
	WriteFile(hFile, (LPSTR)lpbitmap, dwBmpSize, &dwBytesWritten, NULL);

	// Unlock and Free the DIB from the heap.
	GlobalUnlock(hDIB);
	GlobalFree(hDIB);

	// Close the handle for the file that was created.
	CloseHandle(hFile);

	// Clean up.
done:
	DeleteObject(hbmScreen);
	DeleteObject(hdcMemDC);
	ReleaseDC(NULL, hdcScreen);
	ReleaseDC(hWnd, hdcWindow);

	return 0;
}

void create_window(State* state)
{
	state->old_window_proc = (unsigned long long)window_message_handler;

	WNDCLASSEX wcex;
	memset(&wcex, 0, sizeof(WNDCLASSEX));
	wcex.cbSize = sizeof(WNDCLASSEX);
	wcex.style = CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc = window_message_handler;
	wcex.hInstance = GetModuleHandle(NULL);
	wcex.hCursor = LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
	wcex.lpszClassName = "MyWindowClass";
	RegisterClassEx(&wcex);

	RECT rc = { 0, 0, 400, 300 };
	AdjustWindowRect(&rc, WS_OVERLAPPEDWINDOW, FALSE);

	// TODO: No hardcoded name. Get the name of the executable from commandline arguments.
	state->hWnd = CreateWindow("MyWindowClass", GetCommandLine(), WS_OVERLAPPEDWINDOW,
		CW_USEDEFAULT, CW_USEDEFAULT, rc.right - rc.left, rc.bottom - rc.top,
		NULL, NULL, GetModuleHandle(NULL), state);
	ShowWindow(state->hWnd, SW_SHOW);
}

int poll_messages(State* state)
{
	if (!state->hWnd)
		return 0;

	MSG msg;
	while (PeekMessage(&msg, state->hWnd, 0, 0, 0))
	{
		if (GetMessage(&msg, state->hWnd, 0, 0))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
		else
		{
			printf("!GetMessage -> %d\n", (int)msg.wParam);
			return 1;
		}
	}
	return 0;
}

static void setup(State* state)
{
	if (state->initialized == StateInitializedMagicNumber)
	{
		FATAL(state->old_window_proc == (unsigned long long)window_message_handler, "Window message handler function address moved. 0x%X == 0x%X\n", state->old_window_proc, (unsigned long long)window_message_handler);
		return;
	}

	printf("Init state.\n");
	memset(state, 0, sizeof(*state));
	state->initialized = StateInitializedMagicNumber;
	state->tick = 0;
	state->x = 200;
	state->y = 150;

	create_window(state);

	take_screenshot(state->hWnd);

	printf("\n\nGo to the `update` function at the bottom of this source file and edit the `state->x` and `state->y` variable assignments or something, and see what happens. :)\n\n");
}

__declspec(dllexport) void update(Communication* communication)
{
	FATAL(sizeof(State) <= communication->buffer_size, "State is larger than the buffer. %lld <= %lld", sizeof(State), communication->buffer_size);

	State* state = (State*)communication->buffer;
	setup(state);

	state->tick += 1;
	if (state->tick % 100 == 0)
		printf("update(%5d)\n", state->tick);

	// Modify these, save and note the cross being repainted to a different spot
	state->x = 200;
	state->y = 150;

	if (state->hWnd && communication->was_recompiled)
		RedrawWindow(state->hWnd, NULL, NULL, RDW_INVALIDATE);

	if (poll_messages(state) != 0)
		communication->stop = 1;

	if (state->window_closed)
		communication->stop = 1;

	Sleep(16);
}

#endif // DLL

