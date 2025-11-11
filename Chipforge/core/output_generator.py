import os
from datetime import datetime


def generate_output_files(implemented_file_path, project_name, project_dir):
    print(f"Attempting to generate output files from: {implemented_file_path}")
    if not os.path.exists(implemented_file_path):
        print(f"Warning: Implemented file not found: {implemented_file_path}")
        return False

    try:
        rom_data = []
        with open(implemented_file_path, 'r') as f:
            lines = f.readlines()
            print(f"Read {len(lines)} lines from {implemented_file_path}")
            for line in lines:
                line = line.strip()
                if not line:
                    print("Skipping empty line")
                    continue
                number_str = line.split('//')[0].strip()
                if number_str:
                    try:
                        rom_data.append(int(number_str))
                        print(f"Parsed number: {number_str}")
                    except ValueError:
                        print(f"Warning: Could not convert '{number_str}' to integer")
                else:
                    print(f"Skipping line with no number: {line}")

        if not rom_data:
            print("Warning: No valid data found in implemented file")
            return False
        print(f"Extracted {len(rom_data)} valid numbers")

        output_dir = os.path.join(project_dir, "Output")
        print(f"Creating output directory: {output_dir}")
        os.makedirs(output_dir, exist_ok=True)

        generate_c_header(rom_data, implemented_file_path, output_dir)
        generate_ecfrom(rom_data, project_name, output_dir)
        generate_matlab(rom_data, output_dir)

        print(f"Generated output files in: {output_dir}")
        return True

    except Exception as e:
        print(f"Error generating output files: {e}")
        return False

def generate_c_header(rom_data, source_file, output_dir):
    """
    Generate rom_data.h C header file.
    """
    output_path = os.path.join(output_dir, "rom_data.h")

    # Get current timestamp
    now = datetime.now()
    timestamp = now.strftime("%a %d/%m/%Y at %H:%M:%S")

    # Use actual data length (no padding)
    rom_size = len(rom_data)

    with open(output_path, 'w') as f:
        f.write("#ifndef ROM_DATA_H\n")
        f.write("#define ROM_DATA_H\n\n")
        f.write(f"// Auto-generated ROM data from {source_file}\n")
        f.write(f"// Generated on {timestamp}\n\n")
        f.write("#include <stdint.h>\n\n")
        f.write(f"#define ROM_DATA_SIZE {rom_size}\n")
        f.write(f"const uint8_t rom_data[{rom_size}] = {{\n")

        # Write data in rows of 16 values
        for i in range(0, len(rom_data), 16):
            row = rom_data[i:i + 16]
            row_str = ", ".join(str(val) for val in row)
            # Add comma except for the last line
            if i + 16 < len(rom_data):
                f.write(f"{row_str},\n")
            else:
                f.write(f"{row_str}\n")

        f.write("};\n\n")
        f.write("// Array size\n\n")
        f.write("#endif // ROM_DATA_H\n")

    print(f"Generated: {output_path}")


def generate_ecfrom(rom_data, project_name, output_dir):
    """
    Generate projectName.ecfROM file (one number per line, no comments).
    """
    output_path = os.path.join(output_dir, f"{project_name}.ecfROM")

    with open(output_path, 'w') as f:
        for value in rom_data:
            f.write(f"{value}\n")

    print(f"Generated: {output_path}")


def generate_matlab(rom_data, output_dir):
    """
    Generate rom_data.mat MATLAB file.
    """
    output_path = os.path.join(output_dir, "rom_data.mat")

    try:
        # Try to use scipy if available
        from scipy.io import savemat
        import numpy as np

        # Pad or trim to 8192 values
        if len(rom_data) < 8192:
            # Pad with zeros
            padded_data = rom_data + [0] * (8192 - len(rom_data))
        elif len(rom_data) > 8192:
            # Trim to 8192
            padded_data = rom_data[:8192]
        else:
            padded_data = rom_data

        # Create column vector (8192x1) to match MATLAB format
        rom_array = np.array(padded_data, dtype=np.uint8).reshape(-1, 1)

        # Create MATLAB structure
        mat_data = {
            'rom_data': rom_array
        }

        savemat(output_path, mat_data)
        print(f"Generated: {output_path}")

    except ImportError:
        # Fallback: create a simple MATLAB script file (.m)
        print("Warning: scipy not available, creating .m file instead")
        output_path = os.path.join(output_dir, "load_rom_data.m")

        # Pad or trim to 8192 values
        if len(rom_data) < 8192:
            padded_data = rom_data + [0] * (8192 - len(rom_data))
        elif len(rom_data) > 8192:
            padded_data = rom_data[:8192]
        else:
            padded_data = rom_data

        with open(output_path, 'w') as f:
            f.write("% Auto-generated ROM data loader\n")
            f.write(f"% Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("% This script loads rom_data into your workspace\n\n")
            f.write("rom_data = [\n")

            # Write data as column vector (one value per line for proper column vector)
            for val in padded_data:
                f.write(f"    {val}\n")

            f.write("];\n\n")
            f.write("% rom_data is now available as a column vector (8192x1)\n")
            f.write("fprintf('Loaded rom_data: %d values\\n', length(rom_data));\n")

        print(f"Generated: {output_path} (MATLAB script - run this in MATLAB to load data)")