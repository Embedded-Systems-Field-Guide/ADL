from tkinter import messagebox
import os


def on_compile_project():
    """
    Compile the current project.
    """
    # Import the main module to access global variables
    import sys
    ecf_module = sys.modules.get('__main__')

    if ecf_module is None:
        messagebox.showwarning("Error", "Could not access project state.")
        return

    current_project_dir = getattr(ecf_module, 'current_project_dir', None)
    current_project_name = getattr(ecf_module, 'current_project_name', None)

    if current_project_dir is None or current_project_name is None:
        messagebox.showwarning("No Project", "Please open or create a project first.")
        return

    # Get the project file path
    project_path = os.path.join(current_project_dir, f"{current_project_name}.ecfproj")

    print(f"Compiling project: {current_project_name}")
    print(f"Project path: {project_path}")

    try:
        # Import the compiler
        from core.compiler_main import ECFCompiler
        from core.output_generator import generate_output_files

        # Create compiler instance
        compiler = ECFCompiler()

        # Try to load and compile the project
        if compiler.load_project(project_path):
            # Success - show success message
            details = (f"Project: {compiler.project_settings.get('ProjectName', 'Unknown')}\n"
                       f"Loaded:\n"
                       f"• Write Addresses: {len(compiler.write_addresses)} entries\n"
                       f"• Read Addresses: {len(compiler.read_addresses)} entries\n"
                       f"• Instructions: {len(compiler.instructions)} entries\n\n")

            # Add debug file information if debug manager exists
            if hasattr(compiler, 'debug_manager') and compiler.debug_manager:
                debug_files = compiler.debug_manager.get_debug_files()
                if debug_files:
                    details += "Debug files created:\n"
                    for file in debug_files:
                        details += f"• {file.name}\n"

            # Generate output files from _IMPLEMENTED.txt
            implemented_file = os.path.join(current_project_dir, "Debug", f"{current_project_name}_IMPLEMENTED.txt")
            if os.path.exists(implemented_file):
                if generate_output_files(implemented_file, current_project_name, current_project_dir):
                    details += "\nOutput files generated:\n"
                    details += "• rom_data.h\n"
                    details += f"• {current_project_name}.ecfROM\n"
                    details += "• rom_data.mat\n"

            messagebox.showinfo("Compile Success",
                                f"ECF Project compiled successfully!\n\n{details}")

            print("Compilation successful!")
            # Optionally print detailed summary
            # compiler.print_summary()

        else:
            # Failed - show error message with validation errors
            _show_error_dialog(compiler, project_path)

    except ImportError as e:
        # Handle missing compiler modules
        error_msg = (f"Failed to import compiler!\n\n"
                     f"Error: {e}\n\n"
                     f"Make sure all compiler modules are in the 'core/' directory:\n"
                     f"• core/compiler_main.py\n"
                     f"• core/compiler/parser.py\n"
                     f"• core/compiler/spacer.py\n"
                     f"• core/compiler/file_loader.py\n"
                     f"• core/compiler/debug_manager.py\n"
                     f"• core/compiler/__init__.py")

        messagebox.showerror("Import Error", error_msg)
        print(f"Import error: {e}")

    except Exception as e:
        # Handle unexpected errors
        messagebox.showerror("Unexpected Error",
                             f"An unexpected error occurred during compilation!\n\n{str(e)}")
        print(f"Unexpected error: {e}")
        import traceback
        traceback.print_exc()

    print("Compile process completed!")


def _show_error_dialog(compiler, project_path):
    """
    Show error dialog with compilation errors.
    """
    error_text = f"Could not compile project from:\n{project_path}\n\n"

    # Check if compiler has errors using has_errors() method
    if hasattr(compiler, 'has_errors') and compiler.has_errors():
        errors = compiler.get_errors()
        error_text += f"Validation Errors ({len(errors)} found):\n\n"

        # Show first 10 errors to avoid overwhelming the dialog
        display_errors = errors[:10]
        for i, error in enumerate(display_errors, 1):
            error_text += f"{i}. {error}\n"

        if len(errors) > 10:
            error_text += f"\n... and {len(errors) - 10} more errors.\n"
            error_text += "Check the debug log file for complete error list."

    # Fallback: check for validation_errors attribute
    elif hasattr(compiler, 'validation_errors') and compiler.validation_errors:
        errors = compiler.validation_errors
        error_text += f"Validation Errors ({len(errors)} found):\n\n"

        display_errors = errors[:10]
        for i, error in enumerate(display_errors, 1):
            error_text += f"{i}. {error}\n"

        if len(errors) > 10:
            error_text += f"\n... and {len(errors) - 10} more errors.\n"

    else:
        error_text += "No specific errors reported. Check console output."

    messagebox.showerror("Compile Error", error_text)

    # Also print errors to console
    if hasattr(compiler, 'print_errors'):
        compiler.print_errors()
    else:
        print("ERROR: Compilation failed - see dialog for details")