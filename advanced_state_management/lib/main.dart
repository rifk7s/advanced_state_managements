import 'package:flutter/material.dart';
import 'package:global_state/global_state.dart';

void main() => runApp(const MyEphemeralApp());

class MyEphemeralApp extends StatelessWidget {
  const MyEphemeralApp({super.key});
  @override
  Widget build(BuildContext context) {
    final state = GlobalState();
    return GlobalStateProvider(
      state: state,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Global State Counters')),
          body: CountersListPage(),
        ),
      ),
    );
  }
}

/// A simple InheritedWidget to provide GlobalState to subtree.
class GlobalStateProvider extends StatefulWidget {
  const GlobalStateProvider({
    required this.state,
    required this.child,
    super.key,
  });

  final GlobalState state;
  final Widget child;

  /// Provides access to GlobalState from any descendant widget
  static GlobalState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Inherited>()!.state;

  @override
  State<GlobalStateProvider> createState() => _GlobalStateProviderState();
}

class _GlobalStateProviderState extends State<GlobalStateProvider> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant GlobalStateProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-subscribe to new GlobalState instance if it changes
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChanged);
      widget.state.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return _Inherited(state: widget.state, child: widget.child);
  }
}

class _Inherited extends InheritedWidget {
  const _Inherited({required this.state, required super.child});
  final GlobalState state;

  @override
  bool updateShouldNotify(covariant _Inherited oldWidget) {
    // The underlying GlobalState mutates in-place. Always notify dependents
    // when a new _Inherited instance is built so they can read the latest
    // values from `state`.
    return true;
  }
}

class CountersListPage extends StatelessWidget {
  const CountersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final global = GlobalStateProvider.of(context);
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            // Custom drag-and-drop reordering with global state update
            onReorder: (oldIndex, newIndex) =>
                global.moveCounter(oldIndex, newIndex),
            itemCount: global.counters.length,
            itemBuilder: (context, index) {
              final counter = global.counters[index];
              return Padding(
                key: ValueKey(counter.id),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Card(
                  color: counter.color.withAlpha((0.12 * 255).round()),
                  child: CounterTile(counterId: counter.id),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => global.addCounter(),
                icon: Icon(Icons.add),
                label: Text('Add Counter'),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: global.counters.isNotEmpty
                    ? () => global.removeCounterById(global.counters.last.id)
                    : null,
                icon: Icon(Icons.remove),
                label: Text('Remove Last'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Each counter tile is a StatefulWidget that reads its value from global state
/// but keeps the widget lifecycle local for animations or local ephemeral state.
class CounterTile extends StatefulWidget {
  const CounterTile({required this.counterId, super.key});

  final String counterId;

  @override
  State<CounterTile> createState() => _CounterTileState();
}

class _CounterTileState extends State<CounterTile> {
  @override
  Widget build(BuildContext context) {
    final global = GlobalStateProvider.of(context);
    final counter = global.counters.firstWhere((c) => c.id == widget.counterId);

    final idx = global.counters.indexWhere((c) => c.id == widget.counterId);

    return Container(
      color: counter.color.withAlpha((0.06 * 255).round()),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: counter.color,
            child: Text(counter.label.isNotEmpty ? counter.label[0] : '?'),
          ),
          SizedBox(width: 12),

          // Expanded center area with left-aligned label and centered value
          Expanded(
            child: Row(
              children: [
                Text(counter.label, style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      // Smooth scale transition when counter value changes
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Text(
                        'Value: ${counter.value}',
                        key: ValueKey(
                          counter.value,
                        ), // Triggers animation on value change
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action icons and drag handle (spaced)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => _EditCounterDialog(counter: counter),
                  );
                  if (result != null) {
                    global.updateCounter(
                      counter.id,
                      label: result['label'] as String?,
                      color: result['color'] as Color?,
                    );
                  }
                },
              ),
              SizedBox(width: 4),
              AnimatedScale(
                scale: counter.value > 0 ? 1.0 : 0.7,
                duration: Duration(milliseconds: 150),
                child: IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: counter.value > 0
                      ? () => global.decrement(widget.counterId)
                      : null,
                ),
              ),
              SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.add_circle_outline),
                onPressed: () => global.increment(widget.counterId),
              ),
              SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () => global.removeCounterById(widget.counterId),
              ),
              SizedBox(width: 8),
              // Drag handle with padding to avoid being flush to edge
              if (idx != -1)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0, right: 6.0),
                  child: ReorderableDragStartListener(
                    index: idx,
                    child: Icon(Icons.drag_handle),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditCounterDialog extends StatefulWidget {
  const _EditCounterDialog({required this.counter});
  final dynamic counter;
  @override
  State<_EditCounterDialog> createState() => _EditCounterDialogState();
}

class _EditCounterDialogState extends State<_EditCounterDialog> {
  late TextEditingController _labelController;
  late Color _selected;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.counter.label);
    _selected = widget.counter.color as Color;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit counter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: InputDecoration(labelText: 'Label'),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: kCounterPalette.map((c) {
              final selected = c == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    border: selected
                        ? Border.all(width: 3, color: Colors.black)
                        : null,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(
            context,
          ).pop({'label': _labelController.text, 'color': _selected}),
          child: Text('Save'),
        ),
      ],
    );
  }
}
