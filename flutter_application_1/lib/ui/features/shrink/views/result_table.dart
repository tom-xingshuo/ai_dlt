/// 缩水结果表格(对应 QTableWidget: 5列, 隔行变色, 最多预览2000行)。
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/ui/core/widgets.dart';
import 'package:flutter_application_1/ui/features/shrink/view_models/shrink_view_model.dart';

class ResultTable extends StatelessWidget {
  final Uint8List? groupFlat;
  final List<int> resultIndices;

  const ResultTable({
    super.key,
    required this.groupFlat,
    required this.resultIndices,
  });

  @override
  Widget build(BuildContext context) {
    final headers = ['号码1', '号码2', '号码3', '号码4', '号码5'];
    final rowCount =
        resultIndices.length > kPreviewRows ? kPreviewRows : resultIndices.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 30,
            color: kHeaderBg,
            child: Row(
              children: [
                for (final h in headers)
                  Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kRowLabelGreen,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: rowCount == 0
                ? const SizedBox.shrink()
                : ListView.builder(
                    itemExtent: 26,
                    itemCount: rowCount,
                    itemBuilder: (context, i) {
                      final base = resultIndices[i] * 5;
                      return Container(
                        color: i.isEven ? Colors.white : kAltRowBg,
                        child: Row(
                          children: [
                            for (var j = 0; j < 5; j++)
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                          color: Color(0xFFE4E9EE)),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    two(groupFlat![base + j]),
                                    style: const TextStyle(
                                        fontSize: 13, color: kTextDark),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
