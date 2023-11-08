import 'package:bloc/bloc.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:loggy/loggy.dart';

enum ActivationState { initial, activated, failed }

class AccountActivationCubit extends Cubit<ActivationState> {
  AccountActivationCubit({required this.userRepo})
      : super(ActivationState.initial);

  final UserRepo userRepo;

  Future<void> activateUser(String uid, String token) async {
    try {
      final activationSuccess = await userRepo.activateUser(uid, token);
      if (activationSuccess) {
        logInfo('Successfully activated user');
        emit(ActivationState.activated);
      } else {
        logError('Failed to activate user');
        emit(ActivationState.failed);
      }
    } catch (e) {
      logError('Exception during activation: $e');
      emit(ActivationState.failed);
    }
  }
}
