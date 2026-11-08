/// 共享 UI 组件: 分组框/行标题/数字输入/文本输入/复选框等(对应 PyQt 样式)。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kPrimaryGreen = Color(0xFF0A7D43);
const Color kPrimaryGreenDark = Color(0xFF086838);
const Color kRowLabelGreen = Color(0xFF245B3F);
const Color kBorderColor = Color(0xFFDDE3EA);
const Color kHeaderBg = Color(0xFFEEF2F5);
const Color kAltRowBg = Color(0xFFF6FAF8);
const Color kPageBg = Color(0xFFF4F6F8);
const Color kTextDark = Color(0xFF1F2D38);

/// 分组框: 标题加粗亮绿、圆角白底(对应 QGroupBox 样式)。
class GroupBoxWidget extends StatelessWidget {
  final String title;
  final Widget child;
  final String? tooltip;
  final Color titleBg;

  const GroupBoxWidget({
    super.key,
    required this.title,
    required this.child,
    this.tooltip,
    this.titleBg = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final titleChip = Container(
      color: titleBg,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: kPrimaryGreen,
          fontSize: 13,
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
        Positioned(left: 10, top: 0, child: tooltip != null ? Tooltip(message: tooltip!, child: titleChip) : titleChip),
      ],
    );
  }
}

/// 组内行标题: 加粗深绿(对应 make_row_label)。
class RowLabel extends StatelessWidget {
  final String text;

  const RowLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: kRowLabelGreen,
        fontSize: 13,
      ),
    );
  }
}

/// 数字输入框(对应 QSpinBox): 范围外输入失焦/提交时收敛。
class NumberField extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final int resetToken;
  final ValueChanged<int> onCommit;
  final double width;

  const NumberField({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.resetToken,
    required this.onCommit,
    this.width = 64,
  });

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _c =
      TextEditingController(text: '${widget.value}');

  void _applyClamp() {
    final n = int.tryParse(_c.text);
    if (n == null) {
      _c.text = '${widget.value.clamp(widget.min, widget.max)}';
      widget.onCommit(widget.value.clamp(widget.min, widget.max));
      return;
    }
    final clamped = n.clamp(widget.min, widget.max);
    if (clamped != n) {
      _c.text = '$clamped';
    }
    widget.onCommit(clamped);
  }

  void _onChanged(String v) {
    final n = int.tryParse(v);
    if (n == null) {
      return; // 编辑中的空串/残串不处理
    }
    if (n >= widget.min && n <= widget.max) {
      widget.onCommit(n);
    }
  }

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetToken != oldWidget.resetToken) {
      _c.text = '${widget.value}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => _applyClamp(),
      child: SizedBox(
        width: widget.width,
        height: 30,
        child: TextField(
          controller: _c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: kTextDark),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFC3CDD6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: kPrimaryGreen),
            ),
          ),
          onChanged: _onChanged,
          onSubmitted: (_) => _applyClamp(),
        ),
      ),
    );
  }
}

/// 文本输入框(对应 QLineEdit)。
class TextEditField extends StatefulWidget {
  final String value;
  final int resetToken;
  final String? hint;
  final double width;
  final ValueChanged<String> onChanged;

  const TextEditField({
    super.key,
    required this.value,
    required this.resetToken,
    required this.onChanged,
    this.hint,
    this.width = 180,
  });

  @override
  State<TextEditField> createState() => _TextEditFieldState();
}

class _TextEditFieldState extends State<TextEditField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(TextEditField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetToken != oldWidget.resetToken && _c.text != widget.value) {
      _c.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 30,
      child: TextField(
        controller: _c,
        style: const TextStyle(fontSize: 13, color: kTextDark),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9AA7B1)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFC3CDD6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: kPrimaryGreen),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// 条件复选框(可选悬停提示)。
class CondCheckbox extends StatelessWidget {
  final String title;
  final bool value;
  final String? tooltip;
  final ValueChanged<bool> onChanged;

  const CondCheckbox({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: value,
            activeColor: kPrimaryGreen,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
        const SizedBox(width: 4),
        Text(title, style: const TextStyle(fontSize: 13, color: kTextDark)),
      ],
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: row) : row;
  }
}

/// 比例选择组: 0~5 个复选框, 标签为"几:几"(对应 make_ratio_group)。
class RatioGroupBox extends StatelessWidget {
  final String title;
  final String tooltip;
  final List<bool> checks;
  final ValueChanged<int> onToggle;

  const RatioGroupBox({
    super.key,
    required this.title,
    required this.tooltip,
    required this.checks,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GroupBoxWidget(
      title: title,
      tooltip: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var k = 0; k < 6; k++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CondCheckbox(
                title: '$k:${5 - k}',
                value: checks[k],
                onChanged: (_) => onToggle(k),
              ),
            ),
        ],
      ),
    );
  }
}

String two(int n) => n.toString().padLeft(2, '0');
