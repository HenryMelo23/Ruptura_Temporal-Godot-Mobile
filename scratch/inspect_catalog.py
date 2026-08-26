import json

with open('docs/catalogo_temporal_textos.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for tab in data.get('abas', []):
    print(f"Tab {tab.get('indice')}: {tab.get('id')} ({tab.get('rotulo')}) - {len(tab.get('entradas', []))} entries")
    for entry in tab.get('entradas', []):
        eid = entry.get('id')
        name = entry.get('nome')
        print(f"  - {eid}: {name}")
