// location_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/providers/location_provider.dart';

class LocationField extends ConsumerStatefulWidget { 
  final String label;
  final bool isFrom;
  final IconData icon;
  final Widget? suffixIcon;
  final Function(String) onChanged;
  final Function(String) onSuggestionTap;

  const LocationField({
    required this.label,
    required this.isFrom,
    required this.icon,
    required this.onChanged,
    required this.onSuggestionTap,
    this.suffixIcon,
    super.key,
  });

  @override
  ConsumerState<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends ConsumerState<LocationField> { // _ is fine here
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.isFrom
        ? ref.watch(fromLocationProvider)
        : ref.watch(toLocationProvider);

    if (_controller.text != value) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon, color: Colors.deepPurple),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : widget.suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }
}
