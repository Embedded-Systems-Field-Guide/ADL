import os
from tkinter import filedialog, messagebox

# Callback for opening project files
_open_project_callback = None


def set_open_callback(callback):
    """
    Set the callback function for opening project files.
    """
    global _open_project_callback
    _open_project_callback = callback


def on_open_project():
    """
    Handler for Open Project button.
    Opens an existing .ecfproj file and saves its directory.
    """
    try:
        # Ask user to select a .ecfproj file
        project_file = filedialog.askopenfilename(
            title="Open Project",
            filetypes=[("ECF Project", "*.ecfproj"), ("All Files", "*.*")]
        )

        if not project_file:
            return  # User cancelled

        # Get the directory and name of the project
        project_dir = os.path.dirname(project_file)
        project_name = os.path.basename(project_file).replace('.ecfproj', '')

        print(f"Opening project: {project_name}")
        print(f"Project directory: {project_dir}")

        # Load the project data
        if _open_project_callback:
            _open_project_callback(project_dir, project_name)

        messagebox.showinfo("Success", f"Project opened:\n{project_name}")

    except Exception as e:
        messagebox.showerror("Error", f"Failed to open project:\n{str(e)}")