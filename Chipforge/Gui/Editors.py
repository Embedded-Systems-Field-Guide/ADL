import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import os


def create_code_editor(parent, colors):
    """
    Create a basic text editor for the Code tab (removed Save/Compile buttons).
    """
    # Create text editor with scrollbar
    editor = scrolledtext.ScrolledText(
        parent,
        wrap=tk.NONE,
        bg=colors['input_bg'],
        fg=colors['input_fg'],
        insertbackground=colors['fg'],
        font=('Consolas', 11),
        relief='flat',
        padx=5,
        pady=5
    )
    editor.pack(fill='both', expand=True, padx=5, pady=5)

    return editor


def create_instruction_set_table(parent, colors):
    """
    Create a table for Instruction Set configuration.
    Columns: Address, Name, Length, LeadingNops, Format, Description
    256 rows (2^8)
    """
    # Create frame for table
    frame = tk.Frame(parent, bg=colors['bg'])
    frame.pack(fill='both', expand=True, padx=5, pady=5)

    # Create Treeview with scrollbars
    tree_scroll_y = ttk.Scrollbar(frame, orient='vertical')
    tree_scroll_x = ttk.Scrollbar(frame, orient='horizontal')

    columns = ('Address', 'Name', 'Length', 'LeadingNops', 'Format', 'Description')
    tree = ttk.Treeview(
        frame,
        columns=columns,
        show='headings',
        yscrollcommand=tree_scroll_y.set,
        xscrollcommand=tree_scroll_x.set,
        height=20
    )

    tree_scroll_y.config(command=tree.yview)
    tree_scroll_x.config(command=tree.xview)

    # Configure column headings and widths
    tree.heading('Address', text='Address')
    tree.heading('Name', text='Name')
    tree.heading('Length', text='Length')
    tree.heading('LeadingNops', text='LeadingNops')
    tree.heading('Format', text='Format')
    tree.heading('Description', text='Description')

    tree.column('Address', width=80, anchor='center')
    tree.column('Name', width=150)
    tree.column('Length', width=80, anchor='center')
    tree.column('LeadingNops', width=120, anchor='center')
    tree.column('Format', width=150)
    tree.column('Description', width=300)

    # Insert reserved 0x00 row
    tree.insert('', 'end', iid='0', values=('0x00', 'NOP', '1', '0', 'INST', 'Reserved: Does nothing'),
                tags=('reserved',))

    # Insert 255 empty rows (0x01 to 0xFF)
    for i in range(1, 256):
        tree.insert('', 'end', iid=str(i), values=(f'0x{i:02X}', '', '', '', '', ''), tags=('editable',))

    # Configure row colors
    tree.tag_configure('reserved', background='#555555' if colors['bg'] == '#1e1e1e' else '#cccccc')

    # Bind double-click to edit
    tree.bind('<Double-Button-1>', lambda e: on_table_double_click(e, tree, columns))

    # Pack scrollbars and tree
    tree_scroll_y.pack(side='right', fill='y')
    tree_scroll_x.pack(side='bottom', fill='x')
    tree.pack(side='left', fill='both', expand=True)

    return tree


def create_address_table(parent, colors, title):
    """
    Create a table for Read/Write Address configuration.
    Columns: Address, Name, Description
    256 rows (2^8)
    """
    # Create frame for table
    frame = tk.Frame(parent, bg=colors['bg'])
    frame.pack(fill='both', expand=True, padx=5, pady=5)

    # Create Treeview with scrollbars
    tree_scroll_y = ttk.Scrollbar(frame, orient='vertical')
    tree_scroll_x = ttk.Scrollbar(frame, orient='horizontal')

    columns = ('Address', 'Name', 'Description')
    tree = ttk.Treeview(
        frame,
        columns=columns,
        show='headings',
        yscrollcommand=tree_scroll_y.set,
        xscrollcommand=tree_scroll_x.set,
        height=20
    )

    tree_scroll_y.config(command=tree.yview)
    tree_scroll_x.config(command=tree.xview)

    # Configure column headings and widths
    tree.heading('Address', text='Address')
    tree.heading('Name', text='Name')
    tree.heading('Description', text='Description')

    tree.column('Address', width=100, anchor='center')
    tree.column('Name', width=200)
    tree.column('Description', width=400)

    # Insert reserved 0x00 row
    tree.insert('', 'end', iid='0', values=('0x00', 'NOP', 'Reserved: Does nothing'), tags=('reserved',))

    # Insert 255 empty rows (0x01 to 0xFF)
    for i in range(1, 256):
        tree.insert('', 'end', iid=str(i), values=(f'0x{i:02X}', '', ''), tags=('editable',))

    # Configure row colors
    tree.tag_configure('reserved', background='#555555' if colors['bg'] == '#1e1e1e' else '#cccccc')

    # Bind double-click to edit
    tree.bind('<Double-Button-1>', lambda e: on_table_double_click(e, tree, columns))

    # Pack scrollbars and tree
    tree_scroll_y.pack(side='right', fill='y')
    tree_scroll_x.pack(side='bottom', fill='x')
    tree.pack(side='left', fill='both', expand=True)

    return tree


def on_table_double_click(event, tree, columns):
    """
    Handle double-click on table cells to edit them.
    """
    region = tree.identify('region', event.x, event.y)
    if region != 'cell':
        return

    # Get the item and column
    item = tree.identify_row(event.y)
    column = tree.identify_column(event.x)

    # Don't allow editing reserved row (0x00)
    if item == '0':
        return

    # Don't allow editing the Address column
    if column == '#1':
        return

    # Get column index
    col_index = int(column.replace('#', '')) - 1
    col_name = columns[col_index]

    # Get current value
    current_values = tree.item(item, 'values')
    current_value = current_values[col_index]

    # Get cell position
    x, y, width, height = tree.bbox(item, column)

    # Create entry widget for editing
    entry = tk.Entry(tree)
    entry.place(x=x, y=y, width=width, height=height)
    entry.insert(0, current_value)
    entry.select_range(0, tk.END)
    entry.focus()

    def save_edit(event=None):
        new_value = entry.get()
        new_values = list(current_values)
        new_values[col_index] = new_value
        tree.item(item, values=new_values)
        entry.destroy()

    def cancel_edit(event=None):
        entry.destroy()

    entry.bind('<Return>', save_edit)
    entry.bind('<FocusOut>', save_edit)
    entry.bind('<Escape>', cancel_edit)