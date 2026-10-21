import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_track/core/theme/app_theme.dart';
import 'package:fit_track/core/utils/app_exception.dart';

export 'package:fit_track/core/theme/app_theme.dart' show Palette, AppTheme;

extension UiContext on BuildContext {
  Palette get palette {
    final theme = Theme.of(this);
    return theme.extension<Palette>() ?? (theme.brightness == Brightness.dark ? Palette.dark : Palette.light);
  }
  TextTheme get text => Theme.of(this).textTheme;
}

/// Standard horizontal page padding used everywhere.
const kPage = EdgeInsets.symmetric(horizontal: 20);

// ---------------------------------------------------------------------------
// Headings
// ---------------------------------------------------------------------------

/// Big page title used at the top of tab screens (instead of an app bar).
class PageTitle extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final List<Widget> actions;

  const PageTitle(this.title, {super.key, this.eyebrow, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(eyebrow!, style: context.text.bodySmall),
                  const SizedBox(height: 2),
                ],
                Text(title, style: context.text.headlineLarge),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Small all-caps label that introduces a section.
class SectionLabel extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionLabel(
    this.text, {
    super.key,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 28, 12, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: context.text.labelSmall)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(action!, style: context.text.labelMedium),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------

/// A flat surface with a hairline border.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = kPage,
    this.onTap,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: borderColor ?? p.line),
    );
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? p.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A panel holding rows separated by hairlines.
class PanelList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const PanelList({super.key, required this.children, this.margin = kPage});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, indent: 16, color: context.palette.line));
      rows.add(children[i]);
    }
    return Panel(margin: margin, padding: EdgeInsets.zero, child: Column(children: rows));
  }
}

/// One row inside a [PanelList].
class ListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool chevron;

  const ListRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.chevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[
              IconTheme.merge(data: IconThemeData(color: p.muted, size: 20), child: leading!),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.bodyLarge!.copyWith(color: titleColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            if (chevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 20, color: p.faint),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data display
// ---------------------------------------------------------------------------

/// A number with an optional unit and a caption underneath.
class Stat extends StatelessWidget {
  final String value;
  final String? unit;
  final String label;
  final bool large;
  final Color? color;

  const Stat({super.key, required this.value, required this.label, this.unit, this.large = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = (large ? context.text.displayMedium : context.text.headlineMedium)!.copyWith(color: color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: value, style: style),
            if (unit != null)
              TextSpan(
                text: ' $unit',
                style: context.text.titleSmall!.copyWith(color: context.palette.muted),
              ),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(label, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// Thin progress bar.
class Meter extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;

  const Meter({super.key, required this.value, this.height = 4, this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.isNaN ? 0 : value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: p.surfaceAlt,
        color: color ?? p.accent,
      ),
    );
  }
}

/// Small rounded tag, e.g. "For you" or "Beginner".
class Tag extends StatelessWidget {
  final String label;
  final bool strong;

  const Tag(this.label, {super.key, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: strong ? p.accentSoft : p.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: context.text.labelSmall!.copyWith(
          letterSpacing: 0.2,
          color: strong ? p.accent : p.muted,
        ),
      ),
    );
  }
}

/// Selectable filter pill.
class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const Pill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: selected ? p.ink : p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? p.ink : p.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: context.text.labelMedium!.copyWith(color: selected ? p.inkInverse : p.ink),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class Loading extends StatelessWidget {
  final double padding;
  const Loading({super.key, this.padding = 40});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.all(padding),
        child: const Center(
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}

/// Quiet empty state: a sentence or two and maybe one action. No giant icons.
class EmptyNote extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry margin;

  const EmptyNote({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.margin = kPage,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      margin: margin,
      color: Colors.transparent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleMedium),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: context.text.bodyMedium!.copyWith(color: context.palette.muted)),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class ErrorNote extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ErrorNote({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("That didn't load", style: context.text.titleMedium),
            const SizedBox(height: 6),
            Text(friendlyError(error), textAlign: TextAlign.center, style: context.text.bodySmall),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

/// Full-width primary button with a built-in busy state.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  const PrimaryButton({super.key, required this.label, this.onPressed, this.busy = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: p.muted),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback helpers
// ---------------------------------------------------------------------------

/// Turns exceptions into something a person can read.
String friendlyError(Object e) {
  if (e is AuthException) return e.message;
  if (e is SocketException || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
    return "Can't reach the server. Check your connection and try again.";
  }
  if (e is TimeoutException) return 'That took too long. Check your connection and try again.';
  if (e is PostgrestException) return _postgrest(e);
  if (e is AppException) {
    final cause = e.details;
    if (cause != null && cause is! AppException) return friendlyError(cause);
    return e.message;
  }
  final s = e.toString().replaceFirst('Exception: ', '');
  return s.length > 160 ? '${s.substring(0, 160)}…' : s;
}

String _postgrest(PostgrestException e) {
  if (e.code == '23505') return 'That already exists. Try a different value.';
  if (e.code == '42501') return "You don't have permission to do that.";
  return e.message;
}

void showToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ));
}

void showErrorToast(BuildContext context, Object error) => showToast(context, friendlyError(error));

/// Simple yes/no confirmation. Returns true only when confirmed.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final p = context.palette;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: destructive ? p.danger : p.ink),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

/// Bottom sheet with a title, scrollable body and keyboard-aware padding.
Future<T?> showAppSheet<T>(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: ctx.text.headlineSmall),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
}

/// Runs [task] behind a blocking spinner. Returns the result or null on error.
Future<T?> runWithSpinner<T>(BuildContext context, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: Loading()),
  );
  try {
    final result = await task();
    navigator.pop();
    return result;
  } catch (e) {
    navigator.pop();
    if (context.mounted) showErrorToast(context, e);
    return null;
  }
}

String capitalize(String s) {
  final t = s.replaceAll('_', ' ');
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

/// "72.5" instead of "72.50" and "80" instead of "80.0".
String trimNum(num v, {int decimals = 1}) {
  final s = v.toStringAsFixed(decimals);
  if (!s.contains('.')) return s;
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}
