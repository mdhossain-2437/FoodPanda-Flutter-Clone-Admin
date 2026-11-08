import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodpanda_admin/common/firebare_storage_repository.dart';
import 'package:foodpanda_admin/common/local_admin_store.dart';
import 'package:foodpanda_admin/models/banner.dart' as model;
import 'package:image_picker/image_picker.dart';

class BannerController {
  final LocalAdminStore _store = LocalAdminStore.instance;

  Future<void> createBanner({
    required XFile image,
    required String description,
    required List<String> shopListId,
    String? voucherId,
  }) async {
    final id = 'bnr_${DateTime.now().millisecondsSinceEpoch}';
    String creatorUid = 'admin_01';
    try {
      creatorUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin_01';
    } catch (_) {}

    final imageUrl = await storeFileToFirebase(
      'seller/$creatorUid/banner/$id',
      image,
    );

    final banner = model.Banner(
      id: id,
      imageUrl: imageUrl,
      description: description,
      creatorId: creatorUid,
      shopListId: shopListId,
      isApproved: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      voucherId: voucherId,
    );

    _store.addBanner(banner);

    try {
      await FirebaseFirestore.instance
          .collection('banners')
          .doc(id)
          .set(banner.toMap())
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Stream<List<model.Banner>> fetchBanner() {
    return _store.watch(() => List<model.Banner>.from(_store.banners));
  }

  Future<void> changeBannerApproved({
    required String bannerId,
    required bool isApproved,
  }) async {
    _store.setBannerApproved(bannerId, isApproved);
    try {
      await FirebaseFirestore.instance
          .collection('banners')
          .doc(bannerId)
          .set({'isApproved': isApproved}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> deleteBanner({
    required String bannerId,
  }) async {
    _store.removeBanner(bannerId);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'admin_01';
      await deleteFileStorage('seller/$uid/banner/$bannerId');
      await FirebaseFirestore.instance
          .collection('banners')
          .doc(bannerId)
          .delete()
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }
}
