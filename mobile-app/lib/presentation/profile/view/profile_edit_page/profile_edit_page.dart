import 'package:auto_route/auto_route.dart';
import 'package:chatbond/bootstrap.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/profile/view/profile_page/cubit/profile_page_cubit.dart';
import 'package:chatbond/presentation/shared_widgets/live_editable_field/live_editable_field.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfilePageCubit>(
      create: (context) => ProfilePageCubit(
        context.read<UserRepo>(),
        context.read<ChatThreadsRepo>(),
        context.read<QuestionsRepo>(),
        context.read<ChatProvider>().numTotalNotificationsController.stream,
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: MaxWidthView(
          child: BlocBuilder<ProfilePageCubit, ProfilePageState>(
            builder: (context, state) {
              if (state is ProfilePageLoadSuccess) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      LiveEditableField(
                        title: 'Name',
                        initialContent: state.user.name,
                        allowEdits: true,
                        onSave:
                            BlocProvider.of<ProfilePageCubit>(context).saveName,
                      ),
                      /**
                       * TODO: to change email, logout and follow reset email flow,
                       * let user know with message if they try to click on this one.
                       */
                      LiveEditableField(
                        title: 'Email',
                        initialContent: state.user.email,
                      ),
                      if (state.user.dateOfBirth != null)
                        LiveEditableField(
                          title: 'Date of Birth',
                          initialContent: state.user.dateOfBirth!,
                        ),
                    ],
                  ),
                );
              }
              if (state is ProfilePageLoadFailure) {
                return const Text('Failed to load user data');
              }
              return const Center(
                child: LoadingDialog(),
              ); // loading state
            },
          ),
        ),
      ),
    );
  }
}
