import os
import re
import sys

# Configuration
DIRECTORIES = ['src', 'tests', 'tools']
MAX_FILE_LINES = 500
MAX_FUNC_LINES = 50

# Regex patterns
RE_FUNC_NO_RETURN_TYPE = re.compile(r'func\s+\w+\s*\([^)]*\)\s*:(?!\s*->)')
RE_FUNC_NO_TYPE_HINT = re.compile(r'func\s+\w+\s*\(\s*([^)]*?)\s*\)')
RE_VAR_NO_TYPE = re.compile(r'var\s+\w+\s*(?:=.*)?$', re.MULTILINE)
RE_MAGIC_NUMBER = re.compile(r'(?<![#\w])(?:(?<![01])[2-9]|[1-9]\d+)(?![.\w])')
RE_HARDCODED_PATH = re.compile(r'["\'](res://|user://)[^"\']+["\']')
RE_TODO = re.compile(r'#\s*(TODO|FIXME|HACK)', re.IGNORECASE)
RE_PRINT = re.compile(r'\b(print|push_warning|push_error)\s*\(')

def review_file(file_path):
    issues = []
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    content = "".join(lines)
    
    # Check file size
    if len(lines) > MAX_FILE_LINES:
        issues.append(f"File too large: {len(lines)} lines")

    # Check function size and missing return types
    current_func = None
    func_start_line = 0
    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.strip()

        # Check for function start
        if stripped.startswith("func "):
            if current_func:
                func_len = i - func_start_line
                if func_len > MAX_FUNC_LINES:
                    issues.append(f"L{func_start_line}: Function '{current_func}' too large: {func_len} lines")
            
            current_func = stripped.split("(")[0].replace("func ", "").strip()
            func_start_line = line_num

            # Check for return type
            if "->" not in line and not line.strip().endswith(":"):
                # Check if it spans multiple lines
                j = i
                full_func_decl = line
                while ":" not in lines[j] and j < len(lines) - 1:
                    j += 1
                    full_func_decl += lines[j]
                
                if "->" not in full_func_decl:
                    issues.append(f"L{line_num}: Function '{current_func}' missing return type hint")

        # Check for missing type hints in variables
        if stripped.startswith("var "):
            if ":" not in stripped and ":=" not in stripped:
                # Basic check, might have false positives for complex declarations
                issues.append(f"L{line_num}: Variable missing type hint: {stripped}")

        # Check for magic numbers (skipping constants and export variables at top)
        if i > 20: # Crude way to skip header constants
            match = RE_MAGIC_NUMBER.search(line)
            if match and "#" not in line.split(match.group())[0]:
                # Heuristic: skip if it looks like an array index or part of a string
                if not any(c in line for c in ['[', '"', "'"]):
                     issues.append(f"L{line_num}: Possible magic number: {match.group()}")

        # Check for hardcoded paths
        match_path = RE_HARDCODED_PATH.search(line)
        if match_path:
            # Check if it's a constant
            if not stripped.startswith("const ") and "static var" not in stripped:
                issues.append(f"L{line_num}: Hardcoded path in logic: {match_path.group()}")

        # Check for TODO/FIXME/HACK
        match_todo = RE_TODO.search(line)
        if match_todo:
            issues.append(f"L{line_num}: Unresolved {match_todo.group(1)}")

        # Check for print statements (outside core/)
        if "src/core/" not in file_path.replace("\\", "/"):
            match_print = RE_PRINT.search(line)
            if match_print:
                 issues.append(f"L{line_num}: Leftover debug statement: {match_print.group(1)}()")

    # Final function length check
    if current_func:
        func_len = len(lines) - func_start_line
        if func_len > MAX_FUNC_LINES:
             issues.append(f"L{func_start_line}: Function '{current_func}' too large: {func_len} lines")

    return issues

def main():
    all_findings = {}
    for root_dir in DIRECTORIES:
        for root, _, files in os.walk(root_dir):
            for file in files:
                if file.endswith('.gd'):
                    full_path = os.path.join(root, file)
                    issues = review_file(full_path)
                    if issues:
                        all_findings[full_path] = issues

    if not all_findings:
        print("No issues found!")
        return

    for path, issues in all_findings.items():
        print(f"\n--- {path} ---")
        for issue in issues:
            print(f"  - {issue}")

if __name__ == "__main__":
    main()
