from typing import List, Tuple, Optional


class ORGHandler:
    """
    Handles ORG command validation and processing
    """

    def __init__(self):
        self.errors = []

    def validate_org_commands(self, lines: List[str]) -> bool:
        """
        Validate ORG commands for proper ordering and spacing

        Args:
            lines: List of all lines in the code

        Returns:
            True if ORG commands are valid, False if errors found
        """
        try:
            self.errors = []  # Clear previous errors
            org_info = []  # List of (org_address, line_num, content_start_line)

            # Find all ORG commands and their positions
            for line_num, line in enumerate(lines):
                line = line.strip()
                if line.upper().startswith('ORG ') and line.endswith(':'):
                    # Extract ORG address
                    org_part = line[4:-1].strip()  # Remove "ORG " and ":"
                    try:
                        org_address = int(org_part)
                        org_info.append((org_address, line_num + 1, line_num + 1))  # +1 for 1-based line numbering
                    except ValueError:
                        self.errors.append(f"Line {line_num + 1}: Invalid ORG address '{org_part}', must be an integer")
                        return False

            if not org_info:
                # No ORG commands found, that's okay
                return True

            # Sort by ORG address to check ordering
            org_info_sorted = sorted(org_info, key=lambda x: x[0])

            # Check if ORGs are in order (by line number)
            for i in range(len(org_info) - 1):
                current_org = org_info[i]
                next_org = org_info[i + 1]

                # Check if addresses are in ascending order by line appearance
                if current_org[0] >= next_org[0]:
                    self.errors.append(f"Line {next_org[1]}: ORG {next_org[0]} must come after ORG {current_org[0]} "
                                       f"(line {current_org[1]}) in ascending order")
                    return False

            # Check spacing between ORGs
            for i in range(len(org_info) - 1):
                current_org_addr, current_line_num, _ = org_info[i]
                next_org_addr, next_line_num, _ = org_info[i + 1]

                # Count non-empty lines between current ORG and next ORG
                content_lines = 0
                for line_idx in range(current_line_num,
                                      next_line_num - 1):  # -1 because we don't count the next ORG line
                    if line_idx < len(lines) and lines[line_idx].strip():
                        content_lines += 1

                # Calculate available space
                available_space = next_org_addr - current_org_addr

                # Check if content fits in available space
                if content_lines > available_space:
                    self.errors.append(
                        f"Line {current_line_num}: ORG {current_org_addr} has {content_lines} lines of content "
                        f"but only {available_space} spaces available before ORG {next_org_addr} (line {next_line_num})")
                    return False

            return True

        except Exception as e:
            self.errors.append(f"Error validating ORG commands: {e}")
            return False

    def is_org_line(self, line: str) -> bool:
        """
        Check if a line is an ORG command

        Args:
            line: The line to check

        Returns:
            True if it's an ORG line, False otherwise
        """
        line = line.strip()
        return line.upper().startswith('ORG ') and line.endswith(':')

    def extract_org_address(self, line: str) -> Optional[int]:
        """
        Extract the address from an ORG command line

        Args:
            line: The ORG line (e.g., "ORG 100:")

        Returns:
            The ORG address as integer, or None if invalid
        """
        try:
            line = line.strip()
            if not self.is_org_line(line):
                return None

            org_part = line[4:-1].strip()  # Remove "ORG " and ":"
            return int(org_part)
        except ValueError:
            return None

    def get_errors(self) -> List[str]:
        """Return the list of ORG validation errors"""
        return self.errors.copy()

    def has_errors(self) -> bool:
        """Check if there are any ORG validation errors"""
        return len(self.errors) > 0