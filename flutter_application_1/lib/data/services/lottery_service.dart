/// 体彩官网最新开奖获取（移植自 shrink_tool.py 的 fetch_latest_draw）。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 一期开奖结果。
class LatestDraw {
  final String drawNum;
  final String drawTime;
  final List<int> front; // 前区5号
  final List<int> back; // 后区2号

  const LatestDraw({
    required this.drawNum,
    required this.drawTime,
    required this.front,
    required this.back,
  });
}

/// 大乐透开奖 API(gameNo=85), 需带浏览器请求头否则被拦截。
const String kLotteryApi =
    'https://webapi.sporttery.cn/gateway/lottery/getHistoryPageListV1.qry'
    '?gameNo=85&provinceId=0&pageSize=1&isVerify=1&pageNo=1';

class LotteryService {
  Future<LatestDraw?> fetchLatestDraw() async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(kLotteryApi));
      req.headers.set(HttpHeaders.userAgentHeader,
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36');
      req.headers.set(
          HttpHeaders.acceptHeader, 'application/json, text/plain, */*');
      req.headers.set(HttpHeaders.refererHeader, 'https://static.sporttery.cn/');
      final resp =
          await req.close().timeout(const Duration(seconds: 10));
      if (resp.statusCode != HttpStatus.ok) {
        await resp.drain<void>();
        return null;
      }
      final body = await resp.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final item = data['value']['lastPoolDraw'] as Map<String, dynamic>;
      final allNums = (item['lotteryDrawResult'] as String)
          .trim()
          .split(RegExp(r'\s+'))
          .map(int.parse)
          .toList();
      if (allNums.length < 7) {
        return null;
      }
      final front = allNums.sublist(0, 5);
      final back = allNums.sublist(5, 7);
      if (front.length != 5 ||
          back.length != 2 ||
          !front.every((n) => n >= 1 && n <= 35)) {
        return null;
      }
      return LatestDraw(
        drawNum: item['lotteryDrawNum'] as String,
        drawTime: item['lotteryDrawTime'] as String,
        front: front,
        back: back,
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }
}
