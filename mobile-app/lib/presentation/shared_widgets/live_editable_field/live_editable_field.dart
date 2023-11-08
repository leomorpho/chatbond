import 'package:chatbond/presentation/shared_widgets/live_editable_field/cubit/live_editable_field_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LiveEditableField extends StatelessWidget {
  const LiveEditableField({
    super.key,
    required this.title,
    required this.initialContent,
    this.allowEdits = false,
    this.allowEmpty = false,
    this.onSave,
  });

  final String title;
  final String initialContent;
  final bool allowEdits;
  final bool allowEmpty;
  final Future<void> Function(String)? onSave;

  static const double textBoxHeight = 60;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LiveEditableFieldCubit(initialContent),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(
              height: 1,
            ),
            BlocBuilder<LiveEditableFieldCubit, LiveEditableFieldState>(
              builder: (context, state) {
                Widget contentField;
                var currentStateContent = ''; // Default empty content

                // TODO: a bit of a hack but I get some type errors otherwise...
                if (state is LiveEditableFieldEditing) {
                  currentStateContent = state.content;
                } else if (state is LiveEditableFieldDisplay) {
                  currentStateContent = state.content;
                }
                if (state.runtimeType == LiveEditableFieldEditing ||
                    state.runtimeType == LiveEditableFieldDisplay) {
                  contentField = EditableContentField(
                    content: currentStateContent,
                    isEditable: state is LiveEditableFieldEditing,
                    allowEdits: allowEdits,
                    onEditComplete: (value) => context
                        .read<LiveEditableFieldCubit>()
                        .updateContent(value),
                    onStartEditing: allowEdits
                        ? () => context
                            .read<LiveEditableFieldCubit>()
                            .startEditing()
                        : null,
                    allowEmpty: allowEmpty,
                    onSave: onSave,
                  );
                } else {
                  contentField = const SizedBox.shrink();
                }
                return contentField;
              },
            )
          ],
        ),
      ),
    );
  }
}

class EditableContentField extends StatefulWidget {
  const EditableContentField({
    super.key,
    required this.content,
    this.isEditable = false,
    this.allowEdits = true,
    required this.onEditComplete,
    this.onStartEditing,
    required this.allowEmpty,
    this.onSave,
  });

  final String content;
  final bool isEditable;
  final bool allowEdits;
  final VoidCallback? onStartEditing;
  final void Function(String) onEditComplete;
  final bool allowEmpty;
  final void Function(String)? onSave;

  @override
  EditableContentFieldState createState() => EditableContentFieldState();
}

class EditableContentFieldState extends State<EditableContentField> {
  late TextEditingController _controller;
  String? _editedContent;
  late FocusNode _focusNode;

  bool get _isSaveAllowed {
    return widget.allowEmpty ||
        (_editedContent != null && _editedContent!.isNotEmpty);
  }

  bool get _hasError => !widget.allowEmpty && (_controller.text.isEmpty);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
    _focusNode = FocusNode();
    _editedContent = widget.content;
  }

  @override
  void didUpdateWidget(EditableContentField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != _controller.text) {
      _controller
        ..text = widget.content
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      _editedContent = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: _hasError ? Colors.red : Colors.transparent,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SizedBox(
        height: LiveEditableField.textBoxHeight,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                onChanged: widget.isEditable
                    ? (value) {
                        _editedContent = value;
                        setState(() {});
                      }
                    : null,
                controller: _controller,
                readOnly: !widget.isEditable,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  fillColor: Colors.transparent,
                  filled: true,
                  hoverColor: Colors.transparent,
                ),
                onTap: widget.onStartEditing,
              ),
            ),
            if (widget.isEditable) ...[
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isSaveAllowed
                    ? () {
                        widget.onEditComplete(_controller.text);
                      }
                    : null,
                color: _isSaveAllowed ? null : Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _isSaveAllowed
                    ? () {
                        widget.onEditComplete(_editedContent!);
                        if (widget.onSave != null) {
                          widget.onSave?.call(_editedContent!);
                        }
                      }
                    : null,
                color: _isSaveAllowed ? null : Colors.grey,
              )
            ] else if (widget.allowEdits) ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  if (widget.onStartEditing != null) {
                    widget.onStartEditing?.call();
                  }
                  _focusNode.requestFocus();
                },
                color: widget.isEditable ? null : Colors.grey,
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
