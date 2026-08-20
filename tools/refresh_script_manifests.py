#!/usr/bin/env python3
from pathlib import Path
import hashlib, re

root = Path(__file__).resolve().parents[1]
exp = root / 'exported_scripts'
idx_path = exp / 'SCRIPT_INDEX.tsv'
order_path = exp / 'SCRIPT_ORDER.md'

name_by_id = {}
if idx_path.exists():
    for line in idx_path.read_text(encoding='utf-8').splitlines():
        parts = line.split('\t')
        if len(parts) >= 3:
            name_by_id[parts[1]] = parts[2]
name_by_id['1066700'] = 'PMD AutoChess P8 Formal Cross-Gate Regression + QA Shortcut Consolidation I v1.06.67'
name_by_id['250'] = 'Main'
name_by_id['251'] = ''

pat = re.compile(r'^(\d{4})__id_(.+)\.rb$')
rows = []
for p in sorted(exp.glob('[0-9][0-9][0-9][0-9]__id_*.rb')):
    m = pat.match(p.name)
    if not m:
        continue
    idx = int(m.group(1))
    sid = m.group(2)
    data = p.read_bytes()
    name = name_by_id.get(sid, '')
    rows.append((idx, sid, name, p.name, len(data), hashlib.sha256(data).hexdigest()))

expected = list(range(652))
actual = [r[0] for r in rows]
if actual != expected:
    raise SystemExit('manifest index set mismatch: expected 0..651, got %d rows' % len(rows))

idx_text = ''.join('%d\t%s\t%s\t%s\t%d\t%s\n' % r for r in rows)
idx_path.write_text(idx_text, encoding='utf-8', newline='\n')

header = '# RPG Maker VX Script Order\n\nSource: `Data/Scripts.rvdata`\n\n**Do not reorder.** Runtime order is the numeric `index` below.\n\n'
body = ''.join('- %04d | ID `%s` | `%s` | `%s`\n' % (r[0], r[1], r[2], r[3]) for r in rows)
order_path.write_text(header + body, encoding='utf-8', newline='\n')

print('SCRIPT_COUNT=%d' % len(rows))
print('SCRIPT_INDEX_SHA256=%s' % hashlib.sha256(idx_path.read_bytes()).hexdigest())
print('SCRIPT_ORDER_SHA256=%s' % hashlib.sha256(order_path.read_bytes()).hexdigest())
print('TAIL=' + ','.join('%d:%s' % (r[0], r[1]) for r in rows[-7:]))
