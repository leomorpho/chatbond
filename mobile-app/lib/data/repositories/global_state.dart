import 'package:chatbond_api/chatbond_api.dart';

class GlobalState {
  User? currUser;
  Interlocutor? currentInterlocutor;
  List<Interlocutor>? connectedInterlocutors = [];
}
