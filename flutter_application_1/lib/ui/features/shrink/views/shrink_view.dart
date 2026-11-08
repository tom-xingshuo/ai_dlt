/// 主界面(对应 ShrinkWindow: 数据源区 + 12页条件区 + 操作按钮 + 状态栏 + 结果表格)。
library;

import 'package:flutter/material.dart';

import 'package:flutter_application_1/ui/core/widgets.dart';
import 'package:flutter_application_1/ui/features/shrink/view_models/shrink_view_model.dart';
import 'package:flutter_application_1/ui/features/shrink/views/condition_pages.dart';
import 'package:flutter_application_1/ui/features/shrink/views/result_table.dart';

class ShrinkView extends StatefulWidget {
  const ShrinkView({super.key});

  @override
  State<ShrinkView> createState() => _ShrinkViewState();
}

class _ShrinkViewState extends State<ShrinkView> {
  final ShrinkViewModel _vm = ShrinkViewModel();

  @override
  void initState() {
    super.initState();
    _vm.init();
  }

  @override
  void dispose() {
    _vm.persistState(); // 退出前保存界面状态(对应 closeEvent)
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (!_vm.initialized) {
          return const Scaffold(
            backgroundColor: kPageBg,
            body: Center(child: Text('载入中...', style: TextStyle(color: kPrimaryGreen))),
          );
        }
        return Scaffold(
          backgroundColor: kPageBg,
          body: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSourceBox(),
                const SizedBox(height: 8),
                SizedBox(
                  height: 430,
                  child: DefaultTabController(
                    length: conditionTabTitles.length,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: kPrimaryGreen,
                          unselectedLabelColor: const Color(0xFF5A6B7A),
                          labelStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                          unselectedLabelStyle:
                              const TextStyle(fontSize: 13),
                          indicatorColor: kPrimaryGreen,
                          dividerColor: kBorderColor,
                          tabs: [
                            for (final t in conditionTabTitles) Tab(text: t),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: buildConditionPages(_vm),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildButtonRow(),
                const SizedBox(height: 6),
                Text(
                  _vm.statusText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryGreen,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ResultTable(
                    groupFlat: _vm.groupFlat,
                    resultIndices: _vm.resultIndices,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceBox() {
    return GroupBoxWidget(
      title: '① 数据源',
      titleBg: kPageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('全量数据(324632组)',
                  style: TextStyle(fontSize: 13, color: kTextDark)),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _vm.loadGroups,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kRowLabelGreen,
                  side: const BorderSide(color: Color(0xFFC3CDD6)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('重新载入'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _vm.latestText,
                  style: const TextStyle(fontSize: 13, color: kTextDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed:
                    _vm.latestLoading ? null : () => _vm.fetchLatest(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kRowLabelGreen,
                  side: const BorderSide(color: Color(0xFFC3CDD6)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('刷新'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow() {
    return Row(
      children: [
        FilledButton(
          onPressed: _vm.busy ? null : () => _vm.shrink(),
          style: FilledButton.styleFrom(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFF2F4F6),
            disabledForegroundColor: const Color(0xFF9AA7B1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('开始缩水',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _vm.saveResults(),
          style: OutlinedButton.styleFrom(
            foregroundColor: kRowLabelGreen,
            side: const BorderSide(color: Color(0xFFC3CDD6)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('保存结果'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _vm.resetConditions(),
          style: OutlinedButton.styleFrom(
            foregroundColor: kRowLabelGreen,
            side: const BorderSide(color: Color(0xFFC3CDD6)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('重置条件'),
        ),
        const SizedBox(width: 16),
        const RowLabel('保存路径:'),
        const SizedBox(width: 6),
        Expanded(
          child: TextEditField(
            value: _vm.savePath,
            resetToken: -1,
            width: double.infinity,
            onChanged: (v) => _vm.savePath = v,
          ),
        ),
      ],
    );
  }
}
