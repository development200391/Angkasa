import 'package:flutter/material.dart';

/// Permukaan yang terasa punya tebal.
///
/// Kedalamannya bukan gambar: satu `LinearGradient` untuk badan, satu
/// `BoxShadow` tanpa blur sebagai tebal badan, dan satu lagi ber-blur
/// sebagai bayangan jatuh. Menekannya memangkas offset bayangan pertama
/// dari [depth] ke [depthPressed] sambil menurunkan isinya sejauh
/// selisihnya — jadi tombolnya benar-benar terasa turun, bukan sekadar
/// berubah warna.
class Pressable3D extends StatefulWidget {
  const Pressable3D({
    required this.child,
    this.onPressed,
    this.gradient,
    this.color,
    this.bodyColor = const Color(0xFF7E4E07),
    this.dropShadow,
    this.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.depth = 7,
    this.depthPressed = 2,
    this.height,
    this.padding,
    this.highlight = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? color;

  /// Warna tebal badan — bagian yang terlihat di bawah permukaan.
  final Color bodyColor;
  final BoxShadow? dropShadow;
  final BoxBorder? border;
  final BorderRadius borderRadius;
  final double depth;
  final double depthPressed;
  final double? height;
  final EdgeInsetsGeometry? padding;

  /// Garis terang tipis di tepi atas, pengganti `inset 0 2px 0 white`.
  final bool highlight;

  @override
  State<Pressable3D> createState() => _Pressable3DState();
}

class _Pressable3DState extends State<Pressable3D> {
  bool _ditekan = false;

  bool get _aktif => widget.onPressed != null;

  void _set(bool v) {
    if (!_aktif || _ditekan == v) return;
    setState(() => _ditekan = v);
  }

  @override
  Widget build(BuildContext context) {
    final tebal = _ditekan ? widget.depthPressed : widget.depth;
    final turun = widget.depth - tebal;

    return Semantics(
      button: true,
      enabled: _aktif,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOut,
          height: widget.height,
          margin: EdgeInsets.only(top: turun, bottom: tebal),
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            color: widget.gradient == null ? widget.color : null,
            borderRadius: widget.borderRadius,
            border: widget.border,
            boxShadow: [
              BoxShadow(
                color: widget.bodyColor,
                offset: Offset(0, tebal),
                blurRadius: 0,
              ),
              if (widget.dropShadow != null && !_ditekan) widget.dropShadow!,
            ],
          ),
          child: widget.highlight
              ? _GarisAtas(radius: widget.borderRadius, child: widget.child)
              : widget.child,
        ),
      ),
    );
  }
}

class _GarisAtas extends StatelessWidget {
  const _GarisAtas({required this.radius, required this.child});

  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 2,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: radius.topLeft,
                  topRight: radius.topRight,
                ),
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
