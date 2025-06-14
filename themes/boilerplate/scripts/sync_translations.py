#!/usr/bin/env python3
# filepath: /Users/viktorzeman/work/photomaticai-hugo/themes/boilerplate/scripts/sync_translations.py

import os
import yaml
import sys
from pathlib import Path

def load_yaml_file(file_path):
    """Load a YAML file and return its contents."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return yaml.safe_load(file) or {}
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return {}

def save_yaml_file(file_path, data):
    """Save data to a YAML file, preserving comments if possible."""
    try:
        # First, read the original file to preserve comments and structure
        original_content = ""
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                original_content = file.read()
        except FileNotFoundError:
            pass
        
        # Create a dictionary of existing keys and their line numbers
        existing_keys = {}
        if original_content:
            lines = original_content.split('\n')
            for i, line in enumerate(lines):
                if ':' in line and not line.strip().startswith('#'):
                    key = line.split(':', 1)[0].strip()
                    existing_keys[key] = i
        
        # Prepare new content
        new_content = []
        added_keys = []
        
        # Add original content with comments
        if original_content:
            new_content = original_content.split('\n')
        
        # Add missing keys
        for key, value in data.items():
            if key not in existing_keys:
                added_keys.append(key)
                new_content.append(f'{key}: "{value}"')
        
        # Write the content back to the file
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write('\n'.join(new_content))
        
        return added_keys
    except Exception as e:
        print(f"Error saving {file_path}: {e}")
        return []

def sync_translations(i18n_dir, test_mode=False):
    """Synchronize translations across language files."""
    i18n_path = Path(i18n_dir)
    
    # Get the English translations as reference
    en_file = i18n_path / 'en.yaml'
    if not en_file.exists():
        print(f"Error: English translation file {en_file} not found.")
        return
    
    en_translations = load_yaml_file(en_file)
    if not en_translations:
        print("Error: Could not load English translations.")
        return
    
    # If in test mode, don't make any changes but print what would happen
    if test_mode:
        # Process each language file
        language_files = [f for f in i18n_path.glob('*.yaml') if f.name != 'en.yaml']
        for lang_file in language_files:
            lang_code = lang_file.stem
            # Load existing translations
            lang_translations = load_yaml_file(lang_file)
            
            # Find missing keys
            missing_keys = {}
            for key, value in en_translations.items():
                if key not in lang_translations:
                    missing_keys[key] = value
            
            if missing_keys:
                print(f"TEST MODE: Would add {len(missing_keys)} missing keys to {lang_code}.yaml:")
                for key, value in missing_keys.items():
                    print(f"  - {key}: \"{value}\"")
            else:
                print(f"TEST MODE: No missing keys in {lang_code}.yaml")
        return
    
    # Process each language file
    language_files = [f for f in i18n_path.glob('*.yaml') if f.name != 'en.yaml']
    total_additions = 0
    
    for lang_file in language_files:
        lang_code = lang_file.stem
        print(f"Processing {lang_code}...")
        
        # Load existing translations
        lang_translations = load_yaml_file(lang_file)
        
        # Find missing keys
        missing_keys = {}
        for key, value in en_translations.items():
            if key not in lang_translations:
                missing_keys[key] = value
        
        # Add missing keys to the language file
        if missing_keys:
            added_keys = save_yaml_file(lang_file, missing_keys)
            if added_keys:
                print(f"  Added {len(added_keys)} missing keys to {lang_code}.yaml")
                total_additions += len(added_keys)
        else:
            print(f"  No missing keys in {lang_code}.yaml")
    
    print(f"Sync complete. Added {total_additions} translations across all language files.")

if __name__ == "__main__":
    import argparse
    
    # Set up command line arguments
    parser = argparse.ArgumentParser(description="Synchronize translation keys across language files")
    parser.add_argument("--test", action="store_true", help="Run in test mode (no changes)")
    args = parser.parse_args()
    
    # Get the i18n directory path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    hugo_root = os.path.abspath(os.path.join(script_dir, '../../../'))
    theme_root = os.path.abspath(os.path.join(script_dir, '../'))
    i18n_dir = os.path.join(hugo_root, 'i18n')
    
    
    if not os.path.exists(i18n_dir):
        print(f"Error: i18n directory not found at {i18n_dir}")
        sys.exit(1)
    else:
        sync_translations(i18n_dir, args.test)

    i18n_dir = os.path.join(theme_root, 'i18n')
    if not os.path.exists(i18n_dir):
        print(f"Error: i18n directory not found at {i18n_dir}")
        sys.exit(1)
    else:
        sync_translations(i18n_dir, args.test)
