import os
from tkinter import filedialog, messagebox, simpledialog
import shutil

# Callback for opening project files
_open_project_callback = None


def set_open_callback(callback):
    """
    Set the callback function for opening project files.
    """
    global _open_project_callback
    _open_project_callback = callback


def on_new_project():
    """
    Handler for New Project button.
    Creates a new .ecfproj file in a user-selected directory.
    """
    try:
        # Ask user to select a directory
        directory = filedialog.askdirectory(title="Select Project Directory")

        if not directory:
            return  # User cancelled

        # Ask for project name
        project_name = simpledialog.askstring("Project Name", "Enter project name:")

        if not project_name:
            return  # User cancelled

        # Ask for project type: Template or Empty
        project_type = messagebox.askyesno("Project Type",
                                           "Use example template?\n\nYes = Example Project\nNo = Empty Project")

        # Create the project directory (one level: ChosenFolder/ProjectName/)
        project_dir = os.path.join(directory, project_name)

        # Check if directory already exists
        if os.path.exists(project_dir):
            overwrite = messagebox.askyesno("Directory Exists",
                                            f"Directory '{project_name}' already exists. Overwrite?")
            if not overwrite:
                return
        else:
            os.makedirs(project_dir)

        if project_type:  # Template/Example project
            create_example_project(project_dir, project_name)
        else:  # Empty project
            create_empty_project(project_dir, project_name)

        messagebox.showinfo("Success", f"Project created at:\n{project_dir}")

        # Load the project
        if _open_project_callback:
            _open_project_callback(project_dir, project_name)

        print(f"New project created: {project_dir}")

    except Exception as e:
        messagebox.showerror("Error", f"Failed to create project:\n{str(e)}")


def create_empty_project(project_dir, project_name):
    """
    Create an empty project with default files.
    """
    # Create .ecfproj file
    ecfproj_path = os.path.join(project_dir, f"{project_name}.ecfproj")
    with open(ecfproj_path, 'w') as f:
        f.write(f"ProjectName={project_name}\n")
        f.write("ReadSpace=false\n")
        f.write("WriteSpace=false\n")
        f.write("InstructionSpace=false\n")
        f.write("ProgramCounterSize=13\n")
        f.write("BusWidth=8\n")

    # Create .ecfASM file
    ecfasm_path = os.path.join(project_dir, f"{project_name}.ecfASM")
    with open(ecfasm_path, 'w') as f:
        f.write("ORG 0:\n")

    # Create Source directory
    source_dir = os.path.join(project_dir, "Source")
    os.makedirs(source_dir, exist_ok=True)

    # Create empty files in Source directory
    addr_file = os.path.join(source_dir, f"{project_name}.ecfADDR")
    with open(addr_file, 'w') as f:
        f.write("")

    addw_file = os.path.join(source_dir, f"{project_name}.ecfADDW")
    with open(addw_file, 'w') as f:
        f.write("")

    inst_file = os.path.join(source_dir, f"{project_name}.ecfINST")
    with open(inst_file, 'w') as f:
        f.write("")


def create_example_project(project_dir, project_name):
    """
    Create a project from the ExampleProj template.
    Copies all files from ExampleProj except its .ecfproj file,
    renames any 'ExampleProj' references in filenames and folders,
    and creates a new .ecfproj for the new project.
    """
    # Locate ExampleProj folder
    script_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    example_dir = os.path.join(script_dir, "ExampleProj")

    if not os.path.exists(example_dir):
        raise Exception(f"ExampleProj folder not found at: {example_dir}")

    # Copy all files except the .ecfproj file
    for item in os.listdir(example_dir):
        if item.endswith(".ecfproj"):
            continue  # Skip example project file

        src_path = os.path.join(example_dir, item)
        dst_path = os.path.join(project_dir, item)

        if os.path.isdir(src_path):
            shutil.copytree(src_path, dst_path, dirs_exist_ok=True)
        else:
            shutil.copy2(src_path, dst_path)

    # Rename any files or folders that contain "ExampleProj" in their name
    for root, dirs, files in os.walk(project_dir, topdown=False):
        for name in files + dirs:
            if "ExampleProj" in name:
                old_path = os.path.join(root, name)
                new_name = name.replace("ExampleProj", project_name)
                new_path = os.path.join(root, new_name)
                os.rename(old_path, new_path)

    # --- Create a new .ecfproj file ---
    new_ecfproj_path = os.path.join(project_dir, f"{project_name}.ecfproj")

    ecfproj_content = [
        f"ProjectName={project_name}",
        "SourceDir=src",
        "BuildDir=build",
        "Output=output.bin",
        "Target=FPGA",
        "Version=1.0",
    ]

    with open(new_ecfproj_path, 'w') as f:
        f.write('\n'.join(ecfproj_content))

    print(f"Created example project '{project_name}' in {project_dir}")