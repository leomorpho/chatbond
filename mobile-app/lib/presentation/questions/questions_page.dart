import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';

@RoutePage()
class QuestionsPage extends StatelessWidget {
  const QuestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: MaxWidthView(
          child: Column(
            children: [
              Container(
                child: const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.explore),
                      // Make tab headers smaller
                      text: 'Explore',
                    ),
                    Tab(
                      icon: Icon(Icons.favorite),
                      // Make tab headers smaller
                      text: 'Favorites',
                    ),
                  ],
                  labelStyle: TextStyle(fontSize: 12), // Smaller text size
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    SearchTabPage(),
                    // QuestionsFeedWidget(),
                    FavoritesPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchTabPage extends StatelessWidget {
  const SearchTabPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: TextField(
            // controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              // Perform search functionality here
            },
          ),
        ),
        body: const Center(
          child: Text(
            'Search results will appear here',
            // style: TextStyle(color: Colors.white),
          ),
        ),
        // backgroundColor: Colors.deepPurple.shade900,
      );
}

class QuestionFeedPage extends StatelessWidget {
  const QuestionFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text('Dummy Question ${index + 1}'),
            subtitle:
                Text('This is the content of dummy question ${index + 1}.'),
          ),
        );
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text('Favorite Dummy Question ${index + 1}'),
            subtitle: Text(
              'This is the content of favorite dummy question ${index + 1}.',
            ),
          ),
        );
      },
    );
  }
}
// class ExploreTab extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ExploreCubit, List<Question>>(
//       builder: (context, questions) {
//         // Your UI here, e.g.:
//         return ListView.builder(
//           itemCount: questions.length,
//           itemBuilder: (context, index) {
//             return ListTile(
//               title: Text(questions[index].title),
//               // Other properties...
//             );
//           },
//         );
//       },
//     );
//   }
// }

// class FavoritesTab extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<FavoritesCubit, List<Question>>(
//       builder: (context, questions) {
//         // Your UI here, e.g.:
//         return ListView.builder(
//           itemCount: questions.length,
//           itemBuilder: (context, index) {
//             return ListTile(
//               title: Text(questions[index].title),
//               // Other properties...
//             );
//           },
//         );
//       },
//     );
//   }
// }
