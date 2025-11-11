from typing import Optional, List, Dict, Any


class ECFSpacer:
    """
    ECF Spacer class to handle the spacing/formatting of parsed ASM content
    Separates spacing logic from the main compiler
    """

    def __init__(self, instructions: Dict[int, Dict[str, Any]]):
        """
        Initialize the spacer with instruction definitions

        Args:
            instructions: Dictionary of instruction definitions from compiler
        """
        self.instructions = instructions
        self.errors = []

    def space_code(self, parsed_content: str) -> Optional[str]:
        """
        Process parsed ASM content and generate spaced code

        Args:
            parsed_content: The cleaned ASM content from parser

        Returns:
            Spaced code content as string if successful, None if failed
        """
        try:
            self.errors = []  # Clear previous errors
            lines = parsed_content.strip().split('\n')
            output_lines = []
            current_address = 0
            line_num = 0

            for line in lines:
                line_num += 1
                line = line.strip()
                if not line:
                    continue

                # Check for compiler-only commands
                if self._is_compiler_command(line, line_num):
                    # Validate format but keep as-is in output
                    if not self._validate_compiler_command(line, line_num):
                        return None
                    output_lines.append(line)

                    # Update current address if this is an ORG command
                    if line.split()[0].upper() == 'ORG':
                        parts = line.split()
                        current_address = int(parts[1][:-1])  # Remove colon and convert to int
                    continue

                # Process regular instruction
                if not self._process_instruction_line(line, line_num, current_address, output_lines):
                    return None

                # Update current address based on instruction length
                instruction_name = line.split()[0]
                if instruction_name in [inst['name'] for inst in self.instructions.values()]:
                    # Find instruction by name
                    for inst_data in self.instructions.values():
                        if inst_data['name'] == instruction_name:
                            current_address += inst_data['length']
                            break

            return '\n'.join(output_lines)

        except Exception as e:
            self.errors.append(f"Error in SpaceCode processing: {e}")
            return None

    def _is_compiler_command(self, line: str, line_num: int) -> bool:
        """Check if line is a compiler-only command"""
        parts = line.split()
        if not parts:
            return False

        # Check for ORG command
        if parts[0].upper() == 'ORG':
            return True

        # Check for Label (word ending with :)
        if len(parts) == 1 and parts[0].endswith(':'):
            return True

        # Check for DB command
        if parts[0].upper() == 'DB':
            return True

        return False

    def _validate_compiler_command(self, line: str, line_num: int) -> bool:
        """Validate compiler-only command format"""
        parts = line.split()

        if not parts:
            self.errors.append(f"Line {line_num}: Empty compiler command")
            return False

        # Validate ORG format: ORG NUM:
        if parts[0].upper() == 'ORG':
            if len(parts) != 2:
                self.errors.append(f"Line {line_num}: ORG format should be 'ORG NUM:'")
                return False
            if not parts[1].endswith(':'):
                self.errors.append(f"Line {line_num}: ORG should end with colon ':'")
                return False
            try:
                int(parts[1][:-1])  # Remove colon and check if it's a number
            except ValueError:
                self.errors.append(f"Line {line_num}: ORG address '{parts[1][:-1]}' is not a valid number")
                return False
            return True

        # Validate Label format: WORD:
        if len(parts) == 1 and parts[0].endswith(':'):
            label_name = parts[0][:-1]
            if not label_name:
                self.errors.append(f"Line {line_num}: Empty label name")
                return False
            # Allow alphanumeric characters and underscores for labels
            if not all(c.isalnum() or c == '_' for c in label_name):
                self.errors.append(
                    f"Line {line_num}: Label '{label_name}' should contain only letters, numbers, and underscores")
                return False
            return True

        # Validate DB format: DB NUM NUM ...
        if parts[0].upper() == 'DB':
            if len(parts) < 2:
                self.errors.append(f"Line {line_num}: DB should be followed by at least one number")
                return False
            for i, part in enumerate(parts[1:], 2):
                try:
                    int(part)
                except ValueError:
                    self.errors.append(f"Line {line_num}: DB parameter '{part}' is not a valid number")
                    return False
            return True

        self.errors.append(f"Line {line_num}: Unknown compiler command format")
        return False

    def _process_instruction_line(self, line: str, line_num: int, current_address: int, output_lines: list) -> bool:
        """Process a regular instruction line"""
        parts = line.split()
        if not parts:
            return True

        instruction_name = parts[0]
        parameters = parts[1:] if len(parts) > 1 else []

        # Find instruction in dictionary
        instruction_data = None
        for inst_data in self.instructions.values():
            if inst_data['name'] == instruction_name:
                instruction_data = inst_data
                break

        if instruction_data is None:
            self.errors.append(f"Line {line_num}: Unknown instruction '{instruction_name}'")
            return False

        # Parse format to get expected parameter types
        format_parts = instruction_data['format'].split('_')[1:] if '_' in instruction_data['format'] else []

        # Validate parameter count
        if len(parameters) != len(format_parts):
            self.errors.append(
                f"Line {line_num}: Instruction '{instruction_name}' expects {len(format_parts)} parameters, got {len(parameters)}")
            return False

        # Add instruction name
        output_lines.append(instruction_name)

        # Process parameters based on format
        for i, (param, format_type) in enumerate(zip(parameters, format_parts)):
            if format_type == '16ADD':
                # 16-bit address - split into top and bottom bytes
                output_lines.append(f"T@{param}")
                output_lines.append(f"B@{param}")
            else:
                # Regular parameter (NUM, WRT, READ)
                output_lines.append(param)

        # Add leading NOPs
        for _ in range(instruction_data['leading_nops']):
            output_lines.append("0")

        return True

    def get_errors(self) -> List[str]:
        """Return the list of spacing errors"""
        return self.errors.copy()

    def has_errors(self) -> bool:
        """Check if there are any spacing errors"""
        return len(self.errors) > 0

    def add_compiler_command_type(self, command_name: str, validator_func):
        """
        Allow extending the spacer with new compiler command types

        Args:
            command_name: Name of the new command (e.g., 'INCLUDE')
            validator_func: Function to validate this command type
        """
        # This could be extended in the future to support plugin-style command additions
        pass