import os
from tkinter import messagebox


def on_save_project():
    """
    Save the current project (ASM file and all configuration tables).
    """
    # Import the main module to access global variables
    import sys
    ecf_module = sys.modules.get('__main__')

    if ecf_module is None:
        messagebox.showwarning("Error", "Could not access project state.")
        return

    current_project_dir = getattr(ecf_module, 'current_project_dir', None)
    current_project_name = getattr(ecf_module, 'current_project_name', None)
    code_editor = getattr(ecf_module, 'code_editor', None)

    if current_project_dir is None or current_project_name is None:
        messagebox.showwarning("No Project", "Please open or create a project first.")
        return

    if code_editor is None:
        messagebox.showwarning("Error", "Code editor not found.")
        return

    try:
        # Get content from editor
        content = code_editor.get('1.0', 'end-1c')

        # Save to ASM file
        asm_file = os.path.join(current_project_dir, f"{current_project_name}.ecfASM")
        with open(asm_file, 'w') as f:
            f.write(content)

        # Save the three tables
        from Gui import Tabs
        source_dir = os.path.join(current_project_dir, "Source")

        # Ensure Source directory exists
        os.makedirs(source_dir, exist_ok=True)

        # Debug: Check if tables exist
        print(f"Instruction table: {Tabs.instruction_table}")
        print(f"Read address table: {Tabs.read_address_table}")
        print(f"Write address table: {Tabs.write_address_table}")

        # Save Instruction Set table
        inst_file = os.path.join(source_dir, f"{current_project_name}.ecfINST")
        save_instruction_table(Tabs.instruction_table, inst_file)

        # Save Read Address table
        read_file = os.path.join(source_dir, f"{current_project_name}.ecfADDR")
        save_address_table(Tabs.read_address_table, read_file)

        # Save Write Address table
        write_file = os.path.join(source_dir, f"{current_project_name}.ecfADDW")
        save_address_table(Tabs.write_address_table, write_file)

        messagebox.showinfo("Success", "Project saved successfully!")
        print(f"Saved ASM to: {asm_file}")
        print(f"Saved Instruction Set to: {inst_file}")
        print(f"Saved Read Addresses to: {read_file}")
        print(f"Saved Write Addresses to: {write_file}")

    except Exception as e:
        messagebox.showerror("Error", f"Failed to save project:\n{str(e)}")
        import traceback
        traceback.print_exc()


def save_instruction_table(table, filepath):
    """
    Save instruction set table to .ecfINST file.
    Format: Address\tName\tLength\tLeadingNops\tFormat\tDescription
    """
    print(f"\n=== SAVING INSTRUCTION TABLE to {filepath} ===")

    if table is None:
        print("ERROR: Instruction table is None")
        return

    print(f"Table object: {table}")
    print(f"Table type: {type(table)}")

    try:
        rows_saved = 0
        with open(filepath, 'w') as f:
            # Iterate through all rows (skip row 0 which is reserved NOP)
            for i in range(1, 256):
                values = table.item(str(i), 'values')

                # # Debug: Print first 10 rows to see structure
                # if i <= 10:
                #     print(f"  Row {i}:")
                #     print(f"    Raw values: {values}")
                #     print(f"    Type: {type(values)}")
                #     print(f"    Length: {len(values) if values else 0}")
                #     if values and len(values) >= 6:
                #         print(f"    Address: '{values[0]}'")
                #         print(f"    Name: '{values[1]}'")
                #         print(f"    Length: '{values[2]}'")
                #         print(f"    LeadingNops: '{values[3]}'")
                #         print(f"    Format: '{values[4]}'")
                #         print(f"    Description: '{values[5]}'")
                #         print(f"    Name is empty?: {not values[1]}")
                #         print(f"    Name stripped: '{str(values[1]).strip()}'")

                # Check if values is valid and has content
                if values and len(values) >= 6:
                    # Check if Name field (index 1) is not empty
                    name = str(values[1]).strip()
                    if name:
                        # Write: Address(int)\tName\tLength\tLeadingNops\tFormat\tDescription
                        line = f"{i}\t{values[1]}\t{values[2]}\t{values[3]}\t{values[4]}\t{values[5]}\n"
                        print(f"  Writing row {i}: {repr(line)}")
                        f.write(line)
                        rows_saved += 1
                #     else:
                #         # if i <= 10:
                #         #     print(f"  Skipping row {i}: Name is empty")
                # else:
                #     if i <= 10:
                #         print(f"  Skipping row {i}: Invalid values structure")

        print(f"\n=== SAVED {rows_saved} instruction rows to: {filepath} ===\n")

    except Exception as e:
        print(f"ERROR saving instruction table: {e}")
        import traceback
        traceback.print_exc()
        raise


def save_address_table(table, filepath):
    """
    Save address table to .ecfADDR or .ecfADDW file.
    Format: Address\tName\tDescription
    """
    print(f"\n=== SAVING ADDRESS TABLE to {filepath} ===")

    if table is None:
        print(f"ERROR: Address table is None for {filepath}")
        return

    print(f"Table object: {table}")
    print(f"Table type: {type(table)}")

    try:
        rows_saved = 0
        with open(filepath, 'w') as f:
            # Iterate through all rows (skip row 0 which is reserved NOP)
            for i in range(1, 256):
                values = table.item(str(i), 'values')

                # Debug: Print first 10 rows to see structure
                if i <= 10:
                    print(f"  Row {i}:")
                    print(f"    Raw values: {values}")
                    print(f"    Type: {type(values)}")
                    print(f"    Length: {len(values) if values else 0}")
                    if values and len(values) >= 3:
                        print(f"    Address: '{values[0]}'")
                        print(f"    Name: '{values[1]}'")
                        print(f"    Description: '{values[2]}'")
                        print(f"    Name is empty?: {not values[1]}")
                        print(f"    Name stripped: '{str(values[1]).strip()}'")

                # Check if values is valid and has content
                if values and len(values) >= 3:
                    # Check if Name field (index 1) is not empty
                    name = str(values[1]).strip()
                    if name:
                        # Write: Address(int)\tName\tDescription
                        line = f"{i}\t{values[1]}\t{values[2]}\n"
                        print(f"  Writing row {i}: {repr(line)}")
                        f.write(line)
                        rows_saved += 1
                    else:
                        if i <= 10:
                            print(f"  Skipping row {i}: Name is empty")
                else:
                    if i <= 10:
                        print(f"  Skipping row {i}: Invalid values structure")

        print(f"\n=== SAVED {rows_saved} address rows to: {filepath} ===\n")

    except Exception as e:
        print(f"ERROR saving address table: {e}")
        import traceback
        traceback.print_exc()
        raise