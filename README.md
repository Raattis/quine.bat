# What
This is a single file "builder", C program and runtime recompilation loop
* Download and unzip [Tiny C Compiler](http://download.savannah.gnu.org/releases/tinycc/) (Tested with tcc-0.9.27-win64-bin.zip)
* Save quine.bat at `tcc/quine.bat`
* Run quine.bat
* Modify the `#ifdef DLL ... #endif // DLL` section while the program is running
* Note that the changes are being applied at runtime

# Linux
* `chmod +x quine.bat`
* `./quine.bat`
* Tweak the `b_create_exe_file` etc. options to prevent trying to compile Windows-only code. Maybe turn on `b_create_c_file` so you can see some output.

# Troubleshooting
If the DLL file cannot be overwritten while the program is running, Windows has this IgnoreFreeLibrary registry hack that prevents DLLs being unloaded during program execution even if FreeLibrary is called. Search online how to delete that registry entry. And apparently it can reappear after being deleted. In the future I might look into adding a mode where each new DLL file gets a unique name.
