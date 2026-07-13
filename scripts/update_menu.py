#!/usr/bin/env python3
import re
from pathlib import Path

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

PAGE_URL = 'https://ispartasehir.saglik.gov.tr/TR-471595/yemek-listesi.html'
PATTERN = r'https://dosyahastane\.saglik\.gov\.tr/Eklenti/[^"\']+?\.xlsx'

html = requests.get(PAGE_URL, timeout=30, verify=False).text
matches = re.findall(PATTERN, html, flags=re.I)
if not matches:
    raise SystemExit('xlsx linki bulunamadı')

download_url = matches[-1]
out = Path('data/yemek_listesi.xlsx')
out.parent.mkdir(parents=True, exist_ok=True)
out.write_bytes(requests.get(download_url, timeout=60, verify=False).content)
print(download_url)
