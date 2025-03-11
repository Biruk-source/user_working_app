// @dart=2.17

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final String? selectedCategory;
  final List<String> availableCategories;
  final bool isVegetarianSelected;
  final bool isFastingSelected;
  final Function(String?) onCategorySelected;
  final Function(bool) onVegetarianChanged;
  final Function(bool) onFastingChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.selectedCategory,
    required this.availableCategories,
    required this.isVegetarianSelected,
    required this.isFastingSelected,
    required this.onCategorySelected,
    required this.onVegetarianChanged,
    required this.onFastingChanged,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  Timer? _debounce;
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = widget.controller;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onChanged(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search for restaurants or dishes...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.onClear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    'All',
                    style: GoogleFonts.poppins(
                      color: widget.selectedCategory == null
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                  selected: widget.selectedCategory == null,
                  onSelected: (_) => widget.onCategorySelected(null),
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(context).primaryColor,
                  checkmarkColor: Colors.white,
                ),
              ),
              ...widget.availableCategories.map((category) {
                final isSelected = widget.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => widget.onCategorySelected(category),
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).primaryColor,
                    checkmarkColor: Colors.white,
                  ),
                );
              }),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  'Vegetarian',
                  style: GoogleFonts.poppins(
                    color: widget.isVegetarianSelected
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 12,
                  ),
                ),
                selected: widget.isVegetarianSelected,
                onSelected: widget.onVegetarianChanged,
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.green,
                checkmarkColor: Colors.white,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  'Fasting',
                  style: GoogleFonts.poppins(
                    color: widget.isFastingSelected
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 12,
                  ),
                ),
                selected: widget.isFastingSelected,
                onSelected: widget.onFastingChanged,
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.orange,
                checkmarkColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
