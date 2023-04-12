: " This is the beginning of a multiline comment in sh and a valid label in batch.
@goto batch_bootstrap_builder "
if false; then */
#error Remember to insert "#if 0" into the compiler input pipe or skip the first 6 lines when compiling this file.
// Notepad++ run command: cmd /c 'cd /d $(CURRENT_DIRECTORY) &amp;&amp; $(FULL_CURRENT_PATH)'
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

// Outputs a *_preprocessed.bat which has identical functionality to the original .bat but has all of the #includes (and macros) baked in
static const int b_create_preprocessed_builder = 0;

// Outputs a .c from the SOURCE section
static const int b_create_c_file = 0;

// Outputs a .exe from the SOURCE section
static const int b_create_exe_file = 0;

// Outputs a .dll file from the DLL section
static const int b_create_dll_file = 0;

// Runs the program built from SOURCE section. Uses "tcc -run" unless b_create_exe_file is enabled in which case the exe file will be ran
static const int b_run_after_build = 1;

// Enables some extra logging during build
static const int b_verbose = 1;

// Arguments passed to the program built from SOURCE
static const char* b_run_arguments = "--dll --!print_source --!create_builder --!help";

// Compiler arguments for building the SOURCE and DLL sections
static const char* b_compiler_arguments = "-Iinclude -Iinclude/winapi -nostdlib -nostdinc -lmsvcrt -lkernel32 -luser32 -lgdi32";

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

int compile_and_run(const char* output_c)
{
	snprintf(buffer, sizeof(buffer), "%s %s %s -run", b_compiler_executable_path, output_c, b_compiler_arguments);
	int result = system(buffer);
	FATAL(result == 0, "Error while compiling '%s'. Error value: %d", output_c, result);
	return result;
}

FILE* create_compilation_process(const char* run_arguments)
{
	int run_immediately = !b_create_exe_file && b_run_after_build;
	if (run_immediately)
		snprintf(buffer, sizeof(buffer), "%s %s -run -x c - %s %s", b_compiler_executable_path, b_compiler_arguments, b_output_exe_filename, run_arguments);
	else
		snprintf(buffer, sizeof(buffer), "%s %s -x c - -o %s", b_compiler_executable_path, b_compiler_arguments, b_output_exe_filename);

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

		insert_snippet(0, "#ifdef BUILDER", infile, out, 0, 0);
		fputs("#ifdef BUILDER\n", out);

		{
			const char temp_filename[] = "temp_builder_file_to_preprocess.c";
			FILE* temp_file = fopen(temp_filename, "w");
			fseek(infile, 0, SEEK_SET);

			insert_snippet("#ifdef BUILDER", "#endif // BUILDER", infile, temp_file, 0, 0);
			int err = fclose(temp_file);
			FATAL(err == 0, "Failed to preprocess builder.");

			if (b_verbose) printf("Creating preprocessor for BUILDER\n");
			FILE* preprocessor_result = create_preprocessor_process(temp_filename);

			{
				// Skip first line as it's the #line directive with the temp_filename
				fgets(buffer, sizeof(buffer), preprocessor_result);
			}

			insert_snippet(0, "static const int b_create_preprocessed_builder = 1;", preprocessor_result, out, 0, 0);
			fputs("static const int b_create_preprocessed_builder = 0;\n", out);

			while (fgets(buffer, sizeof(buffer), preprocessor_result))
				fputs(buffer, out);
			err = pclose(preprocessor_result);
			FATAL(err == 0, "Failed to preprocess builder.");

			remove(temp_filename);

			fputs("#endif // BUILDER\n", out);
		}

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
			fputs("#ifdef ORIGINAL_BUILDER\n", out);

			insert_snippet("#ifdef BUILDER", "#endif // BUILDER", infile, out, 0, 0);
			fputs("\n#endif // ORIGINAL_BUILDER\n", out);
		}

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

	if (b_create_dll_file)
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

	if (b_create_c_file || b_create_exe_file || b_run_after_build)
	{
		FILE* infile = fopen(b_source_filename, "r");
		FILE* outfile = b_create_c_file ? fopen(b_output_c_filename, "w") : create_compilation_process(b_run_arguments);

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
					FATAL(0, "Failed to compile created '%s'.", b_output_c_filename);
			}
			else if (b_run_after_build)
			{
				int err = compile_and_run(b_output_c_filename);
				if (err != 0)
					FATAL(0, "Error encountered while doing compile&run for created '%s'.", b_output_c_filename);
			}
		}
		else
		{
			int err = pclose(outfile);
			if (b_run_after_build && !b_create_exe_file)
				FATAL(err == 0, "Run-after-build finished with errors. Error code: %d", err);
			else
				FATAL(err == 0, "Failed to close compiler pipe. Error code: %d", err);
		}
	}

	if (b_create_exe_file && b_run_after_build)
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
#include <time.h>

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

enum { debug_printing_verbose = 0 };

size_t scan_includes(const char* source_file, char** files_to_watch, size_t files_to_watch_count, size_t written)
{
	if (debug_printing_verbose)
		printf("scan_includes('%s', %lld)\n", source_file, written);

	char buffer[1024] = {0};

	size_t first_written = written;
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

		char* existing_file = files_to_watch[written];
		if (existing_file == 0 || strncmp(existing_file, begin, end - begin) != 0)
		{
			extern void free(void*);
			extern void* malloc(size_t);
			if (existing_file != 0)
				free(existing_file);

			size_t length = end - begin;
			existing_file = (char*)malloc(length);
			strncpy(existing_file, begin, length);
			existing_file[length] = 0;

			printf("Watching '%s' for changes.\n", existing_file);

			files_to_watch[written] = existing_file;
		}
		written += 1;
	}
	fclose(infile);

	for (size_t i = first_written, end = written; i < end; ++i)
	{
		written = scan_includes(files_to_watch[i], files_to_watch, files_to_watch_count, written);
	}

	return written;
}

size_t find_corresponding_source_files(const char** includes, size_t includes_count, char** sources, size_t sources_count, size_t written_sources)
{
	if (debug_printing_verbose)
		printf("find_corresponding_source_files(%lld, %lld)\n", includes_count, written_sources);

	char buffer[1024] = {0};
	for (int i = 0; i < includes_count && written_sources < sources_count; ++i)
	{
		printf("checking '%s'\n", includes[i]);
		strcpy(buffer, includes[i]);
		char* ext = strstr(buffer, ".h");
		if (!ext)
			continue;

		ext[1] = 'c';

		char* existing_file = sources[written_sources];
		if (existing_file != 0 && strcmp(existing_file, buffer) == 0)
		{
			written_sources += 1;
			continue;
		}

		struct stat dummy;
		if (stat(buffer, &dummy) == 0)
		{
			extern void free(void*);
			extern void* malloc(size_t);
			if (existing_file != 0)
				free(existing_file);

			existing_file = (char*)malloc(strlen(buffer));
			strcpy(existing_file, buffer);

			sources[written_sources] = existing_file;
			written_sources += 1;
		}
	}

	return written_sources;
}

struct headers_and_sources {
	const char* headers[256];
	const char* sources[256];
	size_t sources_count;
	size_t headers_count;
};

void get_headers_and_sources(const char* main_source_file, struct headers_and_sources* headers_and_sources)
{
	size_t headers_buffer_size = sizeof(headers_and_sources->headers) / sizeof(headers_and_sources->headers[0]);
	size_t sources_buffer_size = sizeof(headers_and_sources->sources) / sizeof(headers_and_sources->sources[0]);
	headers_and_sources->sources[0] = main_source_file;
	headers_and_sources->sources_count = 1;
	headers_and_sources->headers_count = 0;
	for (size_t i = 0; i < headers_and_sources->sources_count; ++i)
	{
		const char* source = headers_and_sources->sources[i];
		if (debug_printing_verbose)
			printf("Scanning '%s'\n", source);

		size_t prev_headers_count = headers_and_sources->headers_count;

		headers_and_sources->headers_count
			= scan_includes(
				source,
				headers_and_sources->headers,
				headers_buffer_size,
				headers_and_sources->headers_count);

		headers_and_sources->sources_count
			= find_corresponding_source_files(
				headers_and_sources->headers + prev_headers_count,
				headers_and_sources->headers_count - prev_headers_count,
				headers_and_sources->sources,
				sources_buffer_size,
				headers_and_sources->sources_count);
	}
}

int is_anything_newer_than(const char* executable_file, struct headers_and_sources* headers_and_sources)
{
	for (size_t i = 0; i < headers_and_sources->sources_count; ++i)
	{
		if (cmp_modified_times(executable_file, headers_and_sources->sources[i]) < 0)
		{
			printf("Timestamp of '%s' was newer than '%s'\n", headers_and_sources->sources[i], dll_filename);
			return 1;
		}
	}

	for (size_t i = 0; i < headers_and_sources->headers_count; ++i)
	{
		if (cmp_modified_times(executable_file, headers_and_sources->headers[i]) < 0)
		{
			printf("Timestamp of '%s' was newer than '%s'\n", headers_and_sources->headers[i], dll_filename);
			return 1;
		}
	}

	return 0;
}

void handle_commandline_arguments()
{
	char* command_line = GetCommandLine();
	char* runtime_arguments_after = strstr(command_line, " - ");
	if (runtime_arguments_after)
		command_line = runtime_arguments_after + 3;

	if (debug_printing_verbose)
		printf("%s\n", command_line);

	{
		int len = 0;
		int err = sscanf(command_line, "%s%n", exe_filename, &len);
		FATAL(err == 1, "Failed to get filename from GetCommandLine(): '%s', err: %d", command_line, err);

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

	if (strstr(command_line, " -h") || strstr(command_line, "--help"))
	{
	}
	else if (strstr(command_line, "--print_source"))
	{
		extern const char* b_source_string;
		printf("%s", b_source_string);

		finished();
	}
	else if (strstr(command_line, "--create_builder"))
	{
		FILE* out = fopen(bat_new_filename, "w");
		FATAL(out, "Failed to get filename from GetCommandLine(): '%s'", command_line);

		extern const char* b_source_string;
		fputs(b_source_string, out);
		int err = fclose(out);
		FATAL(err == 0, "Failed to close file '%s'. Error code: %d", bat_new_filename, err);

		finished();
	}
	else if(strstr(command_line, "--dll"))
	{
		void* malloc(size_t);
		struct headers_and_sources* headers_and_sources = (struct headers_and_sources*)malloc(sizeof(struct headers_and_sources));
		memset(headers_and_sources, 0, sizeof(*headers_and_sources));
		get_headers_and_sources(bat_filename, headers_and_sources);

		void* user_buffer = malloc(1000);
		int force_recompile = 0;

		HMODULE hModule = LoadLibrary(dll_filename);
		if (!hModule)
		{
			force_recompile = 1;
			printf("Couldn't load '%s'. Forcing recompile.\n", dll_filename);
		}

		for (;;)
		{
			int was_recompiled = 0;

			if (!force_recompile && is_anything_newer_than(dll_filename, headers_and_sources))
				force_recompile = 1;

			if (force_recompile)
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
				replace(b_source_string, "b_create_exe_file = 1;", "b_create_exe_file = 0;");
				replace(b_source_string, "b_create_dll_file = 0;", "b_create_dll_file = 1;");
				replace(b_source_string, "b_verbose = 1;", "b_verbose = 0;");
				replace(b_source_string, "b_run_after_build = 1;", "b_run_after_build = 0;");

				clock_t c = clock();

				FILE* compiler_pipe = popen("tcc.exe - -run -nostdlib -lmsvcrt -nostdinc -Iinclude -Iinclude/winapi", "w");
				fprintf(compiler_pipe, prefix, bat_filename, dll_filename, bat_filename); 
				fputs(b_source_string, compiler_pipe);

				int err = pclose(compiler_pipe);
				if (err != 0)
				{
					fprintf(stderr, "Failed to recompile %s using included source code.\n", dll_filename);
					Sleep(2000);
					continue;
				}

				clock_t milliseconds = (clock() - c) * (1000ull / CLOCKS_PER_SEC);
				printf("Recompilation took: %lld.%03lld s\n", milliseconds/1000ull, milliseconds%1000ull);

				hModule = LoadLibrary(dll_filename);
				if (!hModule)
				{
					fprintf(stderr, "Error while loading %s. Error: 0x%X\n", dll_filename, GetLastError());
					Sleep(5000);
					continue;
				}

				get_headers_and_sources(bat_filename, headers_and_sources);

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
		printf("\n" "    --dll\t\tCreates a runtime recompilation loop that reacts to changes in the '%s' file.", bat_filename);
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
#include <time.h>

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
	if (!BitBlt(hdcMemDC, 0, 0,
		rcClient.right - rcClient.left, rcClient.bottom - rcClient.top,
		hdcWindow, 0, 0, SRCCOPY))
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
	hFile = CreateFile(TEXT("screenshot.bmp"),
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

enum { TetrisWidth = 10, TetrisHeight = 22 };
typedef enum { PieceL, PieceJ, PieceI, PieceO, PieceT, PieceS, PieceZ } PieceType;

typedef struct
{
	PieceType type;
	int rotation;
	int x, y;
} TetrisPiece;

typedef signed long long i64;
typedef struct
{
	int magic_number;
	TetrisPiece current_piece;
	unsigned char board[TetrisWidth * TetrisHeight];
	int lines_cleared;
	int score;
	i64 current_time_us;
	i64 fall_timer;
	int game_over;
	int input_left;
	int input_right;
	int input_down;
	int input_rotate;
	int input_drop;
} Tetris;

typedef struct
{
	HWND hWnd;
	int initialized;
	int redraw_requested;
	int window_closed;
	unsigned tick;
	int x, y;
	unsigned long long old_window_proc;

	Tetris tetris;
} State;
enum { StateInitializedMagicNumber = 123456 };

typedef struct
{
	PAINTSTRUCT ps;
	HDC screen_device_context;
	HDC hdc;
	HBITMAP bitmap;
	HGDIOBJ previous_gdi_object;
	int screen_width;
	int screen_height;
} Drawer;

Drawer make_drawer(HWND hWnd)
{
	Drawer drawer;

	RECT screen_rect;
	GetClientRect(hWnd, &screen_rect);
	drawer.screen_width = screen_rect.right;
	drawer.screen_height = screen_rect.bottom;

	drawer.screen_device_context = BeginPaint(hWnd, &drawer.ps);
	drawer.hdc = CreateCompatibleDC(drawer.screen_device_context);
	drawer.bitmap = CreateCompatibleBitmap(drawer.screen_device_context, drawer.screen_width, drawer.screen_height);
	drawer.previous_gdi_object = SelectObject(drawer.hdc, drawer.bitmap);
	return drawer;
}

void free_drawer(HWND hWnd, Drawer drawer)
{
	BitBlt(drawer.screen_device_context, 0, 0, drawer.screen_width, drawer.screen_height, drawer.hdc, 0, 0, SRCCOPY);

	SelectObject(drawer.hdc, drawer.previous_gdi_object);
	DeleteObject(drawer.bitmap);
	DeleteDC(drawer.hdc);
	ReleaseDC(hWnd, drawer.screen_device_context);
	EndPaint(hWnd, &drawer.ps);
}

void pixel(Drawer drawer, int x, int y, int r, int g, int b)
{
	int success = SetPixel(drawer.hdc, x, y, RGB(r, g, b));
	//if (success < 0)
	//	fprintf(stderr, "Failed to set pixel to color. (%d, %d) -> (%d,%d,%d)", x,y, r,g,b);
}

void rect(Drawer drawer, int x, int y, int w, int h, int r, int g, int b)
{
	RECT rect = {x, y, x+w, y+h};
	HBRUSH brush = CreateSolidBrush(RGB(r,g,b));
	int success = FillRect(drawer.hdc, &rect, brush);
	if (success < 0)
		fprintf(stderr, "Failed to draw a rectangle. (%d, %d, %d, %d)", x,y, w,h);
	DeleteObject(brush);
}

void fill(Drawer drawer, int r, int g, int b)
{
	int w = GetDeviceCaps(drawer.hdc, HORZRES);
	int h = GetDeviceCaps(drawer.hdc, VERTRES);
	rect(drawer, 0,0, w,h, r,g,b);
}

void text(Drawer drawer, int x, int y, char* str, int strLen)
{
	RECT rect = {x, y, x, y};
	DrawTextExA(drawer.hdc, str, strLen, &rect, DT_NOCLIP|DT_NOPREFIX|DT_SINGLELINE|DT_CENTER|DT_VCENTER, 0);
}

void text_w(Drawer drawer, int x, int y, wchar_t* str, int strLen)
{
	RECT rect = {x, y, x, y};
	DrawTextExW(drawer.hdc, str, strLen, &rect, DT_NOCLIP|DT_NOPREFIX|DT_SINGLELINE|DT_CENTER|DT_VCENTER, 0);
}

i64 microseconds()
{
	clock_t c = clock();
	return ((i64)c) * (1000000ull / CLOCKS_PER_SEC);
}

void tetris_draw(Drawer drawer, Tetris* tetris);

void paint(HWND hWnd, State* state)
{
	Drawer drawer = make_drawer(hWnd);

	fill(drawer, 255, 255, 255);
	rect(drawer, 20, 20, 200, 200, 255, 255, 0);

	if (state)
	{
		for (int x = state->x - 50; x < state->x + 50; ++x)
			pixel(drawer, x, state->y, 255, 0, 0);

		rect(drawer, state->x, state->y - 50, 1, 100, 0, 0, 255);
	}

	text(drawer, 30, 30, "Hello, World!", -1);
	text_w(drawer, 30, 60, L"Hëllö, Wärld!", -1);

	tetris_draw(drawer, &state->tetris);

	free_drawer(hWnd, drawer);
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

			return 0;
		}
		case WM_ERASEBKGND:
			//printf("WM_ERASEBKGND\n");
			break;
		case WM_SETREDRAW:
			printf("WM_SETREDRAW\n");
			break;
		case WM_PAINT:
		{
			//printf("WM_PAINT\n");
			State* state = (State*)GetWindowLongPtr(hWnd, GWLP_USERDATA);
			if (!state)
				printf("No state.\n");

			paint(hWnd, state);
			return 1;
		}
		case WM_KEYDOWN:
		{
			if (wParam == VK_ESCAPE)
			{
				printf("VK_ESCAPE\n");
				DestroyWindow(hWnd);
				return 0;
			}

			State *state = (State*)GetWindowLongPtr(hWnd, GWLP_USERDATA);
			switch (wParam)
			{
				case VK_LEFT:
					state->tetris.input_left = 1;
					return 0;
				case VK_RIGHT:
					state->tetris.input_right = 1;
					return 0;
				case VK_DOWN:
					state->tetris.input_down = 1;
					return 0;
				case VK_UP:
					state->tetris.input_rotate = 1;
					return 0;
				case VK_SPACE:
					state->tetris.input_drop = 1;
					return 0;
			}

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
			break;
		}
		case WM_QUIT:
			printf("WM_QUIT\n");
			break;
		case WM_DESTROY:
		{
			printf("WM_DESTROY\n");
			//PostQuitMessage(0);
			State *state = (State*)GetWindowLongPtr(hWnd, GWLP_USERDATA);
			if (state)
				state->window_closed = 1;
			// fallthrough
		}
		default:
			//printf("%x\n", message);
			break;
	}
	return DefWindowProc(hWnd, message, wParam, lParam);
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
	while (PeekMessage(&msg, state->hWnd, 0, 0, PM_REMOVE))
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	return 0;
}

void get_block_offsets(PieceType piece_type, int rotation, int* out_offsets_x, int* out_offsets_y)
{
	//                     PieceL,  PieceJ,  PieceI, PieceO, PieceT,  PieceS,  PieceZ
	int offsets_x[7*3] = {-1,-1,1,  1,-1,1, -1,1,2,  1,0,1,  1,-1,0,  1,0,-1, -1,0,1};
	int offsets_y[7*3] = { 1, 0,0,  1, 0,0,  0,0,0,  0,1,1,  0, 0,1,  0,1, 1,  0,1,1};

	//                       L, J, I, O, T, S, Z
	int rotation_counts[] = {4, 4, 2, 1, 4, 2, 2};

	out_offsets_x[0] = out_offsets_y[0] = 0;
	for (int i = 1; i < 4; ++i)
	{
		out_offsets_x[i] = offsets_x[piece_type * 3 + i-1];
		out_offsets_y[i] = offsets_y[piece_type * 3 + i-1];
	}

	rotation = rotation % rotation_counts[piece_type];
	for (int r = 0; r < rotation; ++r)
	{
		for (int i = 1; i < 4; ++i)
		{
			int temp = out_offsets_x[i];
			out_offsets_x[i] = -out_offsets_y[i];
			out_offsets_y[i] = temp;
		}
	}
}

void get_piece_blocks(TetrisPiece piece, int* out_piece_x, int* out_piece_y)
{
	int piece_offsets_x[4] = {0};
	int piece_offsets_y[4] = {0};
	get_block_offsets(piece.type, piece.rotation, piece_offsets_x, piece_offsets_y);

	for (int i = 0; i < 4; ++i)
	{
		out_piece_x[i] = piece.x + piece_offsets_x[i];
		out_piece_y[i] = piece.y + piece_offsets_y[i];
	}
}

void get_tetris_color(int tile_color, int* r, int* g, int* b)
{
	int x = 170, y = 70, z = 110;
	switch(tile_color)
	{
	case 0: *r = *g = *b = 0; return;
	case 1: *r = x; *g = *b = y; return;
	case 2: *g = x; *r = *b = y; return;
	case 3: *b = x; *r = *g = y; return;
	case 4: *r = *b = x; *g = y; return;
	case 5: *g = *r = x; *b = y; return;
	case 6: *b = *g = x; *r = y; return;
	case 7: *b = *r = *g = z; return;
	}
}

int move_piece_to(TetrisPiece* piece, Tetris* tetris, int x, int y, int r)
{
	int offsets_x[4];
	int offsets_y[4];
	get_block_offsets(piece->type, piece->rotation + r, offsets_x, offsets_y);

	for (int i = 0; i < 4; ++i)
	{
		int xx = piece->x + x + offsets_x[i];
		int yy = piece->y + y + offsets_y[i];
		if (xx < 0 || xx >= TetrisWidth)
			return 0;
		if (yy >= TetrisHeight)
			return 0;
		if (yy < 0)
			continue;

		if (tetris->board[xx + yy * TetrisWidth])
			return 0;
	}

	piece->rotation += r;
	piece->x += x;
	piece->y += y;
	return 1;
}

int move_to(Tetris* tetris, int x, int y, int r)
{
	return move_piece_to(&tetris->current_piece, tetris, x, y, r);
}

void tetris_draw(Drawer drawer, Tetris* tetris)
{
	RECT screen_rect;
	GetClientRect(WindowFromDC(drawer.screen_device_context), &screen_rect);
	int screen_height = screen_rect.bottom - screen_rect.top;
	int h = (screen_height - 20) / TetrisHeight;
	int w = h;
	int margin = w/2;
	rect(drawer, 0, 0, w * TetrisWidth + margin*2, w * TetrisHeight + margin*2, 70,10,50);

	TetrisPiece shadow_piece = tetris->current_piece;
	while (move_piece_to(&shadow_piece, tetris, 0, 1, 0)) {}

	int piece_x[4] = {0};
	int piece_y[4] = {0};
	get_block_offsets(tetris->current_piece.type, tetris->current_piece.rotation, piece_x, piece_y);
	for (int i = 0; i < 4; ++i)
	{
		piece_x[i] += tetris->current_piece.x;
		piece_y[i] += tetris->current_piece.y;
	}

	for (int y = 0; y < TetrisHeight; ++y)
	{
		for (int x = 0; x < TetrisWidth; ++x)
		{
			int tile_color = tetris->board[y * TetrisWidth + x];
			int piece_hit = 0;
			int shadow_hit = 0;
			int shadow_piece_hit = 0;

			for (int i = 0; i < 4; ++i)
			{
				if (piece_x[i] != x || piece_y[i] > y)
					continue;

				int shadow_y = piece_y[i] - tetris->current_piece.y + shadow_piece.y;
				if (piece_y[i] == y)
					piece_hit = 1;
				else if (shadow_y == y)
					shadow_piece_hit = 1;
				else if (shadow_y > y)
					shadow_hit = 1;
				else
					continue;

				tile_color = tetris->current_piece.type + 1;
			}

			int r,g,b;
			get_tetris_color(tile_color, &r,&g,&b);
			int divider = 1;
			if (piece_hit)
				divider = 1;
			else if (shadow_piece_hit)
				divider = 2;
			else if (shadow_hit)
				divider = 3;

			r/=divider; g/=divider; b/=divider;

			rect(drawer, x * w + margin, y * h + margin, w, h, r,g,b);
		}
	}

	char score_buffer[32];
	sprintf(score_buffer, "%d", tetris->score);
	text(drawer, drawer.screen_width / 2, 30, score_buffer, -1);

	if (tetris->game_over)
		text(drawer, drawer.screen_width / 2, 60, "Game Over!", -1);
}

int tetris_update(Tetris* tetris)
{
	if (tetris->magic_number != StateInitializedMagicNumber
		|| (tetris->game_over && tetris->input_drop))
	{
		memset(tetris, 0, sizeof *tetris);
		tetris->magic_number = StateInitializedMagicNumber;
		tetris->current_time_us =  microseconds();
		tetris->fall_timer = 1000 * 1000; // 1 second
		tetris->current_piece.x = 5;
		return 1;
	}

	if (tetris->game_over)
		return 0;

	{
		i64 t = microseconds();
		tetris->fall_timer -= t - tetris->current_time_us;
		//printf("fall: %lld, t: %lld, ct: %lld, -:%lld\n", tetris->fall_timer, t, tetris->current_time_us, t - tetris->current_time_us);
		tetris->current_time_us = t;
	}

	int move_left = tetris->input_left;
	int move_right = tetris->input_right;
	int move_down = tetris->input_down;
	int rotate = tetris->input_rotate;
	int drop = tetris->input_drop;
	tetris->input_left = tetris->input_right = tetris->input_down = tetris->input_rotate = tetris->input_drop = 0;

	int difficulty = 1 + tetris->lines_cleared / 10;
	i64 drop_delay = 1000 * 1000 / difficulty;
	if (drop)
	{
		tetris->fall_timer = drop_delay;
	}
	else if (move_down)
	{
		tetris->fall_timer = drop_delay;
		tetris->score += 1;
	}
	else if (tetris->fall_timer <= 0)
	{
		move_down = 1;
		tetris->fall_timer += drop_delay;
		if (tetris->fall_timer < 0)
			tetris->fall_timer = drop_delay; // No double drops if the game was paused etc.
	}

	if (rotate)
	{
		int i_piece_nudge = tetris->current_piece.type == PieceI && tetris->current_piece.x >= 8;

		move_to(tetris, 0,0,1)
		|| move_to(tetris,  1,0,1)
		|| move_to(tetris, -1,0,1)
		|| (i_piece_nudge && move_to(tetris, -2,0,1))
		|| move_to(tetris, 0,1,1);
	}

	if (move_left)
		move_to(tetris, -1,0,0);

	if (move_right)
		move_to(tetris, 1,0,0);

	if (drop)
	{
		while (move_to(tetris, 0,1,0))
			tetris->score += 1;
		move_down = 1;
	}

	if (move_down)
	{
		if (!move_to(tetris, 0,1,0))
		{
			int offsets_x[4];
			int offsets_y[4];
			get_block_offsets(tetris->current_piece.type, tetris->current_piece.rotation, offsets_x, offsets_y);

			// stick
			for (int i = 0; i < 4; ++i)
			{
				int x = tetris->current_piece.x + offsets_x[i];
				int y = tetris->current_piece.y + offsets_y[i];
				tetris->board[x + y * TetrisWidth] = tetris->current_piece.type + 1;
			}

			// destroy
			int clears = 0;
			for (int y = TetrisHeight; y-- > 0;)
			{
				int block_count = 0;
				for (int x = 0; x < TetrisWidth; ++x)
				{
					int val = tetris->board[x + y * TetrisWidth];
					if (val)
						block_count += 1;

					tetris->board[x + y * TetrisWidth] = 0;
					tetris->board[x + (y + clears) * TetrisWidth] = val;
				}

				if (block_count == 10)
					clears += 1;
			}

			// meta
			tetris->lines_cleared += clears;
			tetris->score += clears * clears * 100 * difficulty;

			// new piece
			tetris->current_piece.type = (tetris->current_piece.type + 1) % 7;
			tetris->current_piece.x = 5;
			tetris->current_piece.y = 0;
			tetris->current_piece.rotation = 0;

			if (!move_to(tetris, 0,0,0))
			{
				tetris->game_over = 1;
				printf("Game Over! Final Score: %d\n", tetris->score);
			}
		}
	}

	return move_down || move_left || move_right || move_down || rotate || drop;
}

static void setup(State* state)
{
	if (state->initialized == StateInitializedMagicNumber)
	{
		FATAL(state->old_window_proc == (unsigned long long)window_message_handler
			, "Window message handler function address moved. 0x%X == 0x%X\n"
			, state->old_window_proc, (unsigned long long)window_message_handler);
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

	printf("\n\nGo to the `tick` function at line %d of this source file and edit the 'state->x' and 'state->y' variables or something and see what happens. :)\n\n", __LINE__ + 3);
}

void tick(State* state)
{
	// Modify these, save and note the cross in the window being painted to a different spot
	state->x = 200;
	state->y = 100;

	if (tetris_update(&state->tetris))
		state->redraw_requested = 1;
}

__declspec(dllexport) void update(Communication* communication)
{
	FATAL(sizeof(State) <= communication->buffer_size, "State is larger than the buffer. %lld <= %lld", sizeof(State), communication->buffer_size);

	i64 t = microseconds();

	State* state = (State*)communication->buffer;
	setup(state);

	state->tick += 1;
	if (state->tick % 100 == 0)
		printf("update(%5d)\n", state->tick);

	tick(state);

	if (state->hWnd && (communication->was_recompiled || state->redraw_requested))
	{
		state->redraw_requested = 0;
		RedrawWindow(state->hWnd, NULL, NULL, RDW_INVALIDATE); // Add "|RDW_ERASE" to see the flicker that is currently hidden by double buffering the draw target.
	}

	if (poll_messages(state) != 0)
		communication->stop = 1;

	if (state->window_closed)
		communication->stop = 1;

	i64 d = microseconds() - t;
	printf("%lldms\r", (d/1000) % 1000);

	Sleep(16);
}

#endif // DLL

