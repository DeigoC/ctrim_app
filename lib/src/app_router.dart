import 'package:go_router/go_router.dart';

import '../models/event/event_head.dart';
import '../pages/events/open_post_page.dart';
import '../pages/home_page.dart';
import '../utility/app_links.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    restorationScopeId: 'router',
    redirect: (context, state) => AppLinks.redirectFromUri(state.uri),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'post/:id',
            builder: (context, state) {
              final rawId = state.pathParameters['id'] ?? '';
              final id = Uri.decodeComponent(rawId);
              final extra = state.extra;
              final head = extra is EventHead && extra.id == id ? extra : null;
              return OpenPostPage(postId: id, initialHead: head);
            },
          ),
        ],
      ),
    ],
  );
}
