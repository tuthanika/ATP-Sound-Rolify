import 'package:flutter/material.dart';

import '../../presentation_logic_holders/singletons/app_state.dart';
import '../../src/components/my_icons.dart';

class MySearchBar extends StatelessWidget {
  final TextEditingController filterController;
  final FocusNode focusNode;
  final Function(BuildContext) filterAudios;
  final Function(BuildContext) resetTextFilter;
  final int sortMode;
  final VoidCallback onSortToggle;
  final bool isCollapsed;
  final VoidCallback onLayoutToggle;
  final VoidCallback onAddTap;
  final bool showAddButton;

  const MySearchBar({
    Key? key,
    required this.filterController,
    required this.focusNode,
    required this.filterAudios,
    required this.resetTextFilter,
    required this.sortMode,
    required this.onSortToggle,
    required this.isCollapsed,
    required this.onLayoutToggle,
    required this.onAddTap,
    this.showAddButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onSortToggle,
          icon: Icon(
            sortMode == 0 ? Icons.sort_by_alpha : Icons.history,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: sortMode == 0 ? 'A-Z' : 'Newest',
        ),
        IconButton(
          onPressed: onLayoutToggle,
          icon: Icon(
            isCollapsed ? Icons.grid_view : Icons.view_agenda_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: isCollapsed ? 'Expanded' : 'Collapsed',
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(20.0)),
            ),
            padding: const EdgeInsets.only(left: 12.0, right: 8.0),
            child: SizedBox(
              height: 40 * heightFactor,
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.search,
                    size: 18,
                    color: focusNode.hasFocus
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).disabledColor,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      controller: filterController,
                      focusNode: focusNode,
                      style: TextStyle(fontSize: 14 * heightFactor),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14 * heightFactor,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      onChanged: (text) {
                        if (text == '') {
                          resetTextFilter(context);
                        } else {
                          filterAudios(context);
                        }
                      },
                    ),
                  ),
                  if (filterController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => resetTextFilter(context),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showAddButton) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: onAddTap,
            icon: Icon(
              Icons.add_circle_outline,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
