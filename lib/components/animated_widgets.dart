import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:nexar_app/services/providers.dart';

class AnimatedSearchBar extends ConsumerStatefulWidget {
  const AnimatedSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search music...',
    this.width = 220,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final double width;

  @override
  ConsumerState<AnimatedSearchBar> createState() =>
      _AnimatedSearchBarState();
}

class _AnimatedSearchBarState
    extends ConsumerState<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
    _focusNode = FocusNode();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  void _openSearch() {
    setState(() => _isExpanded = true);

    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted && _isExpanded) {
        _focusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _focusNode.unfocus();
    _controller.clear();
    widget.onChanged('');

    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isExpanded = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(designProvider);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _isExpanded
            ? design.controlBackground
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isExpanded ? null : _openSearch,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.search,
                  size: 20,
                  color: design.textPrimary,
                ),
              ),
            ),
          ),

          // Animated input
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                width: _isExpanded ? widget.width : 0,
                height: 44,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _isExpanded
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                onChanged: widget.onChanged,
                                style: TextStyle(
                                  color: design.textPrimary,
                                  fontSize: 14,
                                ),
                                cursorColor: design.accent,
                                decoration: InputDecoration(
                                  hintText: widget.hintText,
                                  hintStyle: TextStyle(
                                    color: design.textSecondary,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
              
                            // Close button
                            IconButton(
                              onPressed: _closeSearch,
                              icon: Icon(
                                LucideIcons.x,
                                size: 17,
                                color: design.textSecondary,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 40,
                              ),
                              splashRadius: 18,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}