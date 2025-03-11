import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.isSuccessful,
    required this.theme,
    this.isDarkMode = false,
  });

  final String text;
  final Function onPressed;
  final bool isSuccessful;
  final ThemeData theme;
  final bool isDarkMode;

  @override
  CustomButtonState createState() => CustomButtonState();
}

class CustomButtonState extends State<CustomButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAnimating = false;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed == null
          ? null
          : () async {
              setState(() {
                _isAnimating = true;
              });
              await _animationController.forward(from: 0.0);
              widget.onPressed();
              await _animationController.reverse(from: 1.0);
              setState(() {
                _isAnimating = false;
              });
            },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 + (_isAnimating ? _animationController.value * 0.1 : 0),
            child: Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isSuccessful
                      ? [
                          widget.theme.colorScheme.secondary,
                          widget.theme.colorScheme.secondaryContainer,
                        ]
                      : [
                          widget.isDarkMode
                              ? Colors.blue
                              : const Color.fromARGB(255, 5, 36, 61),
                          widget.isDarkMode
                              ? Colors.blueAccent
                              : const Color.fromARGB(255, 13, 30, 59),
                        ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(
                      _animationController.value * 5,
                      _animationController.value * 5,
                    ),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.theme.colorScheme.onSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

class CustomToggleButton extends StatefulWidget {
  const CustomToggleButton({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
  });

  final bool isDarkMode;
  final Function onToggle;

  @override
  CustomToggleButtonState createState() => CustomToggleButtonState();
}

class CustomToggleButtonState extends State<CustomToggleButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAnimating = false;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        setState(() {
          _isAnimating = true;
        });
        await _animationController.forward(from: 0.0);
        widget.onToggle();
        await _animationController.reverse(from: 1.0);
        setState(() {
          _isAnimating = false;
        });
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 + (_isAnimating ? _animationController.value * 0.1 : 0),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.isDarkMode ? Colors.deepPurple : Colors.blue,
                    widget.isDarkMode
                        ? Colors.deepPurpleAccent
                        : Colors.blueAccent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(
                      _animationController.value * 5,
                      _animationController.value * 5,
                    ),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    required this.onChanged,
    required this.validator,
  });

  final String labelText;
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? Function(String?)? validator;

  @override
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      obscureText: widget.obscureText,
      onChanged: (text) => widget.onChanged(text),
      validator: (text) => widget.validator?.call(text),
      cursorColor: Theme.of(context).colorScheme.secondary,
    );
  }
}
