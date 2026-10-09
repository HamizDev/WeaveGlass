#!/usr/bin/env python3
"""Deterministic catalog generation from the ORIGINAL handoff markdown. Never infer defaults."""
import re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=(root/'reference/CONFIG_KEYS.md').read_text(encoding='utf-8-sig')
blocks=re.findall(r'^## (.+?)（(\d+)）\s*\n```\n(.*?)\n```',source,re.M|re.S)
assert len(blocks)==14
seen=set()
groups=[]
for name,decl,body in blocks:
    keys=[s.strip() for s in body.splitlines() if s.strip()]
    assert int(decl)==len(keys),(name,len(keys))
    for key in keys:
        assert key not in seen,key
        seen.add(key)
    groups.append((name,keys))
assert len(seen)==1067

def quote(s):
    return '@"' + s.replace('\\','\\\\').replace('"','\\"') + '"'

lines=['// GENERATED FILE — do not edit. Run python3 scripts/generate_catalog.py.',
       '#import "WGConfigCatalog.h"', '', '@implementation WGConfigCatalog',
       '+ (NSDictionary<NSString *,NSArray<NSString *> *> *)groups {',
       '    static NSDictionary<NSString *,NSArray<NSString *> *> *groups;',
       '    static dispatch_once_t once;',
       '    dispatch_once(&once, ^{ groups = @{']
for name,keys in groups:
    lines.append('        '+quote(name)+': @[')
    for key in keys:
        lines.append('            '+quote(key)+',')
    lines.append('        ],')
lines += ['    }; });','    return groups;','}',
          '+ (NSArray<NSString *> *)groupNames {',
          '    return @['+ ', '.join(quote(name) for name,_ in groups)+'];','}',
          '+ (NSArray<NSString *> *)keysForGroup:(NSString *)group { return [self groups][group] ?: @[]; }',
          '+ (NSArray<NSString *> *)allKeys {',
          '    static NSArray<NSString *> *keys;',
          '    static dispatch_once_t once;',
          '    dispatch_once(&once, ^{ NSMutableArray *result = [NSMutableArray array];',
          '        for (NSString *name in [self groupNames]) [result addObjectsFromArray:[self keysForGroup:name]];',
          '        keys = [result copy];','    });','    return keys;','}',
          '+ (BOOL)containsKey:(NSString *)key {',
          '    static NSSet<NSString *> *catalog;',
          '    static dispatch_once_t once;',
          '    dispatch_once(&once, ^{ catalog = [NSSet setWithArray:[self allKeys]]; });',
          '    return [catalog containsObject:key];','}', '@end','']
out=root/'Sources/Core/WGConfigCatalog.m'
out.write_text('\n'.join(lines),encoding='utf-8')
print(f'Generated {out.relative_to(root)}: {len(groups)} groups / {len(seen)} keys')
