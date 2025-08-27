import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CommonTextField extends StatefulWidget {
  final String label;
  final bool isPassword;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final int? maxLength;
  final String? initialValue;

  /// Custom colors
  final Color? fillColor;
  final Color? focusedBorderColor;
  final Color? enabledBorderColor;

  /// Optional prefix icon
  final IconData? prefixIcon;
  final Color? prefixIconColor; // <-- added this

  const CommonTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.controller,
    this.maxLength,
    this.initialValue,
    this.fillColor,
    this.focusedBorderColor,
    this.enabledBorderColor,
    this.prefixIcon,
    this.prefixIconColor, // <-- added
  });

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  late final TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ??
        TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  Color _getTextColor() {
    final bg = widget.fillColor ?? AppColors.secondary.withOpacity(0.3);
    return bg.computeLuminance() < 0.5
        ? Colors.white
        : AppColors.text.withOpacity(0.8);
  }

  Color _getLabelColor() {
    final bg = widget.fillColor ?? AppColors.secondary.withOpacity(0.3);
    if (bg.computeLuminance() < 0.5) return Colors.white70;
    return widget.focusedBorderColor ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: widget.isPassword,
      keyboardType: widget.keyboardType,
      controller: _internalController,
      onChanged: widget.onChanged,
      maxLength: widget.maxLength,
      style: TextStyle(
        fontSize: 16,
        color: _getTextColor(),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: _getLabelColor(),
          fontSize: 15,
        ),
        filled: true,
        fillColor: widget.fillColor ?? AppColors.secondary.withOpacity(0.3),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon,
                color: widget.prefixIconColor ?? Colors.white70)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: widget.enabledBorderColor ??
                (widget.fillColor != null &&
                        widget.fillColor!.computeLuminance() < 0.5
                    ? Colors.white24
                    : AppColors.primary.withOpacity(0.5)),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: widget.focusedBorderColor ??
                (widget.fillColor != null &&
                        widget.fillColor!.computeLuminance() < 0.5
                    ? Colors.greenAccent
                    : AppColors.primary),
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        counterText: '', // hide character counter
      ),
    );
  }
}
