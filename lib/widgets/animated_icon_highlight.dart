import 'package:flutter/material.dart';

class AnimatedIconHighlight extends StatefulWidget {
  final Widget child;
  final bool playing;
  final Duration duration;
  final double loops;

  const AnimatedIconHighlight({Key key, this.playing, this.child, Duration duration, double loops}) :
    this.duration = duration ?? const Duration(milliseconds: 1000),
    this.loops = loops ?? 2.0,
    super(key: key);

  @override
  _AnimatedIconHighlightState createState() => _AnimatedIconHighlightState();
}

class _AnimatedIconHighlightState extends State<AnimatedIconHighlight> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  bool _loopHasCompleted = false;

  @override
  void initState() {
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(begin: 0, end: 50).animate(_controller)
      ..addListener(() => setState(() { }));

    updatePlaying();

    super.initState();
  }

  @override
  void didUpdateWidget(AnimatedIconHighlight oldWidget) {
    updatePlaying();
    super.didUpdateWidget(oldWidget);
  }

  void updatePlaying() {
    if (widget.playing != false && !_controller.isAnimating && !_loopHasCompleted) {
      _controller.repeat()
        .timeout(widget.duration * widget.loops, onTimeout: () {     //TODO This causes the animation to stop when re-started before timeout expired. See https://github.com/flutter/flutter/issues/53262.
          _controller.reset();
          _loopHasCompleted = true;
        });
    } else if (widget.playing == false) {
      if (_controller.isAnimating)
        _controller.reset();
      _loopHasCompleted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[

        // background
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) {
              return CustomPaint(
                size: Size(box.maxWidth, 50),
                painter: CirclePainter(_animation.value),
              );
            }
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class CirclePainter extends CustomPainter {
  final double radius;
  var _paint;

  CirclePainter(this.radius) {
    _paint = Paint()
      ..color = Colors.green;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var centerX = size.width / 2;
    var centerY = size.height / 2;
    canvas.drawCircle(Offset(centerX, centerY), radius, _paint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}