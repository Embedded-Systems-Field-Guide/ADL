import tkinter as tk
from tkinter import ttk
import platform
import os
from Gui.Editors import create_code_editor, create_instruction_set_table, create_address_table
from Gui.Programmer.programming import create_programming_interface
from Gui.Programmer.validate import create_validate_interface
from Gui.Programmer.emulate import create_emulate_interface
from Gui.Programmer.sniffer import create_sniffer_interface
from Gui.Programmer.debugger import create_debugger_interface

# Global references to tables for loading data
instruction_table = None
read_address_table = None
write_address_table = None


def detect_windows_theme():
    """
    Detect if Windows is using dark or light theme.
    Returns True for dark theme, False for light theme.
    """
    if platform.system() == 'Windows':
        try:
            import winreg
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
            )
            value, _ = winreg.QueryValueEx(key, 'AppsUseLightTheme')
            winreg.CloseKey(key)
            return value == 0  # 0 = dark theme, 1 = light theme
        except Exception:
            return False  # Default to light theme if detection fails
    return False  # Default to light theme on non-Windows


def get_theme_colors(is_dark):
    """
    Get color scheme based on theme.
    Returns a dictionary of colors for the application.
    """
    if is_dark:
        return {
            'bg': '#1e1e1e',  # Main background
            'fg': '#e0e0e0',  # Foreground text
            'tab_bg': '#2d2d2d',  # Tab background
            'tab_selected': '#0e639c',  # Selected tab
            'frame_bg': '#252526',  # Frame background
            'input_bg': '#3c3c3c',  # Input fields
            'input_fg': '#e0e0e0'  # Input text
        }
    else:
        return {
            'bg': '#f0f0f0',  # Main background
            'fg': '#000000',  # Foreground text
            'tab_bg': '#e0e0e0',  # Tab background
            'tab_selected': '#0078d4',  # Selected tab
            'frame_bg': '#ffffff',  # Frame background
            'input_bg': '#ffffff',  # Input fields
            'input_fg': '#000000'  # Input text
        }


def create_main_tabs(parent, colors):
    """
    Create the three main tabs: Code, Configure, Program.
    Returns the notebook widget and code editor.
    """
    notebook = ttk.Notebook(parent)

    # Create Code tab
    code_tab = ttk.Frame(notebook)
    notebook.add(code_tab, text='Code')
    code_editor = setup_code_tab(code_tab, colors)

    # Create Configure tab
    configure_tab = ttk.Frame(notebook)
    notebook.add(configure_tab, text='Configure')
    setup_configure_tab(configure_tab, colors)

    # Create Program tab
    program_tab = ttk.Frame(notebook)
    notebook.add(program_tab, text='Program')
    setup_program_tab(program_tab, colors)

    return notebook, code_editor


def setup_code_tab(parent, colors):
    """
    Setup the Code tab - single editor area.
    """
    editor = create_code_editor(parent, colors)
    return editor


def setup_configure_tab(parent, colors):
    """
    Setup the Configure tab with sub-tabs.
    """
    global instruction_table, read_address_table, write_address_table

    # Create sub-notebook for Configure tab
    sub_notebook = ttk.Notebook(parent)
    sub_notebook.pack(fill='both', expand=True)

    # Instruction Set sub-tab
    instruction_tab = ttk.Frame(sub_notebook)
    sub_notebook.add(instruction_tab, text='Instruction Set')
    instruction_table = create_instruction_set_table(instruction_tab, colors)

    # Write Addresses sub-tab
    write_addr_tab = ttk.Frame(sub_notebook)
    sub_notebook.add(write_addr_tab, text='Write Addresses')
    write_address_table = create_address_table(write_addr_tab, colors, 'Write Addresses')

    # Read Addresses sub-tab
    read_addr_tab = ttk.Frame(sub_notebook)
    sub_notebook.add(read_addr_tab, text='Read Addresses')
    read_address_table = create_address_table(read_addr_tab, colors, 'Read Addresses')


def setup_program_tab(parent, colors):
    """
    Setup the Program tab with sub-tabs.
    """
    # Create sub-notebook for Program tab
    sub_notebook = ttk.Notebook(parent)
    sub_notebook.pack(fill='both', expand=True)

    # Program sub-tab
    program_subtab = ttk.Frame(sub_notebook)
    sub_notebook.add(program_subtab, text='Program')
    create_programming_interface(program_subtab, colors)

    # Validate sub-tab
    validate_tab = ttk.Frame(sub_notebook)
    sub_notebook.add(validate_tab, text='Validate')
    create_validate_interface(validate_tab, colors)

    # Emulate sub-tab
    emulate_tab = ttk.Frame(sub_notebook)
    sub_notebook.add(emulate_tab, text='Emulate')
    create_emulate_interface(emulate_tab, colors)

    # Sniffer sub-tab
    sniffer_tab = ttk.Frame(sub_notebook)
    sub_notebook.add(sniffer_tab, text='Sniffer')
    create_sniffer_interface(sniffer_tab, colors)

    # # Debugger sub-tab
    # debugger_tab = ttk.Frame(sub_notebook)
    # sub_notebook.add(debugger_tab, text='Debugger')
    # create_debugger_interface(debugger_tab, colors)


def load_instruction_file(filepath):
    """
    Load instruction set data from .ecfINST file.
    Format: Address\tName\tLength\tLeadingNops\tFormat\tDescription
    """
    global instruction_table

    if not os.path.exists(filepath):
        print(f"Instruction file not found: {filepath}")
        return

    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()

        for line in lines:
            line = line.strip()
            if not line:
                continue

            parts = line.split('\t')
            if len(parts) < 6:
                continue

            address_int = int(parts[0])
            if address_int == 0 or address_int >= 256:
                continue  # Skip reserved address and out of range

            # Update the tree item
            instruction_table.item(str(address_int), values=(
                f'0x{address_int:02X}',
                parts[1],  # Name
                parts[2],  # Length
                parts[3],  # LeadingNops
                parts[4],  # Format
                parts[5]  # Description
            ))

        print(f"Loaded instruction data from: {filepath}")

    except Exception as e:
        print(f"Error loading instruction file: {e}")


def load_address_file(filepath, table):
    """
    Load address data from .ecfADDR or .ecfADDW file.
    Format: Address\tName\tDescription
    """
    if not os.path.exists(filepath):
        print(f"Address file not found: {filepath}")
        return

    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()

        for line in lines:
            line = line.strip()
            if not line:
                continue

            parts = line.split('\t')
            if len(parts) < 3:
                continue

            address_int = int(parts[0])
            if address_int == 0 or address_int >= 256:
                continue  # Skip reserved address and out of range

            # Update the tree item
            table.item(str(address_int), values=(
                f'0x{address_int:02X}',
                parts[1],  # Name
                parts[2]  # Description
            ))

        print(f"Loaded address data from: {filepath}")

    except Exception as e:
        print(f"Error loading address file: {e}")