import tkinter as tk
from tkinter import ttk, messagebox
import sys
import os

current_project_dir = None
current_project_name = None

sys.path.append(os.path.dirname(__file__))
from Gui.Tabs import (create_main_tabs, get_theme_colors, detect_windows_theme,
                      load_instruction_file, load_address_file,
                      instruction_table, read_address_table, write_address_table)
from Gui.Ribbon import create_ribbon
from Gui.RibbonFunctions.NewProj import set_open_callback as set_new_callback
from Gui.RibbonFunctions.OpenProj import set_open_callback

current_project_dir = None
current_project_name = None


def open_project_files(project_dir, project_name):
    """
    Load project files into the IDE.
    """
    global current_project_dir, current_project_name
    current_project_dir = project_dir
    current_project_name = project_name

    print(f"Loading project: {project_name} from {project_dir}")

    asm_file = os.path.join(project_dir, f"{project_name}.ecfASM")
    print(f"Looking for ASM file: {asm_file}")

    if os.path.exists(asm_file):
        with open(asm_file, 'r') as f:
            content = f.read()
        code_editor.delete('1.0', 'end')
        code_editor.insert('1.0', content)
        print(f"Loaded {len(content)} characters from ASM file")
    else:
        print(f"ASM file not found: {asm_file}")
        messagebox.showwarning("File Not Found", f"Could not find ASM file:\n{asm_file}")

    source_dir = os.path.join(project_dir, "Source")
    inst_file = os.path.join(source_dir, f"{project_name}.ecfINST")
    load_instruction_file(inst_file)

    from Gui import Tabs

    read_file = os.path.join(source_dir, f"{project_name}.ecfADDR")
    load_address_file(read_file, Tabs.read_address_table)

    write_file = os.path.join(source_dir, f"{project_name}.ecfADDW")
    load_address_file(write_file, Tabs.write_address_table)


def main():
    global code_editor

    root = tk.Tk()
    root.title("Erys Chip Forge")

    root.state('zoomed')

    is_dark = detect_windows_theme()
    colors = get_theme_colors(is_dark)

    root.configure(bg=colors['bg'])

    style = ttk.Style()
    style.theme_use('default')

    style.configure('TNotebook',
                    background=colors['bg'],
                    borderwidth=0)
    style.configure('TNotebook.Tab',
                    background=colors['tab_bg'],
                    foreground=colors['fg'],
                    padding=[20, 10])
    style.map('TNotebook.Tab',
              background=[('selected', colors['tab_selected'])],
              foreground=[('selected', colors['fg'])])

    style.configure('TFrame',
                    background=colors['bg'])

    ribbon = create_ribbon(root, colors)
    ribbon.pack(fill='x', padx=5, pady=(5, 0))

    notebook, code_editor = create_main_tabs(root, colors)
    notebook.pack(fill='both', expand=True, padx=5, pady=5)

    set_new_callback(open_project_files)
    set_open_callback(open_project_files)

    root.mainloop()


if __name__ == "__main__":
    main()
