part of 'live_editable_field_cubit.dart';

abstract class LiveEditableFieldState extends Equatable {
  const LiveEditableFieldState();

  @override
  List<Object> get props => [];
}

class LiveEditableFieldDisplay extends LiveEditableFieldState {
  const LiveEditableFieldDisplay({required this.content});

  final String content;

  @override
  List<Object> get props => [content];
}

class LiveEditableFieldEditing extends LiveEditableFieldState {
  const LiveEditableFieldEditing({required this.content});

  final String content;

  @override
  List<Object> get props => [content];
}
