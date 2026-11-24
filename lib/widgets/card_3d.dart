import 'dart:math' as math;
import 'package:flutter/material.dart';

class TiltCard3D extends StatefulWidget {
  final Widget child;
  final double maxTiltAngle; // In radians
  final Color? glowColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool enableGlow;
  final double depth;

  const TiltCard3D({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.12,
    this.glowColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.enableGlow = true,
    this.depth = 12.0,
  });

  @override
  State<TiltCard3D> createState() => _TiltCard3DState();
}

class _TiltCard3DState extends State<TiltCard3D> with SingleTickerProviderStateMixin {
  double _rotateX = 0;
  double _rotateY = 0;
  bool _isHovered = false;
  late AnimationController _animController;
  late Animation<double> _returnAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent details, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final dx = details.localPosition.dx - (size.width / 2);
    final dy = details.localPosition.dy - (size.height / 2);

    final normX = (dx / (size.width / 2)).clamp(-1.0, 1.0);
    final normY = (dy / (size.height / 2)).clamp(-1.0, 1.0);

    setState(() {
      _rotateX = -normY * widget.maxTiltAngle;
      _rotateY = normX * widget.maxTiltAngle;
      _isHovered = true;
    });
  }

  void _onExit(PointerEvent details) {
    _returnAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _rotateX *= _returnAnim.value;
          _rotateY *= _returnAnim.value;
        });
      });

    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _rotateX = 0;
          _rotateY = 0;
          _isHovered = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final glow = widget.glowColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return MouseRegion(
            onHover: (event) => _onHover(event, size),
            onExit: _onExit,
            child: GestureDetector(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _isHovered = true),
              onTapUp: (_) => setState(() => _isHovered = false),
              onTapCancel: () => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutQuad,
                transformAlignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015) // 3D Perspective depth
                  ..rotateX(_rotateX)
                  ..rotateY(_rotateY)
                  ..setTranslationRaw(0.0, _isHovered ? -4.0 : 0.0, _isHovered ? widget.depth : 0.0),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    if (widget.enableGlow && _isHovered)
                      BoxShadow(
                        color: glow.withValues(alpha: 0.28),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: _isHovered
                            ? (widget.borderColor ?? glow.withValues(alpha: 0.6))
                            : (widget.borderColor ?? Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                        width: _isHovered ? 1.6 : 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        widget.child,
                        // Dynamic 3D lighting sheen reflection
                        if (_isHovered)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: radius,
                                  gradient: LinearGradient(
                                    begin: Alignment(
                                      -math.sin(_rotateY) * 2,
                                      -math.sin(_rotateX) * 2,
                                    ),
                                    end: Alignment(
                                      math.sin(_rotateY) * 2,
                                      math.sin(_rotateX) * 2,
                                    ),
                                    colors: [
                                      Colors.white.withValues(alpha: 0.08),
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.03),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
