#!/usr/bin/env python3
"""
Generate Translation URLs Map

This script creates a mapping of English URLs to their translations in all other languages.
It processes all content files in content/en/, identifies their URLs (either from frontmatter 
or from file path), then finds corresponding files in other language directories and maps
their URLs.

Usage:
    python translation-urls.py

Output:
    Creates /data/translation_urls.yaml with the mapping structure

Requirements:
    pip install pyyaml frontmatter
"""

import os
import frontmatter
from frontmatter import TOMLHandler # Add this import
import yaml
import argparse
from pathlib import Path
from collections import defaultdict

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Generate translation URLs mapping")
    parser.add_argument("--hugo-root", type=str, 
                        default=os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..")),
                        help="Hugo root directory (default: three levels up from script location)")
    parser.add_argument("--content-dir", type=str, default="content",
                        help="Content directory relative to Hugo root (default: content)")
    parser.add_argument("--output-file", type=str, default="data/translation_urls.yaml",
                        help="Output file relative to Hugo root (default: data/translation_urls.yaml)")
    return parser.parse_args()

def get_url_from_file(file_path, lang, relative_path):
    """Extract URL from a markdown file, either from frontmatter or derive from path."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            post = frontmatter.load(f, handler=TOMLHandler()) # Use TOMLHandler

        # Check if URL is defined in frontmatter
        if 'url' in post.metadata:
            url = post.metadata['url']
            # Ensure URL ends with /
            if not url.endswith('/'):
                url = url + '/'
            return url
        
        # Derive URL from file path
        # Remove .md extension and handle _index.md files
        url_path = relative_path
        if url_path.endswith('.md'):
            url_path = url_path[:-3]
        
        # Handle _index.md files - they represent the directory URL
        if url_path.endswith('/_index'):
            url_path = url_path[:-7]  # Remove /_index (7 characters)
        elif url_path == '_index':
            url_path = ''  # Root index
        
        # Ensure URL starts with /
        if url_path and not url_path.startswith('/'):
            url_path = '/' + url_path
        elif not url_path:
            url_path = '/'
        
        # Ensure URL ends with /
        if not url_path.endswith('/'):
            url_path = url_path + '/'
        
        return url_path
        
    except Exception as e:
        print(f"Error processing file {file_path}: {e}")
        return None

def get_all_languages(content_dir):
    """Get list of all language directories."""
    languages = []
    if os.path.exists(content_dir):
        for item in os.listdir(content_dir):
            item_path = os.path.join(content_dir, item)
            if os.path.isdir(item_path) and not item.startswith('_'):
                languages.append(item)
    return sorted(languages)

def process_english_files(hugo_root, content_dir):
    """Process all English content files and extract their URLs."""
    en_dir = os.path.join(hugo_root, content_dir, 'en')
    english_files = {}
    
    if not os.path.exists(en_dir):
        print(f"English content directory not found: {en_dir}")
        return english_files
    
    print(f"Processing English files in: {en_dir}")
    
    # Walk through all English content files
    for root, dirs, files in os.walk(en_dir):
        for file in files:
            if file.endswith('.md'):
                file_path = os.path.join(root, file)
                
                # Get relative path from en directory
                relative_path = os.path.relpath(file_path, en_dir)
                
                # Get URL for this file
                url = get_url_from_file(file_path, 'en', relative_path)
                
                if url:
                    english_files[relative_path] = {
                        'url': url,
                        'file_path': file_path
                    }
    
    print(f"Found {len(english_files)} English content files")
    return english_files

def find_translation_urls(hugo_root, content_dir, english_files, languages):
    """Find translation URLs for all English files."""
    translation_map = {}
    
    for rel_path, en_data in english_files.items():
        en_url = en_data['url']
        translations = {}
        
        # Look for the same relative path in all language directories (including English)
        for lang in languages:
            lang_file_path = os.path.join(hugo_root, content_dir, lang, rel_path)
            
            if os.path.exists(lang_file_path):
                # Get URL for this translation
                translation_url = get_url_from_file(lang_file_path, lang, rel_path)
                
                if translation_url:
                    translations[lang] = translation_url
        
        # Add to map using file path as key (always include, even if only English exists)
        translation_map[rel_path] = translations
    
    return translation_map

def generate_yaml_output(translation_map, hugo_root, output_file):
    """Generate YAML file with translation URL mapping."""
    output_path = os.path.join(hugo_root, output_file)
    
    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Sort by English URL for consistent output
    sorted_map = dict(sorted(translation_map.items()))
    
    print(f"Generating YAML file: {output_path}")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        yaml.dump(sorted_map, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    
    print(f"Translation URLs mapping generated: {output_path}")
    print(f"Total content files processed: {len(sorted_map)}")
    
    # Print summary statistics
    lang_stats = defaultdict(int)
    for file_path, translations in sorted_map.items():
        for lang in translations.keys():
            lang_stats[lang] += 1
    
    print("\nTranslation statistics:")
    for lang, count in sorted(lang_stats.items()):
        print(f"  {lang}: {count} files")

def main():
    """Main function."""
    args = parse_args()
    
    # Set up paths
    content_dir_path = os.path.join(args.hugo_root, args.content_dir)
    
    # Get all available languages
    languages = get_all_languages(content_dir_path)
    print(f"Found languages: {', '.join(languages)}")
    
    # Process English files
    english_files = process_english_files(args.hugo_root, args.content_dir)
    
    if not english_files:
        print("No English content files found")
        return
    
    # Find translations
    print("Finding translation URLs...")
    translation_map = find_translation_urls(args.hugo_root, args.content_dir, english_files, languages)
    
    # Generate output
    generate_yaml_output(translation_map, args.hugo_root, args.output_file)

if __name__ == "__main__":
    main()