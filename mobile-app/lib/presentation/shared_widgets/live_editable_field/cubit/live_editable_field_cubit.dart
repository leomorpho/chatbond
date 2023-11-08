import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'live_editable_field_state.dart';

class LiveEditableFieldCubit extends Cubit<LiveEditableFieldState> {
  LiveEditableFieldCubit(String initialContent)
      : super(LiveEditableFieldDisplay(content: initialContent));

  void startEditing() {
    if (state is LiveEditableFieldDisplay) {
      emit(LiveEditableFieldEditing(
          content: (state as LiveEditableFieldDisplay).content));
    }
  }

  void updateContent(String newContent) {
    emit(LiveEditableFieldDisplay(content: newContent));
  }

  void cancelEditing() {
    if (state is LiveEditableFieldEditing) {
      emit(LiveEditableFieldDisplay(
          content: (state as LiveEditableFieldEditing).content));
    }
  }
}
