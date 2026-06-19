import urllib.request
import json
import re

try:
    req = urllib.request.Request('https://raw.githubusercontent.com/senegalouvert/Decoupage-Administratif/master/geojson/regions.geojson', headers={'User-Agent': 'Mozilla/5.0'})
    html = urllib.request.urlopen(req).read().decode('utf-8')
    with open('public/geo/senegal-regions.json', 'w', encoding='utf-8') as f:
        f.write(html)
    print("Downloaded regions.geojson successfully!")
except Exception as e:
    print("Error:", e)
    
try:
    req = urllib.request.Request('https://raw.githubusercontent.com/glynnbird/countriesgeojson/master/senegal.geojson', headers={'User-Agent': 'Mozilla/5.0'})
    html = urllib.request.urlopen(req).read().decode('utf-8')
    with open('public/geo/senegal-regions-fallback.json', 'w', encoding='utf-8') as f:
        f.write(html)
    print("Downloaded fallback successfully!")
except Exception as e:
    print("Error:", e)
