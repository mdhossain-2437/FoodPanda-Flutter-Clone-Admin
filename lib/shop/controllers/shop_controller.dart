import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodpanda_admin/common/firebare_storage_repository.dart';
import 'package:foodpanda_admin/common/local_admin_store.dart';
import 'package:foodpanda_admin/models/category.dart';
import 'package:foodpanda_admin/models/food.dart';
import 'package:foodpanda_admin/models/shop.dart';
import 'package:image_picker/image_picker.dart';

class ShopController {
  final LocalAdminStore _store = LocalAdminStore.instance;

  Future<void> addNewCategory({
    required String sellerId,
    required String title,
    required String subtitle,
    String? id,
  }) async {
    _store.upsertCategory(
      sellerId: sellerId,
      title: title,
      subtitle: subtitle,
      id: id,
    );
    try {
      final firestore = FirebaseFirestore.instance;
      final DocumentReference ref;
      if (id != null && id.isNotEmpty) {
        ref = firestore
            .collection('sellers')
            .doc(sellerId)
            .collection('categories')
            .doc(id);
      } else {
        ref = firestore
            .collection('sellers')
            .doc(sellerId)
            .collection('categories')
            .doc();
      }
      await ref.set({
        'title': title,
        'subtitle': subtitle,
        'id': ref.id,
        'isPublished': true,
      }).timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> deleteCategory({
    required String sellerId,
    required String id,
  }) async {
    _store.removeCategory(sellerId, id);
    try {
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('categories')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<List<Shop>> fetchShop() async {
    try {
      final shopSnapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .get()
          .timeout(const Duration(seconds: 3));
      if (shopSnapshot.docs.isNotEmpty) {
        return shopSnapshot.docs.map((doc) => Shop.fromMap(doc.data())).toList();
      }
    } catch (error) {
      debugPrint(error.toString());
    }
    return List<Shop>.from(_store.shops);
  }

  Stream<List<Category>> fetchCategory({required String sellerId}) {
    return _store.watch(() => _store.getCategories(sellerId));
  }

  Future<void> changeIsPublished({
    required String sellerId,
    required String id,
    required bool isPublished,
  }) async {
    _store.setCategoryPublished(sellerId, id, isPublished);
    try {
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('categories')
          .doc(id)
          .set({'isPublished': isPublished}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Stream<List<Food>> fetchFood({
    required String sellerId,
    required String categoryId,
  }) {
    return _store.watch(() => _store.getFoods(sellerId, categoryId));
  }

  Future<void> changeIsPublishedFood({
    required String sellerId,
    required String categoryId,
    required String id,
    required bool isPublished,
  }) async {
    _store.setFoodPublished(sellerId, categoryId, id, isPublished);
    try {
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('categories')
          .doc(categoryId)
          .collection('foods')
          .doc(id)
          .set({'isPublished': isPublished}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> addNewFood({
    required String sellerId,
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required double comparePrice,
    required XFile? imageFile,
    String? imageUrl,
    String? foodId,
  }) async {
    String foodImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      foodImage = imageUrl;
    } else if (imageFile != null) {
      foodImage = await storeFileToFirebase(
        'seller/$sellerId/$categoryId/${foodId ?? DateTime.now().millisecondsSinceEpoch}',
        imageFile,
      );
    } else {
      foodImage =
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80';
    }

    _store.upsertFood(
      sellerId: sellerId,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      comparePrice: comparePrice,
      image: foodImage,
      foodId: foodId,
    );

    try {
      final firestore = FirebaseFirestore.instance;
      final DocumentReference ref;
      if (foodId != null && foodId.isNotEmpty) {
        ref = firestore
            .collection('sellers')
            .doc(sellerId)
            .collection('categories')
            .doc(categoryId)
            .collection('foods')
            .doc(foodId);
      } else {
        ref = firestore
            .collection('sellers')
            .doc(sellerId)
            .collection('categories')
            .doc(categoryId)
            .collection('foods')
            .doc();
      }
      await ref.set({
        'id': ref.id,
        'name': name,
        'description': description,
        'price': price,
        'comparePrice': comparePrice,
        'image': foodImage,
        'isPublished': true,
      }).timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<Food?> fetchFoodById({
    required String sellerId,
    required String categoryId,
    required String id,
  }) async {
    final localFood = _store.getFoodById(sellerId, categoryId, id);
    if (localFood != null) return localFood;
    try {
      final foodData = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('categories')
          .doc(categoryId)
          .collection('foods')
          .doc(id)
          .get()
          .timeout(const Duration(seconds: 3));
      if (foodData.data() != null) {
        return Food.fromMap(foodData.data()!);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
    return null;
  }

  Future<void> deleteFood({
    required String sellerId,
    required String categoryId,
    required String id,
  }) async {
    _store.removeFood(sellerId, categoryId, id);
    try {
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('categories')
          .doc(categoryId)
          .collection('foods')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }
}
