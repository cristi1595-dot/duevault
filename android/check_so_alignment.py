import os
import sys
import zipfile
import tempfile
import subprocess
import glob

# Try to find llvm-readelf
def find_readelf():
    # 1. Direct path from active configuration
    default_path = r"C:\Users\crist\AppData\Local\Android\sdk\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-readelf.exe"
    if os.path.exists(default_path):
        return default_path
    
    # 2. General SDK scan
    sdk_ndk_base = r"C:\Users\crist\AppData\Local\Android\sdk\ndk"
    if os.path.exists(sdk_ndk_base):
        versions = os.listdir(sdk_ndk_base)
        if versions:
            # Sort by version number to get the latest
            versions.sort(key=lambda s: [int(u) if u.isdigit() else u for u in s.split('.')])
            latest_version = versions[-1]
            path = os.path.join(sdk_ndk_base, latest_version, "toolchains", "llvm", "prebuilt", "windows-x86_64", "bin", "llvm-readelf.exe")
            if os.path.exists(path):
                return path
                
    # 3. Path search
    for name in ["llvm-readelf.exe", "llvm-readelf", "readelf"]:
        try:
            subprocess.run([name, "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            return name
        except FileNotFoundError:
            pass
            
    return None

def check_alignment(so_path, readelf_path, zip_path):
    print(f"Checking: {zip_path}")
    try:
        result = subprocess.run([readelf_path, "-l", so_path], capture_output=True, text=True, check=True)
        lines = result.stdout.splitlines()
        
        load_segments_found = False
        non_compliant_segments = []
        
        # We need to find the Align column index or parse the table
        # Typical header line:
        # Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
        # Or:
        # Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
        # LOAD           0x000000 0x00000000 0x00000000 0x12345 0x12345 R   0x1000
        
        for line in lines:
            parts = line.split()
            if not parts:
                continue
            
            if parts[0] == "LOAD":
                load_segments_found = True
                # The alignment is typically the last element on the LOAD line
                align_str = parts[-1]
                
                # Parse alignment
                try:
                    if align_str.startswith("0x") or align_str.startswith("0X"):
                        align = int(align_str, 16)
                    else:
                        align = int(align_str)
                except ValueError:
                    print(f"  Warning: Could not parse alignment value '{align_str}' in line: {line}")
                    continue
                
                print(f"  LOAD Segment Alignment: {align_str} ({align} bytes)")
                
                # Check if it is less than 16 KB (16384 bytes)
                if align < 16384:
                    non_compliant_segments.append((line, align))
                    
        if not load_segments_found:
            print("  Warning: No LOAD segments found in this ELF file.")
            return False
            
        if non_compliant_segments:
            print("  [FAIL] Contains 4KB aligned LOAD segments:")
            for line, align in non_compliant_segments:
                print(f"    - Alignment: {align} bytes | Line: {line}")
            return False
            
        print("  [PASS] All LOAD segments are aligned to 16KB or greater.")
        return True
        
    except Exception as e:
        print(f"  Error running readelf: {e}")
        return False

def main():
    readelf_path = find_readelf()
    if not readelf_path:
        print("ERROR: llvm-readelf.exe not found! Please check your NDK installation.")
        sys.exit(1)
        
    print(f"Using readelf tool at: {readelf_path}")
    
    # Locate bundle or APK
    workspace_root = r"d:\Aplicatii\DueVault_app"
    
    # Look for built outputs
    search_patterns = [
        os.path.join(workspace_root, "build", "app", "outputs", "bundle", "release", "*.aab"),
        os.path.join(workspace_root, "build", "app", "outputs", "bundle", "debug", "*.aab"),
        os.path.join(workspace_root, "build", "app", "outputs", "apk", "release", "*.apk"),
        os.path.join(workspace_root, "build", "app", "outputs", "apk", "debug", "*.apk"),
    ]
    
    archive_path = None
    for pattern in search_patterns:
        matches = glob.glob(pattern)
        if matches:
            # Take the newest match
            matches.sort(key=os.path.getmtime)
            archive_path = matches[-1]
            break
            
    if not archive_path:
        print("ERROR: No compiled .aab or .apk files found. Run 'flutter build appbundle' or 'flutter build apk' first.")
        sys.exit(1)
        
    print(f"Found archive: {archive_path}")
    
    # Extract .so files to a temp directory
    all_passed = True
    so_files_found = 0
    
    with tempfile.TemporaryDirectory() as temp_dir:
        with zipfile.ZipFile(archive_path, 'r') as zip_ref:
            # Collect all .so files from the archive
            for file_info in zip_ref.infolist():
                if file_info.filename.endswith('.so'):
                    # Skip 32-bit architectures as they are exempt from 16KB alignment requirements
                    is_32bit = "armeabi-v7a" in file_info.filename or "/x86/" in file_info.filename or file_info.filename.startswith("lib/x86/") or file_info.filename.startswith("base/lib/x86/")
                    if is_32bit:
                        print(f"Skipping 32-bit library (exempt from 16KB alignment): {file_info.filename}")
                        continue
                        
                    so_files_found += 1
                    # Extract the file
                    # In an AAB, native libs are in base/lib/arm64-v8a/libsome.so
                    # In an APK, they are in lib/arm64-v8a/libsome.so
                    extracted_path = zip_ref.extract(file_info.filename, temp_dir)
                    
                    # Run alignment check
                    passed = check_alignment(extracted_path, readelf_path, file_info.filename)
                    if not passed:
                        all_passed = False
                        
    if so_files_found == 0:
        print("No native (.so) files found in the archive.")
        print("Note: If the application only contains pure Dart/Kotlin code with no native dependencies, it is 16KB compliant by default.")
    elif all_passed:
        print("\nSUCCESS: All native (.so) libraries are 16KB page-aligned!")
    else:
        print("\nFAILURE: Some native (.so) libraries are NOT 16KB page-aligned!")
        sys.exit(1)

if __name__ == "__main__":
    main()
