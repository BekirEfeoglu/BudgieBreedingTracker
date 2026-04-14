import 'package:go_router/go_router.dart';

import '../../core/widgets/not_found_screen.dart';
import '../../features/marketplace/screens/marketplace_detail_screen.dart';
import '../../features/marketplace/screens/marketplace_form_screen.dart';
import '../../features/marketplace/screens/marketplace_favorites_screen.dart';
import '../../features/marketplace/screens/marketplace_my_listings_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/marketplace/screens/marketplace_seller_listings_screen.dart';
import '../route_names.dart';
import '../route_utils.dart';

/// Marketplace feature routes (listings, detail, form, my listings).
List<RouteBase> buildMarketplaceRoutes() => [
      GoRoute(
        path: AppRoutes.marketplace,
        builder: (context, state) => const MarketplaceScreen(),
        routes: [
          // Specific paths BEFORE parameterized paths
          GoRoute(
            path: 'favorites',
            builder: (context, state) => const MarketplaceFavoritesScreen(),
          ),
          GoRoute(
            path: 'form',
            builder: (context, state) => MarketplaceFormScreen(
              editListingId: state.uri.queryParameters['editId'],
            ),
          ),
          GoRoute(
            path: 'my-listings',
            builder: (context, state) => const MarketplaceMyListingsScreen(),
          ),
          GoRoute(
            path: 'seller/:sellerId',
            builder: (context, state) {
              final sellerId = state.pathParameters['sellerId']!;
              if (!isValidRouteId(sellerId)) return const NotFoundScreen();
              return MarketplaceSellerListingsScreen(sellerId: sellerId);
            },
          ),
          // Parameterized paths AFTER specific paths
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              if (!isValidRouteId(id)) return const NotFoundScreen();
              return MarketplaceDetailScreen(listingId: id);
            },
          ),
        ],
      ),
    ];
