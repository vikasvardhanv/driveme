import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Swipe-to-action button for fraud prevention in trip status updates.
/// Driver must swipe from left to right to confirm actions.
class SwipeActionButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onSwipeComplete;
  final bool isEnabled;

  const SwipeActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onSwipeComplete,
    this.isEnabled = true,
  });

  @override
  State<SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<SwipeActionButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const double _buttonHeight = 64.0;
  static const double _thumbSize = 56.0;
  static const double _minThreshold = 0.85;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _maxDrag {
    final width = MediaQuery.of(context).size.width - 48; // padding
    return width - _thumbSize - 8;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled || _isCompleted) return;
    
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.isEnabled || _isCompleted) return;

    final progress = _dragPosition / _maxDrag;
    
    if (progress >= _minThreshold) {
      // Success - complete the swipe
      setState(() {
        _isCompleted = true;
        _dragPosition = _maxDrag;
      });
      HapticFeedback.heavyImpact();
      widget.onSwipeComplete();
    } else {
      // Reset position with animation
      _animation = Tween<double>(begin: _dragPosition, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward(from: 0).then((_) {
        setState(() {
          _dragPosition = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _maxDrag > 0 ? _dragPosition / _maxDrag : 0.0;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedPosition = _animationController.isAnimating
            ? _animation.value
            : _dragPosition;

        return Container(
          height: _buttonHeight,
          decoration: BoxDecoration(
            color: widget.isEnabled
                ? widget.color.withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_buttonHeight / 2),
            border: Border.all(
              color: widget.isEnabled
                  ? widget.color.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                height: _buttonHeight,
                width: animatedPosition + _thumbSize + 4,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(progress * 0.3),
                  borderRadius: BorderRadius.circular(_buttonHeight / 2),
                ),
              ),
              // Center text with icon
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isCompleted) ...[
                      Icon(
                        Icons.chevron_right,
                        color: widget.isEnabled
                            ? widget.color.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.3),
                        size: 20,
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: widget.isEnabled
                            ? widget.color.withOpacity(0.7)
                            : Colors.grey.withOpacity(0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isCompleted ? 'Done!' : 'Swipe to ${widget.text}',
                      style: TextStyle(
                        color: widget.isEnabled ? widget.color : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Draggable thumb
              Positioned(
                left: animatedPosition + 4,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: widget.isEnabled ? widget.color : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCompleted ? Icons.check : widget.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Helper widget for AnimatedBuilder compatibility
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
