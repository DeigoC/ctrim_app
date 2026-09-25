import 'package:go_router/go_router.dart';

import '../models/event/event_head.dart';
import '../models/info/church_info.dart';
import '../models/user.dart';
import '../pages/cell_groups/cell_group_detail_page.dart';
import '../pages/events/open_post_page.dart';
import '../pages/home_page.dart';
import '../pages/information/church_info_page.dart';
import '../pages/information/church_page_info_page.dart';
import '../pages/information/church_pastors_page.dart';
import '../pages/information/ctrim_info_page.dart';
import '../pages/information/testimonial_info_page.dart';
import '../pages/personal/open_person_page.dart';
import '../utility/app_links.dart';

String _routeId(GoRouterState state, [String key = 'id']) {
  return Uri.decodeComponent(state.pathParameters[key] ?? '');
}

GoRouter createAppRouter() {
  // push/replace leave the address bar unchanged unless this is set.
  // Permalink opens use context.push, and those paths are real routes.
  GoRouter.optionURLReflectsImperativeAPIs = true;
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
              final id = _routeId(state);
              final extra = state.extra;
              final head = extra is EventHead && extra.id == id ? extra : null;
              return OpenPostPage(postId: id, initialHead: head);
            },
          ),
          GoRoute(
            path: 'cell-groups/:id',
            builder: (context, state) =>
                CellGroupDetailPage(groupId: _routeId(state)),
          ),
          GoRoute(
            path: 'churches/:id',
            builder: (context, state) {
              final id = _routeId(state);
              final extra = state.extra;
              final church =
                  extra is ChurchInfo && extra.id == id ? extra : null;
              return ChurchInfoPage(documentId: id, initialChurch: church);
            },
            routes: [
              GoRoute(
                path: 'pages/:pageId',
                builder: (context, state) => ChurchPageInfoPage(
                  churchId: _routeId(state),
                  documentId: _routeId(state, 'pageId'),
                ),
              ),
              GoRoute(
                path: 'pastors',
                builder: (context, state) =>
                    ChurchPastorsPage(documentId: _routeId(state)),
              ),
            ],
          ),
          GoRoute(
            path: 'info/:id',
            builder: (context, state) => CTRIMInfoPage(
              documentId: AppLinks.infoDocumentIdFromPayload(_routeId(state)),
            ),
          ),
          GoRoute(
            path: 'testimonials/:id',
            builder: (context, state) =>
                TestimonialInfoPage(documentId: _routeId(state)),
          ),
          GoRoute(
            path: 'people/:id',
            builder: (context, state) {
              final id = _routeId(state);
              final extra = state.extra;
              final user = extra is User && extra.id == id ? extra : null;
              return OpenPersonPage(userId: id, initialUser: user);
            },
          ),
        ],
      ),
    ],
  );
}
