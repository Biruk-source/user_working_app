import 'package:flutter/material.dart';

enum ButtonState { idle, loading, success, fail }

class CustomProgressButton extends StatelessWidget {
  final ButtonState state;
  final VoidCallback onPressed;
  final Map<ButtonState, Widget> stateWidgets;
  final Map<ButtonState, Color> stateColors;

  const CustomProgressButton({
    super.key,
    required this.state,
    required this.onPressed,
    required this.stateWidgets,
    required this.stateColors,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: state == ButtonState.loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: stateColors[state],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: stateWidgets[state],
    );
  }
}
