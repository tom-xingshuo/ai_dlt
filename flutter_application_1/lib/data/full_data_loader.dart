/// 全量组合数据载入（移植自 full_data.py）。
///
/// 资产为 zlib 压缩包; 解压后每 4 字节打包 5 个 6bit 号码
/// (chunk>>24 & 0x3F, >>18, >>12, >>6, &0x3F), 共 324632 组。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

const String kGroupAssetPath = 'assets/data/full_groups.z';
const int kTotalGroups = 324632;

/// 读取并解压资产, 返回扁平字节(每组5字节升序号码, 共 count*5)。
Future<Uint8List> loadGroupFlatBytes() async {
  final data = await rootBundle.load(kGroupAssetPath);
  final compressed =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final raw = Uint8List.fromList(zlib.decode(compressed));
  if (raw.length != kTotalGroups * 4) {
    throw StateError('全量数据大小异常: ${raw.length}');
  }
  final bd = ByteData.sublistView(raw);
  final flat = Uint8List(kTotalGroups * 5);
  var w = 0;
  for (var off = 0; off + 4 <= raw.length; off += 4) {
    final chunk = bd.getUint32(off, Endian.big);
    flat[w++] = (chunk >> 24) & 0x3F;
    flat[w++] = (chunk >> 18) & 0x3F;
    flat[w++] = (chunk >> 12) & 0x3F;
    flat[w++] = (chunk >> 6) & 0x3F;
    flat[w++] = chunk & 0x3F;
  }
  return flat;
}
