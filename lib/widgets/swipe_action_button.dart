import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _SwipeActionButtonState extends State<SwipeActionButton> with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isCompleted = false;
  static const double _height = 60.0;
  static const double _thumbPadding = 4.0;
  
  // Amount needed to trigger action (0.0 to 1.0)
  static const double _threshold = 0.9;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final thumbSize = _height - (_thumbPadding * 2);
        final maxDrag = maxWidth - _height; // _height equals thumb width + padding adjustments approx

        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: widget.isEnabled 
                ? widget.color.withOpacity(0.1) 
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(_height / 2),
            border: Border.all(
              color: widget.isEnabled ? widget.color.withOpacity(0.2) : Colors.grey.shade300,
            ),
          ),
          child: Stack(
            children: [
              // Background Text
              Center(
                child: Opacity(
                  opacity: (1 - (_dragValue / maxDrag)).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Text(
                        widget.text.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: widget.isEnabled ? widget.color : Colors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                       Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: widget.isEnabled ? widget.color.withOpacity(0.5) : Colors.grey,
                        size: 18,
                      )
                    ],
                  ),
                ),
              ),

              // Progress Fill
              if (widget.isEnabled)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: _dragValue + (_height / 2),
                    height: _height,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.2),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_height / 2),
                        bottomLeft: Radius.circular(_height / 2),
                      ),
                    ),
                  ),
                ),

              // Thumb
              Positioned(
                left: _dragValue + _thumbPadding,
                top: _thumbPadding,
                bottom: _thumbPadding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!widget.isEnabled || _isCompleted) return;
                    setState(() {
                      _dragValue = (_dragValue + details.delta.dx).clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (!widget.isEnabled || _isCompleted) return;
                    
                    if (_dragValue / maxDrag > _threshold) {
                      setState(() {
                        _isCompleted = true;
                        _dragValue = maxDrag;
                      });
                      HapticFeedback.mediumImpact();
                      widget.onSwipeComplete();
                    } else {
                      // Snap back
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize, // Ensures square/circle
                    decoration: BoxDecoration(
                      color: widget.isEnabled ? widget.color : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 24,
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

