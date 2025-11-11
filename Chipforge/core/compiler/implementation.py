from typing import Optional, List, Dict, Any


class ECFImplementation:
    """
    ECF Implementation class to handle the final stage of compilation
    Takes addressed content and generates final machine code with comments
    """

    def __init__(self, instructions: Dict[int, Dict[str, Any]],
                 write_addresses: Dict[int, Dict[str, Any]],
                 read_addresses: Dict[int, Dict[str, Any]]):
        """
        Initialize the implementation with instruction and address definitions

        Args:
            instructions: Dictionary of instruction definitions from compiler
            write_addresses: Dictionary of write address definitions from compiler
            read_addresses: Dictionary of read address definitions from compiler
        """
        self.instructions = instructions
        self.write_addresses = write_addresses
        self.read_addresses = read_addresses
        self.errors = []

    def implement_code(self, addressed_content: str) -> Optional[str]:
        """
        Process addressed content and generate final implemented code
        Converts instructions based on their format definitions

        Args:
            addressed_content: The addressed content from addresser

        Returns:
            Implemented code content as string if successful, None if failed
        """
        try:
            self.errors = []  # Clear previous errors

            lines = addressed_content.splitlines()
            result_lines = []

            address = 0

            while address < len(lines):
                line = lines[address].strip()

                # Skip empty lines
                if not line:
                    result_lines.append("")
                    address += 1
                    continue

                # Find instruction by name
                instruction_data = self._find_instruction_by_name(line)

                if instruction_data is None:
                    # Not an instruction, just output as-is (could be data)
                    result_lines.append(line)
                    address += 1
                    continue

                # Process instruction based on its format and length
                implemented_instruction = self._process_instruction(
                    instruction_data, lines, address
                )

                if implemented_instruction is None:
                    return None  # Error occurred

                # Add the implemented instruction lines
                result_lines.extend(implemented_instruction)

                # Move to next instruction (skip the consumed lines)
                address += instruction_data['length']

            print(f"Implementation stage processed {len(lines)} lines into {len(result_lines)} lines")
            return '\n'.join(result_lines)

        except Exception as e:
            self.errors.append(f"Error in implement_code processing: {e}")
            return None

    def _find_address_by_name(self, name: str, address_type: str) -> Optional[int]:
        """
        Find address by name in the appropriate dictionary

        Args:
            name: The name to find
            address_type: 'instruction', 'write', or 'read'

        Returns:
            Address (key) if found, None otherwise
        """
        if address_type == 'instruction':
            for address, instruction_data in self.instructions.items():
                if instruction_data['name'] == name:
                    return address
        elif address_type == 'write':
            for address, write_data in self.write_addresses.items():
                if write_data['name'] == name:
                    return address
        elif address_type == 'read':
            for address, read_data in self.read_addresses.items():
                if read_data['name'] == name:
                    return address

        return None

    def _find_instruction_by_name(self, name: str) -> Optional[Dict[str, Any]]:
        """
        Find instruction data by name in the instructions dictionary

        Args:
            name: The instruction name to find

        Returns:
            Instruction data dictionary if found, None otherwise
        """
        for instruction_data in self.instructions.values():
            if instruction_data['name'] == name:
                return instruction_data
        return None

    def _process_instruction(self, instruction_data: Dict[str, Any],
                             lines: List[str], address: int) -> Optional[List[str]]:
        """
        Process a single instruction based on its format

        Args:
            instruction_data: The instruction definition
            lines: All lines from addressed content
            address: Current address (line number)

        Returns:
            List of implemented lines if successful, None if error
        """
        try:
            instruction_name = instruction_data['name']
            instruction_length = instruction_data['length']
            instruction_format = instruction_data['format']

            # Check if we have enough lines for this instruction
            if address + instruction_length > len(lines):
                self.errors.append(
                    f"Address {address}: Instruction '{instruction_name}' needs {instruction_length} lines, "
                    f"but only {len(lines) - address} available"
                )
                return None

            # Get the instruction lines
            instruction_lines = []
            for i in range(instruction_length):
                instruction_lines.append(lines[address + i].strip())

            # Process based on format
            result_lines = []

            # Get instruction address
            instruction_address = self._find_address_by_name(instruction_name, 'instruction')
            if instruction_address is None:
                self.errors.append(
                    f"Address {address}: Could not find address for instruction '{instruction_name}'"
                )
                return None

            result_lines.append(f"{instruction_address} //{instruction_name}")

            # Parse format to determine what each parameter should be
            format_parts = instruction_format.split('_')

            # Skip the first part (INS) as that's the instruction itself
            param_formats = format_parts[1:] if len(format_parts) > 1 else []

            # Process each parameter
            param_line_index = 1  # Start after instruction name line

            for param_format in param_formats:
                if param_format == 'WRT':
                    # Write address - takes 1 line
                    if param_line_index >= len(instruction_lines):
                        self.errors.append(
                            f"Address {address}: Missing WRT parameter for instruction '{instruction_name}'"
                        )
                        return None
                    param_name = instruction_lines[param_line_index]
                    param_address = self._find_address_by_name(param_name, 'write')
                    if param_address is None:
                        self.errors.append(
                            f"Address {address}: Could not find write address for '{param_name}'"
                        )
                        return None
                    result_lines.append(f"{param_address} //{param_name}")
                    param_line_index += 1

                elif param_format == 'READ':
                    # Read address - takes 1 line
                    if param_line_index >= len(instruction_lines):
                        self.errors.append(
                            f"Address {address}: Missing READ parameter for instruction '{instruction_name}'"
                        )
                        return None
                    param_name = instruction_lines[param_line_index]
                    param_address = self._find_address_by_name(param_name, 'read')
                    if param_address is None:
                        self.errors.append(
                            f"Address {address}: Could not find read address for '{param_name}'"
                        )
                        return None
                    result_lines.append(f"{param_address} //{param_name}")
                    param_line_index += 1

                elif param_format == 'NUM':
                    # Number - takes 1 line, no comment needed
                    if param_line_index >= len(instruction_lines):
                        self.errors.append(
                            f"Address {address}: Missing NUM parameter for instruction '{instruction_name}'"
                        )
                        return None
                    param_value = instruction_lines[param_line_index]
                    result_lines.append(param_value)
                    param_line_index += 1

                elif param_format == '16ADD':
                    # 16-bit address - takes 2 lines (T@ and B@)
                    if param_line_index + 1 >= len(instruction_lines):
                        self.errors.append(
                            f"Address {address}: Missing 16ADD parameters for instruction '{instruction_name}'"
                        )
                        return None

                    t_value = instruction_lines[param_line_index]
                    b_value = instruction_lines[param_line_index + 1]
                    result_lines.append(f"{t_value} //T@16ADD")
                    result_lines.append(f"{b_value} //B@16ADD")
                    param_line_index += 2

                else:
                    # Unknown format, just output with comment
                    if param_line_index >= len(instruction_lines):
                        self.errors.append(
                            f"Address {address}: Missing parameter for format '{param_format}' in instruction '{instruction_name}'"
                        )
                        return None
                    param_value = instruction_lines[param_line_index]
                    result_lines.append(f"{param_format} //{param_value}")
                    param_line_index += 1

            return result_lines

        except Exception as e:
            self.errors.append(f"Error processing instruction at address {address}: {e}")
            return None

    def get_errors(self) -> List[str]:
        """Return the list of implementation errors"""
        return self.errors.copy()

    def has_errors(self) -> bool:
        """Check if there are any implementation errors"""
        return len(self.errors) > 0

    def print_errors(self):
        """Print all implementation errors"""
        if self.errors:
            print(f"\n=== IMPLEMENTATION ERRORS ({len(self.errors)} found) ===")
            for i, error in enumerate(self.errors, 1):
                print(f"{i}. {error}")
        else:
            print("No implementation errors found.")