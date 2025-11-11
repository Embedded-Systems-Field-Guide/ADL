import tkinter as tk
from tkinter import PhotoImage
import os
from Gui.RibbonFunctions.NewProj import on_new_project
from Gui.RibbonFunctions.OpenProj import on_open_project
from Gui.RibbonFunctions.CompileProj import on_compile_project
from Gui.RibbonFunctions.Save import on_save_project
from Gui.RibbonFunctions.Programmer import on_programmer_click

# Global reference to programmer button
programmer_button = None


def create_ribbon(parent, colors):
    """
    Create the ribbon bar with New Project, Open Project, Save, Compile, Programmer, and Close App buttons.
    Returns the ribbon frame.
    """
    global programmer_button

    ribbon_frame = tk.Frame(parent, bg=colors['tab_bg'], height=60)

    # Get the assets directory path
    assets_dir = os.path.join(os.path.dirname(__file__), 'assets')

    # Button configuration
    button_config = {
        'bg': colors['tab_bg'],
        'fg': colors['fg'],
        'activebackground': colors['tab_selected'],
        'activeforeground': colors['fg'],
        'relief': 'flat',
        'bd': 0,
        'padx': 15,
        'pady': 8,
        'font': ('Arial', 10)
    }

    # Try to load icons, fall back to text if not available
    try:
        new_icon = PhotoImage(file=os.path.join(assets_dir, 'new_project.png'))
        open_icon = PhotoImage(file=os.path.join(assets_dir, 'open_project.png'))
        save_icon = PhotoImage(file=os.path.join(assets_dir, 'save.png'))
        compile_icon = PhotoImage(file=os.path.join(assets_dir, 'compile.png'))
        programmer_icon = PhotoImage(file=os.path.join(assets_dir, 'programmer.png'))
        close_icon = PhotoImage(file=os.path.join(assets_dir, 'close_app.png'))

        # Store references to prevent garbage collection
        ribbon_frame.new_icon = new_icon
        ribbon_frame.open_icon = open_icon
        ribbon_frame.save_icon = save_icon
        ribbon_frame.compile_icon = compile_icon
        ribbon_frame.programmer_icon = programmer_icon
        ribbon_frame.close_icon = close_icon

        # Create buttons with icons
        btn_new = tk.Button(ribbon_frame, image=new_icon, command=on_new_project, **button_config)
        btn_open = tk.Button(ribbon_frame, image=open_icon, command=on_open_project, **button_config)
        btn_save = tk.Button(ribbon_frame, image=save_icon, command=on_save_project, **button_config)
        btn_compile = tk.Button(ribbon_frame, image=compile_icon, command=on_compile_project, **button_config)
        programmer_button = tk.Button(ribbon_frame, image=programmer_icon, command=on_programmer_click, **button_config)
        btn_close = tk.Button(ribbon_frame, image=close_icon, command=on_close_app, **button_config)

    except Exception:
        # Fall back to text buttons if icons not found
        btn_new = tk.Button(ribbon_frame, text='New Project', command=on_new_project, **button_config)
        btn_open = tk.Button(ribbon_frame, text='Open Project', command=on_open_project, **button_config)
        btn_save = tk.Button(ribbon_frame, text='Save', command=on_save_project, **button_config)
        btn_compile = tk.Button(ribbon_frame, text='Compile', command=on_compile_project, **button_config)
        programmer_button = tk.Button(ribbon_frame, text='Connect to Programmer', command=on_programmer_click,
                                      **button_config)
        btn_close = tk.Button(ribbon_frame, text='Close App', command=on_close_app, **button_config)

    # Pack buttons to the left
    btn_new.pack(side='left', padx=5, pady=10)
    btn_open.pack(side='left', padx=5, pady=10)
    btn_save.pack(side='left', padx=5, pady=10)
    btn_compile.pack(side='left', padx=5, pady=10)
    programmer_button.pack(side='left', padx=5, pady=10)

    # Pack close button to the right
    btn_close.pack(side='right', padx=5, pady=10)

    return ribbon_frame


def on_close_app():
    """
    Handler for Close App button.
    Terminates the application.
    """
    import sys
    from tkinter import messagebox

    if messagebox.askokcancel("Quit", "Are you sure you want to exit?"):
        sys.exit(0)


def get_programmer_button():
    """
    Get reference to the programmer button for updating its appearance.
    """
    return programmer_button