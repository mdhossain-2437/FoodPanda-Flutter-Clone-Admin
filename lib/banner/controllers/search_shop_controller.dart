import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodpanda_admin/common/local_admin_store.dart';
import 'package:foodpanda_admin/models/shop.dart';

class SearchShopController {
  final LocalAdminStore _store = LocalAdminStore.instance;

  Future<List<Shop>> fetchSearchResult({
    required String search,
  }) async {
    final query = search.trim().toLowerCase();
    try {
      final shopSnapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .get()
          .timeout(const Duration(seconds: 3));
      if (shopSnapshot.docs.isNotEmpty) {
        final remoteShops = shopSnapshot.docs
            .map((doc) => Shop.fromMap(doc.data()))
            .where(
              (s) =>
                  s.isApproved &&
                  (query.isEmpty ||
                      s.shopName.toLowerCase().contains(query) ||
                      s.shopDescription.toLowerCase().contains(query)),
            )
            .toList();
        if (remoteShops.isNotEmpty) {
          return remoteShops;
        }
      }
    } catch (_) {}

    return _store.shops
        .where(
          (s) =>
              s.isApproved &&
              (query.isEmpty ||
                  s.shopName.toLowerCase().contains(query) ||
                  s.shopDescription.toLowerCase().contains(query)),
        )
        .toList();
  }
}
