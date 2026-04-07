import glob
import re
import os

link_html = r'''
                <a href="{{ url_for('crop.disease_detection') }}" class="nav-link">
                    <i class="fas fa-microscope"></i>
                    <span>Disease Detection</span>
                </a>'''

files = glob.glob('templates/**/*.html', recursive=True)
count = 0
for path in files:
    try:
        content = open(path, encoding='utf-8').read()
        if 'Disease Detection' not in content and 'nav-section-title">Main Menu' in content:
            new_content = re.sub(
                r'(<a href="\{\{\s*url_for\(\'crop\.crop_suggestion\'\)\s*\}\}"[^>]*>.*?</a>)',
                r'\1' + link_html,
                content,
                flags=re.IGNORECASE | re.DOTALL
            )
            
            if new_content != content:
                open(path, 'w', encoding='utf-8').write(new_content)
                print('Updated', path)
                count += 1
    except Exception as e:
        print('Error', path, e)
print(f"Updated {count} files.")
