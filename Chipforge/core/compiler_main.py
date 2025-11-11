from pathlib import Path
from core.compiler import DebugManager, ECFFileLoader, ADDW_SCHEMA, ADDR_SCHEMA, INST_SCHEMA


class ECFCompiler:
    def __init__(self):
        self.project_settings = {}
        self.write_addresses = {}  # ADDW - keyed by address
        self.read_addresses = {}  # ADDR - keyed by address
        self.instructions = {}  # INST - keyed by address
        self.errors = []  # List to store validation errors
        self.base_name = ""  # Store project base name
        self.proj_dir = None  # Store project directory
        self.debug_manager = None  # Will be initialized when project is loaded

    def load_project(self, proj_file_path: str) -> bool:
        """
        Load ECF project and associated address files

        Args:
            proj_file_path: Path to the .ecfproj file

        Returns:
            True if successful, False otherwise
        """
        try:

            # Clear previous errors
            self.errors = []

            proj_path = Path(proj_file_path)

            if not proj_path.exists():
                self.errors.append(f"Error: Project file {proj_file_path} not found")
                return False


            # Store project info
            self.base_name = proj_path.stem
            self.proj_dir = proj_path.parent

            # Initialize debug manager
            try:
                from core.compiler import DebugManager
                self.debug_manager = DebugManager(self.proj_dir, self.base_name)
            except ImportError as e:
                self.errors.append(f"Error: Could not import debug_manager: {e}")
                return False

            # Load project settings
            if not self._load_project_file(proj_path):
                return False

            # Load address files using abstracted loader
            try:
                from core.compiler import ECFFileLoader, ADDW_SCHEMA, ADDR_SCHEMA, INST_SCHEMA
            except ImportError as e:
                self.errors.append(f"Error: Could not import file_loader: {e}")
                return False

            loader = ECFFileLoader()

            # Calculate file paths relative to project directory
            source_dir = self.proj_dir / "source"
            addw_file = source_dir / f"{self.base_name}.ecfADDW"
            addr_file = source_dir / f"{self.base_name}.ecfADDR"
            inst_file = source_dir / f"{self.base_name}.ecfINST"

            # Check if source directory exists
            if not source_dir.exists():
                self.errors.append(f"Error: Source directory not found: {source_dir}")
                return False

            # Load files using schemas
            self.write_addresses = loader.load_tabbed_file(addw_file, ADDW_SCHEMA)
            if loader.has_errors():
                self.errors.extend(loader.get_errors())

            self.read_addresses = loader.load_tabbed_file(addr_file, ADDR_SCHEMA)
            if loader.has_errors():
                self.errors.extend(loader.get_errors())

            self.instructions = loader.load_tabbed_file(inst_file, INST_SCHEMA)
            if loader.has_errors():
                self.errors.extend(loader.get_errors())

            # Cross-file validation
            self._validate_cross_file_conflicts()

            if self.errors:
                return False

            # Add address 0 as "do nothing" for all spaces
            self._add_do_nothing_entries()


            # Save project summary to debug
            self.debug_manager.save_project_summary(self)

            # Process ASM file if basic validation passed
            if not self.errors:
                return self._process_asm_file()

            return True

        except Exception as e:
            import traceback
            self.errors.append(f"Unexpected error loading project: {e}")
            return False

    def _process_asm_file(self) -> bool:
        """Process the ASM file through parser, spacer, addresser, and implementation, save to Debug folder"""
        try:

            # Import parser, spacer, addresser, and implementation
            try:
                from core.compiler import ECFParser
            except ImportError as e:
                self.errors.append(f"Error: Could not import parser: {e}")
                return False

            try:
                from core.compiler import ECFSpacer
            except ImportError as e:
                self.errors.append(f"Error: Could not import spacer: {e}")
                return False

            try:
                from core.compiler import ECFAddresser
            except ImportError as e:
                self.errors.append(f"Error: Could not import addresser: {e}")
                return False

            try:
                from core.compiler import ECFImplementation
            except ImportError as e:
                self.errors.append(f"Error: Could not import implementation: {e}")
                return False

            # Locate ASM file
            asm_file = self.proj_dir / f"{self.base_name}.ecfASM"

            if not asm_file.exists():
                self.errors.append(f"ASM file not found: {asm_file}")
                return False


            # Create parser and process file
            parser = ECFParser()
            parsed_content = parser.parse_asm_file(str(asm_file))

            if parsed_content is None:
                self.errors.extend(parser.get_errors())
                return False


            # Save parsed content using debug manager
            parsed_file = self.debug_manager.save_stage("PARSED", parsed_content)
            print(f"ASM file processed and saved to: {parsed_file}")

            # Create spacer and process the parsed content
            spacer = ECFSpacer(self.instructions)
            spaced_content = spacer.space_code(parsed_content)

            if spaced_content is None:
                self.errors.extend(spacer.get_errors())
                # Save compilation log with errors
                self.debug_manager.save_compilation_log(self.errors)
                return False


            # Save spaced content using debug manager
            spaced_file = self.debug_manager.save_stage("SPACED", spaced_content)
            print(f"Spaced code generated and saved to: {spaced_file}")

            # Create addresser and process the spaced content
            addresser = ECFAddresser(self.instructions, self.write_addresses, self.read_addresses)
            addressed_content = addresser.address_code(spaced_content)

            if addressed_content is None:
                self.errors.extend(addresser.get_errors())
                # Save compilation log with errors
                self.debug_manager.save_compilation_log(self.errors)
                return False


            # Save addressed content using debug manager
            addressed_file = self.debug_manager.save_stage("ADDRESSED", addressed_content)
            print(f"Addressed code generated and saved to: {addressed_file}")

            # Create implementation and process the addressed content
            implementation = ECFImplementation(self.instructions, self.write_addresses, self.read_addresses)
            implemented_content = implementation.implement_code(addressed_content)

            if implemented_content is None:
                self.errors.extend(implementation.get_errors())
                # Save compilation log with errors
                self.debug_manager.save_compilation_log(self.errors)
                return False

            # Save implemented content using debug manager
            implemented_file = self.debug_manager.save_stage("IMPLEMENTED", implemented_content)
            print(f"Implemented code generated and saved to: {implemented_file}")

            # Save successful compilation log
            self.debug_manager.save_compilation_log(self.errors, info=["Compilation completed successfully"])
            return True

        except Exception as e:
            import traceback
            self.errors.append(f"Error processing ASM file: {e}")
            # Save compilation log with errors
            if self.debug_manager:
                self.debug_manager.save_compilation_log(self.errors)
            return False

    def _load_project_file(self, proj_path: Path) -> bool:
        """Load the .ecfproj settings file"""
        try:
            with open(proj_path, 'r') as f:
                line_count = 0
                for line in f:
                    line_count += 1
                    line = line.strip()
                    if '=' in line:
                        key, value = line.split('=', 1)
                        # Try to convert to appropriate type
                        if value.lower() == 'true':
                            self.project_settings[key] = True
                        elif value.lower() == 'false':
                            self.project_settings[key] = False
                        elif value.isdigit():
                            self.project_settings[key] = int(value)
                        else:
                            self.project_settings[key] = value
            return True
        except Exception as e:
            self.errors.append(f"Error loading project file: {e}")
            return False

    def _validate_cross_file_conflicts(self):
        """Cross-file validation - currently no conflicts checked as duplicates are allowed across files"""
        # Names can be duplicated across different files (e.g., RAM can be both readable and writable)
        # Only within-file duplicates are not allowed, which are already checked in individual file validation
        pass

    def _add_do_nothing_entries(self):
        """Add address 0 as 'do nothing' instruction for all address spaces"""
        if 0 not in self.write_addresses:
            self.write_addresses[0] = {'name': 'NOP', 'description': 'Do nothing'}
        if 0 not in self.read_addresses:
            self.read_addresses[0] = {'name': 'NOP', 'description': 'Do nothing'}
        if 0 not in self.instructions:
            self.instructions[0] = {
                'name': 'NOP',
                'length': 1,
                'leading_nops': 0,
                'format': 'INS',
                'description': 'Do nothing instruction'
            }

    def get_errors(self) -> list:
        """Return the list of validation errors"""
        return self.errors.copy()

    def has_errors(self) -> bool:
        """Check if there are any validation errors"""
        return len(self.errors) > 0

    def print_errors(self):
        """Print all validation errors"""
        if self.errors:
            print(f"\n=== VALIDATION ERRORS ({len(self.errors)} found) ===")
            for i, error in enumerate(self.errors, 1):
                print(f"{i}. {error}")
        else:
            print("No validation errors found.")

    def print_summary(self):
        """Print a summary of loaded data for testing"""
        print(f"\n=== ECF Project Summary ===")
        print(f"Project Settings: {self.project_settings}")
        print(f"Write Addresses: {len(self.write_addresses)} entries")
        print(f"Read Addresses: {len(self.read_addresses)} entries")
        print(f"Instructions: {len(self.instructions)} entries")

        # Show a few examples
        print(f"\nSample Write Addresses:")
        for addr in sorted(list(self.write_addresses.keys())[:5]):
            entry = self.write_addresses[addr]
            print(f"  {addr}: {entry['name']} - {entry['description']}")

        print(f"\nSample Read Addresses:")
        for addr in sorted(list(self.read_addresses.keys())[:5]):
            entry = self.read_addresses[addr]
            print(f"  {addr}: {entry['name']} - {entry['description']}")

        print(f"\nSample Instructions:")
        for addr in sorted(list(self.instructions.keys())[:5]):
            entry = self.instructions[addr]
            print(
                f"  {addr}: {entry['name']} (len:{entry['length']}, nops:{entry['leading_nops']}) - {entry['description']}")


# Test the compiler
if __name__ == "__main__":
    compiler = ECFCompiler()

    # Test with your sample project file
    if compiler.load_project("Poll7Seg.ecfProj"):
        compiler.print_summary()
    else:
        print("Failed to load project")
        compiler.print_errors()