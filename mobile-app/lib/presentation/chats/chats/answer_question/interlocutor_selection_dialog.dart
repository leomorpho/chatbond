import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';

class InterlocutorSelectorDialog extends StatefulWidget {
  const InterlocutorSelectorDialog({
    super.key,
    required this.interlocutors,
    required this.interlocutorToDraftMap,
    this.selectedInterlocutor,
  });

  final List<Interlocutor> interlocutors;
  final Map<Interlocutor, DraftQuestionThread>? interlocutorToDraftMap;
  final Interlocutor? selectedInterlocutor;

  @override
  InterlocutorSelectorDialogState createState() =>
      InterlocutorSelectorDialogState();
}

class InterlocutorSelectorDialogState
    extends State<InterlocutorSelectorDialog> {
  int? _selectedInterlocutorIndex;

  @override
  void initState() {
    super.initState();

    // pre-select selectedInterlocutor
    if (widget.selectedInterlocutor != null) {
      _selectedInterlocutorIndex =
          widget.interlocutors.indexOf(widget.selectedInterlocutor!);
    }
  }

  bool checkIfPublished(Interlocutor interlocutor) {
    final draft = widget.interlocutorToDraftMap?[interlocutor];
    return draft?.publishedAt != null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.interlocutors.isEmpty) ...[
                const Text("You'll need to add a friend first :)"),
              ],
              if (widget.interlocutors.isNotEmpty) ...[
                const Text('Select an Interlocutor'),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.interlocutors.length,
                  itemBuilder: (context, index) {
                    final interlocutor = widget.interlocutors[index];
                    final hasDraft = widget.interlocutorToDraftMap
                            ?.containsKey(interlocutor) ??
                        false;
                    final draftPublished = checkIfPublished(interlocutor);
                    return RadioListTile<int>(
                      value: index,
                      groupValue: _selectedInterlocutorIndex,
                      onChanged: draftPublished
                          ? null // disable selection if draft is published
                          : (int? value) {
                              setState(() {
                                _selectedInterlocutorIndex = value;
                              });
                            },
                      title: Text(
                        draftPublished
                            ? '${interlocutor.name} - Already answered'
                            : hasDraft
                                ? '${interlocutor.name} - draft in progress'
                                : interlocutor.name,
                      ),
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _selectedInterlocutorIndex != null
                          ? widget.interlocutors[_selectedInterlocutorIndex!]
                          : null,
                    );
                  },
                  child: const Text('Submit'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
