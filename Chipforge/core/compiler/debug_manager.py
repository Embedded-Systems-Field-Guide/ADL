from pathlib import Path
from typing import Optional, Dict, Any
import json
from datetime import datetime


class DebugManager:
    """
    Manages debug output files for the ECF compiler
    Handles creating debug directory and saving various output stages
    """

    def __init__(self, project_dir: Path, base_name: str):
        self.project_dir = project_dir
        self.base_name = base_name
        self.debug_dir = project_dir / "Debug"
        self.debug_dir.mkdir(exist_ok=True)

    def save_stage(self, stage_name: str, content: str, extension: str = "txt") -> Path:
        """
        Save a compilation stage to debug directory

        Args:
            stage_name: Name of the stage (e.g., "PARSED", "SPACED")
            content: Content to save
            extension: File extension (default: "txt")

        Returns:
            Path to the saved file
        """
        filename = f"{self.base_name}_{stage_name}.{extension}"
        file_path = self.debug_dir / filename

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

        return file_path

    def save_json_stage(self, stage_name: str, data: Dict[str, Any]) -> Path:
        """Save structured data as JSON"""
        return self.save_stage(stage_name, json.dumps(data, indent=2), "json")

    def save_compilation_log(self, errors: list, warnings: list = None, info: list = None) -> Path:
        """Save compilation log with errors, warnings, and info"""
        log_content = []
        log_content.append(f"ECF Compilation Log - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        log_content.append("=" * 60)

        if errors:
            log_content.append(f"\nERRORS ({len(errors)}):")
            for i, error in enumerate(errors, 1):
                log_content.append(f"  {i}. {error}")

        if warnings:
            log_content.append(f"\nWARNINGS ({len(warnings)}):")
            for i, warning in enumerate(warnings, 1):
                log_content.append(f"  {i}. {warning}")

        if info:
            log_content.append(f"\nINFO ({len(info)}):")
            for i, msg in enumerate(info, 1):
                log_content.append(f"  {i}. {msg}")

        if not errors and not warnings:
            log_content.append("\nNo errors or warnings - compilation successful!")

        return self.save_stage("LOG", "\n".join(log_content), "log")

    def save_project_summary(self, compiler) -> Path:
        """Save a summary of the loaded project data"""
        summary = {
            "project_settings": compiler.project_settings,
            "write_addresses_count": len(compiler.write_addresses),
            "read_addresses_count": len(compiler.read_addresses),
            "instructions_count": len(compiler.instructions),
            "write_addresses": {k: v for k, v in list(compiler.write_addresses.items())[:10]},  # First 10
            "read_addresses": {k: v for k, v in list(compiler.read_addresses.items())[:10]},  # First 10
            "instructions": {k: v for k, v in list(compiler.instructions.items())[:10]}  # First 10
        }
        return self.save_json_stage("SUMMARY", summary)

    def get_debug_files(self) -> list:
        """Get list of all debug files created"""
        if not self.debug_dir.exists():
            return []
        return [f for f in self.debug_dir.glob(f"{self.base_name}_*")]

    def clear_debug_files(self):
        """Clear all debug files for this project"""
        for file in self.get_debug_files():
            file.unlink()