# -*- coding: utf-8 -*-
"""生成 full_data.py: 大乐透前区全量数据内嵌文件(便于打包exe)。

运行环境: conda py311
数据: C(35,5)=324632 组组合, 每组5个号升序。
存储: 每个号码6bit(1~35), 5个号30bit打包进4字节, zlib压缩, base64编码。
"""

import base64
import os
import zlib
from itertools import combinations

OUT = r"full_data.py"
TOTAL = 324632  # C(35,5)

# 1) 打包: 每组5个号 -> 4字节
chunks = bytearray()
count = 0
for nums in combinations(range(1, 36), 5):
    v = 0
    for n in nums:
        v = (v << 6) | n  # 每号6bit, 1~35 均可表示
    chunks += v.to_bytes(4, "big")
    count += 1
assert count == TOTAL and len(chunks) == TOTAL * 4

# 2) 压缩 + base64
b64 = base64.b64encode(zlib.compress(bytes(chunks), 9)).decode("ascii")
lines = [b64[i:i + 100] for i in range(0, len(b64), 100)]

# 3) 回读校验
decoded = zlib.decompress(base64.b64decode(b64))
assert decoded == bytes(chunks), "压缩回读校验失败"

# 4) 写出 full_data.py
body = f'''# -*- coding: utf-8 -*-
"""大乐透前区全量数据对象(内嵌, 无外部文件依赖, 便于打包exe)。

由 make_full_data.py 自动生成, 请勿手工修改。
数据: C(35,5)={TOTAL} 组前区组合, 每组5个号, 升序排列。
存储: 每个号码6bit, 5个号打包4字节 -> zlib压缩 -> base64。
导入本模块即得到 FULL_GROUPS 列表(324632个元组)。
"""
import base64
import zlib

TOTAL = {TOTAL}

_DATA_B64 = (
'''

for line in lines:
    body += f'    "{line}"\n'
body += ''')

def decode_groups():
    """解码内嵌数据, 返回全量组合列表 [(n1,n2,n3,n4,n5), ...]。"""
    raw = zlib.decompress(base64.b64decode(_DATA_B64))
    groups = []
    append = groups.append
    for off in range(0, len(raw), 4):
        chunk = int.from_bytes(raw[off:off + 4], "big")
        append(((chunk >> 24) & 0x3F, (chunk >> 18) & 0x3F,
                (chunk >> 12) & 0x3F, (chunk >> 6) & 0x3F, chunk & 0x3F))
    return groups


FULL_GROUPS = decode_groups()
'''

with open(OUT, "w", encoding="utf-8") as f:
    f.write(body)

print(f"已生成 {OUT}, 文件大小 {os.path.getsize(OUT) / 1024:.0f} KB, 组数 {count}")
