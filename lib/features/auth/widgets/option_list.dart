import 'package:flutter/material.dart';
import 'package:fit_track/core/ui/ui.dart';

class Option {
  final String value;
  final String title;
  final String detail;
  const Option(this.value, this.title, this.detail);
}

/// A stack of tappable rows where exactly one is selected.
class OptionList extends StatelessWidget {
  final List<Option> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const OptionList({super.key, required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: p.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: o.value == selected ? p.ink : p.line, width: o.value == selected ? 1.6 : 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(o.value),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.title, style: context.text.titleMedium),
                            const SizedBox(height: 2),
                            Text(o.detail, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        o.value == selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: o.value == selected ? p.ink : p.faint,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
