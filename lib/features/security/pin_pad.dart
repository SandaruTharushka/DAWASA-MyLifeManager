import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/l10n.dart';
import '../../core/security/pin_hasher.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';

/// On-screen number pad for PIN entry. The system keyboard is not used, so
/// keyboard apps never see (or learn) the PIN.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onCompleted,
    this.length,
    this.enabled = true,
    this.busy = false,
    this.errorText,
    this.onBiometric,
  });

  /// Called with the entered PIN. With a known [length] this happens as soon
  /// as the last digit is typed; otherwise a confirm key is shown.
  final ValueChanged<String> onCompleted;
  final int? length;
  final bool enabled;
  final bool busy;
  final String? errorText;
  final VoidCallback? onBiometric;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';

  void clear() {
    if (mounted) setState(() => _pin = '');
  }

  bool get _active => widget.enabled && !widget.busy;

  void _digit(int d) {
    if (!_active) return;
    final max = widget.length ?? PinPolicy.maxLength;
    if (_pin.length >= max) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += '$d');
    if (widget.length != null && _pin.length == widget.length) {
      widget.onCompleted(_pin);
    }
  }

  void _backspace() {
    if (!_active || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    if (!_active || _pin.length < PinPolicy.minLength) return;
    widget.onCompleted(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final slots = widget.length ?? PinPolicy.maxLength;
    final error = widget.errorText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l10n.securityPinDigitsEntered(_pin.length),
          liveRegion: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slots; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? (error == null ? colors.primary : colors.error)
                        : Colors.transparent,
                    border: Border.all(
                      color: error == null ? colors.outline : colors.error,
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 56,
          child: Center(
            child: widget.busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : error == null
                ? null
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                    child: Text(
                      error,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              for (final row in const [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
              ])
                Row(
                  children: [
                    for (final d in row)
                      _Key(
                        key: ValueKey('pin-key-$d'),
                        label: '$d',
                        onTap: _active ? () => _digit(d) : null,
                      ),
                  ],
                ),
              Row(
                children: [
                  if (widget.length == null)
                    _Key(
                      key: const ValueKey('pin-key-ok'),
                      icon: Icons.check_rounded,
                      semanticLabel: l10n.actionContinue,
                      onTap: _active && _pin.length >= PinPolicy.minLength
                          ? _submit
                          : null,
                    )
                  else if (widget.onBiometric != null)
                    _Key(
                      key: const ValueKey('pin-key-biometric'),
                      icon: Icons.fingerprint_rounded,
                      semanticLabel: l10n.securityUseBiometric,
                      onTap: widget.busy ? null : widget.onBiometric,
                    )
                  else
                    const Expanded(child: SizedBox()),
                  _Key(
                    key: const ValueKey('pin-key-0'),
                    label: '0',
                    onTap: _active ? () => _digit(0) : null,
                  ),
                  _Key(
                    key: const ValueKey('pin-key-back'),
                    icon: Icons.backspace_outlined,
                    semanticLabel: l10n.securityPinDelete,
                    onTap: _active && _pin.isNotEmpty ? _backspace : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    this.label,
    this.icon,
    this.semanticLabel,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled
        ? context.colors.onSurface
        : context.colors.onSurface.withValues(alpha: 0.35);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AspectRatio(
          aspectRatio: 1.5,
          child: Semantics(
            button: true,
            enabled: enabled,
            label: semanticLabel ?? label,
            excludeSemantics: true,
            child: Material(
              color: label == null
                  ? Colors.transparent
                  : context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Radii.card),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.card),
                onTap: onTap,
                child: Center(
                  child: label != null
                      ? Text(
                          label!,
                          style: context.textTheme.headlineSmall?.copyWith(
                            color: color,
                          ),
                        )
                      : Icon(icon, color: color, size: 26),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
