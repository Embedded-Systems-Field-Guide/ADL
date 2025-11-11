from typing import List, Dict, Optional


class LBLHandler:
    """
    Handles label processing, validation, and management
    """

    def __init__(self, instructions: Dict[int, Dict[str, any]] = None):
        self.errors = []
        self.instructions = instructions or {}  # Store instructions for length lookup
        self.reserved_keywords = {
            'ORG', 'DB', 'END', 'EQU',
            # Add more reserved keywords as needed
        }

    def is_label_line(self, line: str) -> bool:
        """
        Check if a line is a label definition (ends with colon but not ORG)

        Args:
            line: The line to check

        Returns:
            True if it's a label line, False otherwise
        """
        line = line.strip()
        if not line.endswith(':'):
            return False

        # Extract potential label name
        label_name = line[:-1].strip()

        # Skip ORG commands (they also end with colon but are not labels)
        return not label_name.upper().startswith('ORG ')

    def extract_label_name(self, line: str) -> Optional[str]:
        """
        Extract the label name from a label line

        Args:
            line: The label line (e.g., "LOOP:", "DATA_START:")

        Returns:
            The label name without the colon, or None if not a valid label line
        """
        if not self.is_label_line(line):
            return None

        return line.strip()[:-1].strip()

    def is_valid_label_name(self, label_name: str) -> bool:
        """
        Validate if a label name is valid

        Args:
            label_name: The label name to validate

        Returns:
            True if valid, False otherwise
        """
        # Basic validation rules for label names:
        # - Must not be empty
        # - Should contain only alphanumeric characters and underscores
        # - Must not be a reserved keyword
        # - Can start with digits (unlike some assembly languages, this one allows it)

        if not label_name:
            return False

        # Check for valid characters (alphanumeric and underscore)
        if not all(c.isalnum() or c == '_' for c in label_name):
            return False

        # Check against reserved keywords
        if label_name.upper() in self.reserved_keywords:
            return False

        return True

    def get_instruction_length(self, instruction_name: str) -> int:
        """
        Get the length of an instruction by name

        Args:
            instruction_name: The name of the instruction

        Returns:
            The length of the instruction, or 1 if not found
        """
        for inst_data in self.instructions.values():
            if inst_data['name'] == instruction_name:
                return inst_data['length']

        # Default to 1 if instruction not found
        print(f"WARNING: Instruction '{instruction_name}' not found in instruction set, defaulting to length 1")
        return 1

    def find_and_process_labels(self, addressed_array: List[str]) -> Dict[str, int]:
        """
        Find all labels from top to bottom, store their addresses, and remove them from the array
        This modifies the addressed_array by removing label lines and shifting content up

        Args:
            addressed_array: The addressed array to process

        Returns:
            Dictionary mapping label names to their addresses
        """
        try:
            self.errors = []  # Clear previous errors
            label_addresses = {}  # Dictionary to store label -> address mappings

            # Process from top to bottom, but track removals to adjust addresses
            address = 0
            removals_count = 0  # Track how many labels we've removed

            while address < len(addressed_array):
                line = addressed_array[address].strip()

                # Check if this is a label line
                if self.is_label_line(line):
                    # Extract label name
                    label_name = self.extract_label_name(line)

                    if label_name and self.is_valid_label_name(label_name):
                        # The actual address where this label points is the current address
                        # (since labels point to the next instruction after them)
                        actual_address = address


                        # Check for duplicate labels
                        if label_name in label_addresses:
                            self.errors.append(
                                f"Duplicate label '{label_name}' found at address {actual_address}. Previously defined at address {label_addresses[label_name]}")
                        else:
                            # Store the label and its address
                            label_addresses[label_name] = actual_address

                        # Remove the label line from the array
                        addressed_array.pop(address)
                        removals_count += 1


                        # Don't increment address since we removed an element
                        # The next element is now at the same index
                        continue
                    else:
                        if label_name:
                            self.errors.append(f"Invalid label name at address {address}: '{label_name}'")

                # Move to next address
                address += 1

            # After finding all labels, replace label references with addresses
            if not self.replace_label_references(addressed_array, label_addresses):
                return {}

            return label_addresses

        except Exception as e:
            self.errors.append(f"Error processing labels: {e}")
            return {}

    def replace_label_references(self, addressed_array: List[str], label_addresses: Dict[str, int]) -> bool:
        """
        Replace label references in the code with their actual address values
        Handles T@LABEL (top byte), B@LABEL (bottom byte), and direct LABEL (8-bit offset) references

        Args:
            addressed_array: The addressed array to process (modified in place)
            label_addresses: Dictionary of defined labels and their addresses

        Returns:
            True if all references were successfully replaced, False if errors found
        """
        try:
            self.errors = []  # Clear previous errors

            # Process each line in the array
            for address, line in enumerate(addressed_array):
                original_line = line
                modified_line = line

                # Find all label references in this line
                import re

                # Pattern to match T@LABELNAME or B@LABELNAME
                pattern_prefixed = r'\b([TB])@([A-Za-z0-9_]+)\b'

                # Pattern to match direct label references (just LABELNAME without prefix)
                # This should match valid label names that are not part of T@ or B@ references
                pattern_direct = r'\b(?<![@])([A-Za-z0-9_]+)(?![@])\b'

                # First, handle prefixed references (T@ and B@)
                matches = re.finditer(pattern_prefixed, line)

                # Process matches in reverse order to maintain string positions
                for match in reversed(list(matches)):
                    prefix = match.group(1)  # 'T' or 'B'
                    label_name = match.group(2)  # The label name
                    full_match = match.group(0)  # The complete match like 'T@MAIN'


                    # Check if the label exists
                    if label_name not in label_addresses:
                        self.errors.append(f"Undefined label reference '{label_name}' at address {address}")
                        continue

                    # Get the label's address
                    label_address = label_addresses[label_name]

                    # Calculate the replacement value
                    if prefix == 'T':
                        # Top byte (high byte) of 16-bit address
                        replacement_value = (label_address >> 8) & 0xFF
                    else:  # prefix == 'B'
                        # Bottom byte (low byte) of 16-bit address
                        replacement_value = label_address & 0xFF


                    # Replace the reference with the calculated value
                    start, end = match.span()
                    modified_line = modified_line[:start] + str(replacement_value) + modified_line[end:]

                # Now handle direct label references (8-bit offsets)
                # We need to be careful not to match instruction names or numbers
                # Only match if the word is a known label and not an instruction name

                # Get current line after prefixed replacements
                current_line = modified_line

                # Find potential direct label references
                direct_matches = list(re.finditer(pattern_direct, current_line))

                # Filter matches to only include actual labels (not instruction names, numbers, etc.)
                valid_direct_matches = []
                for match in direct_matches:
                    potential_label = match.group(1)

                    # Skip if it's a number
                    if potential_label.isdigit():
                        continue

                    # Skip if it's an instruction name
                    is_instruction = False
                    for inst_data in self.instructions.values():
                        if inst_data['name'] == potential_label:
                            is_instruction = True
                            break

                    if is_instruction:
                        continue

                    # Only process if it's a known label
                    if potential_label in label_addresses:
                        valid_direct_matches.append(match)

                # Process valid direct matches in reverse order
                for match in reversed(valid_direct_matches):
                    label_name = match.group(1)


                    # Get the label's address
                    label_address = label_addresses[label_name]

                    # Get the instruction name at current address to find its length
                    instruction_name = addressed_array[address - 1].strip()
                    instruction_length = self.get_instruction_length(instruction_name)

                    # Calculate 8-bit offset: abs(target_address - (current_address + instruction_length)) + 1
                    # Subtract 1 if jumping forward, keep +1 if jumping backward
                    raw_offset = abs(label_address - (address + instruction_length))
                    if label_address > address:
                        # Jumping forward
                        offset = raw_offset + 1
                    else:
                        # Jumping backward
                        offset = raw_offset - 1

                    # Validate offset fits in 8 bits (0-255)
                    if offset > 255:
                        self.errors.append(
                            f"Offset to label '{label_name}' at address {address} is too large ({offset}), maximum is 255")
                        continue


                    # Replace the reference with the calculated offset
                    start, end = match.span()
                    current_line = current_line[:start] + str(offset) + current_line[end:]

                # Update the line if it was modified
                if current_line != original_line:
                    addressed_array[address] = current_line

            return len(self.errors) == 0

        except Exception as e:
            self.errors.append(f"Error replacing label references: {e}")
            return False

    def validate_label_references(self, code_lines: List[str], label_addresses: Dict[str, int]) -> bool:
        """
        Validate that all label references in the code exist in the label_addresses dictionary
        This is a validation-only method that doesn't modify the code

        Args:
            code_lines: List of code lines to check for label references
            label_addresses: Dictionary of defined labels and their addresses

        Returns:
            True if all references are valid, False if errors found
        """
        try:
            import re

            # Pattern to match T@LABELNAME or B@LABELNAME
            pattern_prefixed = r'\b([TB])@([A-Za-z0-9_]+)\b'

            # Pattern for direct label references
            pattern_direct = r'\b(?<![@])([A-Za-z0-9_]+)(?![@])\b'

            validation_errors = []

            for line_num, line in enumerate(code_lines):
                # Check prefixed references
                matches = re.finditer(pattern_prefixed, line)
                for match in matches:
                    label_name = match.group(2)  # The label name
                    full_match = match.group(0)  # The complete match

                    # Check if the label exists
                    if label_name not in label_addresses:
                        validation_errors.append(f"Undefined label reference '{full_match}' at line {line_num + 1}")

                # Check direct references (only if they're known labels)
                direct_matches = re.finditer(pattern_direct, line)
                for match in direct_matches:
                    potential_label = match.group(1)

                    # Skip numbers
                    if potential_label.isdigit():
                        continue

                    # Skip instruction names
                    is_instruction = False
                    for inst_data in self.instructions.values():
                        if inst_data['name'] == potential_label:
                            is_instruction = True
                            break

                    if is_instruction:
                        continue

                    # If it looks like a label reference but doesn't exist, that's an error
                    if potential_label not in label_addresses:
                        # This might be a parameter or something else, so we'll be lenient here
                        # and only report it if it looks like it should be a label
                        continue

            if validation_errors:
                self.errors.extend(validation_errors)
                return False

            return True

        except Exception as e:
            self.errors.append(f"Error validating label references: {e}")
            return False

    def get_label_address(self, label_name: str, label_addresses: Dict[str, int]) -> Optional[int]:
        """
        Get the address of a specific label

        Args:
            label_name: The name of the label to look up
            label_addresses: Dictionary of label addresses

        Returns:
            The address of the label, or None if not found
        """
        return label_addresses.get(label_name)

    def add_reserved_keyword(self, keyword: str) -> None:
        """
        Add a new reserved keyword that cannot be used as a label name

        Args:
            keyword: The keyword to add (will be converted to uppercase)
        """
        self.reserved_keywords.add(keyword.upper())

    def remove_reserved_keyword(self, keyword: str) -> None:
        """
        Remove a reserved keyword

        Args:
            keyword: The keyword to remove (will be converted to uppercase)
        """
        self.reserved_keywords.discard(keyword.upper())

    def get_reserved_keywords(self) -> set:
        """
        Get a copy of the current reserved keywords set

        Returns:
            Set of reserved keywords
        """
        return self.reserved_keywords.copy()

    def get_errors(self) -> List[str]:
        """Return the list of label processing errors"""
        return self.errors.copy()

    def has_errors(self) -> bool:
        """Check if there are any label processing errors"""
        return len(self.errors) > 0

    def clear_errors(self) -> None:
        """Clear all accumulated errors"""
        self.errors = []