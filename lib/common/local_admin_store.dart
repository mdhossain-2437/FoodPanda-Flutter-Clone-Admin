import 'dart:async';

import 'package:foodpanda_admin/models/banner.dart' as model;
import 'package:foodpanda_admin/models/category.dart';
import 'package:foodpanda_admin/models/food.dart';
import 'package:foodpanda_admin/models/shop.dart';
import 'package:foodpanda_admin/models/voucher.dart';

class LocalAdminStore {
  static final LocalAdminStore instance = LocalAdminStore._internal();

  LocalAdminStore._internal() {
    _initDefaults();
  }

  final List<Shop> shops = [];
  final Map<String, List<Category>> categoriesBySeller = {};
  final Map<String, List<Food>> foodsByCategoryKey = {};
  final List<Voucher> vouchers = [];
  final List<model.Banner> banners = [];

  final StreamController<void> _changeController =
      StreamController<void>.broadcast();

  void notifyChanges() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  Stream<T> watch<T>(T Function() builder) async* {
    yield builder();
    await for (final _ in _changeController.stream) {
      yield builder();
    }
  }

  String _foodKey(String sellerId, String categoryId) => '$sellerId::$categoryId';

  List<Category> getCategories(String sellerId) {
    return List<Category>.from(categoriesBySeller[sellerId] ?? const []);
  }

  void upsertCategory({
    required String sellerId,
    required String title,
    required String subtitle,
    String? id,
  }) {
    final list = categoriesBySeller.putIfAbsent(sellerId, () => []);
    final categoryId = (id != null && id.isNotEmpty)
        ? id
        : 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final existingIdx = list.indexWhere((c) => c.id == categoryId);
    final updated = Category(
      id: categoryId,
      title: title,
      subtitle: subtitle,
      isPublished: existingIdx >= 0 ? list[existingIdx].isPublished : true,
    );
    if (existingIdx >= 0) {
      list[existingIdx] = updated;
    } else {
      list.add(updated);
    }
    notifyChanges();
  }

  void setCategoryPublished(String sellerId, String id, bool isPublished) {
    final list = categoriesBySeller[sellerId];
    if (list == null) return;
    final idx = list.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      list[idx] = Category(
        id: list[idx].id,
        title: list[idx].title,
        subtitle: list[idx].subtitle,
        isPublished: isPublished,
      );
      notifyChanges();
    }
  }

  void removeCategory(String sellerId, String id) {
    categoriesBySeller[sellerId]?.removeWhere((c) => c.id == id);
    foodsByCategoryKey.remove(_foodKey(sellerId, id));
    notifyChanges();
  }

  List<Food> getFoods(String sellerId, String categoryId) {
    return List<Food>.from(
      foodsByCategoryKey[_foodKey(sellerId, categoryId)] ?? const [],
    );
  }

  Food? getFoodById(String sellerId, String categoryId, String id) {
    final list = foodsByCategoryKey[_foodKey(sellerId, categoryId)] ?? const [];
    for (final item in list) {
      if (item.id == id) return item;
    }
    return null;
  }

  void upsertFood({
    required String sellerId,
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required double comparePrice,
    required String image,
    String? foodId,
  }) {
    final list =
        foodsByCategoryKey.putIfAbsent(_foodKey(sellerId, categoryId), () => []);
    final resolvedId = (foodId != null && foodId.isNotEmpty)
        ? foodId
        : 'food_${DateTime.now().millisecondsSinceEpoch}';
    final idx = list.indexWhere((f) => f.id == resolvedId);
    final food = Food(
      id: resolvedId,
      name: name,
      description: description,
      image: image,
      price: price,
      comparePrice: comparePrice,
      isPublished: idx >= 0 ? list[idx].isPublished : true,
    );
    if (idx >= 0) {
      list[idx] = food;
    } else {
      list.add(food);
    }
    notifyChanges();
  }

  void setFoodPublished(
    String sellerId,
    String categoryId,
    String id,
    bool isPublished,
  ) {
    final list = foodsByCategoryKey[_foodKey(sellerId, categoryId)];
    if (list == null) return;
    final idx = list.indexWhere((f) => f.id == id);
    if (idx >= 0) {
      final old = list[idx];
      list[idx] = Food(
        id: old.id,
        name: old.name,
        description: old.description,
        image: old.image,
        price: old.price,
        comparePrice: old.comparePrice,
        isPublished: isPublished,
      );
      notifyChanges();
    }
  }

  void removeFood(String sellerId, String categoryId, String id) {
    foodsByCategoryKey[_foodKey(sellerId, categoryId)]
        ?.removeWhere((f) => f.id == id);
    notifyChanges();
  }

  String? addVoucher(Voucher voucher) {
    final duplicate = vouchers.any(
      (v) => v.name.toLowerCase() == voucher.name.trim().toLowerCase(),
    );
    if (duplicate) {
      return 'This voucher name already existed!';
    }
    voucher.id = voucher.id.isNotEmpty
        ? voucher.id
        : 'vch_${DateTime.now().millisecondsSinceEpoch}';
    vouchers.insert(0, voucher);
    notifyChanges();
    return null;
  }

  void removeVoucher(String id) {
    vouchers.removeWhere((v) => v.id == id);
    notifyChanges();
  }

  void addBanner(model.Banner banner) {
    banners.insert(0, banner);
    notifyChanges();
  }

  void setBannerApproved(String bannerId, bool isApproved) {
    final idx = banners.indexWhere((b) => b.id == bannerId);
    if (idx >= 0) {
      banners[idx].isApproved = isApproved;
      notifyChanges();
    }
  }

  void removeBanner(String bannerId) {
    banners.removeWhere((b) => b.id == bannerId);
    notifyChanges();
  }

  void _initDefaults() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const dayMs = 24 * 60 * 60 * 1000;

    shops.addAll([
      Shop(
        uid: 'shop_burger_district',
        shopName: 'Burger District Craft Kitchen',
        shopDescription: 'Burgers • American • Crispy Fries',
        remainingTime: 20,
        deliveryPrice: 1.49,
        shopImage:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
        rating: 4.9,
        totalRating: 340,
        houseNumber: '142',
        street: 'Market Street',
        area: 'Downtown',
        latitude: 13.7563,
        longitude: 100.5018,
        province: 'Metro City',
        floor: 'G',
        isApproved: true,
      ),
      Shop(
        uid: 'shop_sakura_sushi',
        shopName: 'Sakura Omakase & Ramen Bar',
        shopDescription: 'Japanese • Sushi • Tonkotsu Ramen',
        remainingTime: 30,
        deliveryPrice: 2.49,
        shopImage:
            'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800&q=80',
        rating: 4.8,
        totalRating: 215,
        houseNumber: '88',
        street: 'Lotus Avenue',
        area: 'Midtown',
        latitude: 13.7640,
        longitude: 100.5380,
        province: 'Metro City',
        floor: '1F',
        isApproved: true,
      ),
      Shop(
        uid: 'shop_napoli_pizza',
        shopName: 'Bella Napoli Woodfired Pizza',
        shopDescription: 'Italian • Neapolitan Pizza • Pasta',
        remainingTime: 25,
        deliveryPrice: 1.99,
        shopImage:
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
        rating: 4.7,
        totalRating: 189,
        houseNumber: '55',
        street: 'Olive Boulevard',
        area: 'Westside',
        latitude: 13.7510,
        longitude: 100.4920,
        province: 'Metro City',
        floor: 'G',
        isApproved: true,
      ),
    ]);

    categoriesBySeller['shop_burger_district'] = [
      Category(
        id: 'cat_signature_burgers',
        title: 'Signature Smash Burgers',
        subtitle: 'Double-seared Angus patties on toasted brioche buns',
        isPublished: true,
      ),
      Category(
        id: 'cat_loaded_sides',
        title: 'Loaded Fries & Sides',
        subtitle: 'Hand-cut fries, truffle parmesan & crispy onion rings',
        isPublished: true,
      ),
    ];

    categoriesBySeller['shop_sakura_sushi'] = [
      Category(
        id: 'cat_sushi_rolls',
        title: 'Chef Special Rolls',
        subtitle: 'Fresh sashimi-grade salmon, tuna & dragon rolls',
        isPublished: true,
      ),
    ];

    categoriesBySeller['shop_napoli_pizza'] = [
      Category(
        id: 'cat_woodfired_pizza',
        title: 'Artisan Woodfired Pizzas',
        subtitle: '72-hour fermented sourdough crust baked at 900°F',
        isPublished: true,
      ),
    ];

    foodsByCategoryKey[_foodKey('shop_burger_district', 'cat_signature_burgers')] = [
      Food(
        id: 'food_truffle_smash',
        name: 'Double Truffle Smash Burger',
        description:
            'Two Wagyu smash patties, aged Swiss cheese, caramelized onions, and black truffle aioli.',
        image:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
        price: 12.99,
        comparePrice: 15.99,
        isPublished: true,
      ),
      Food(
        id: 'food_smokehouse_burger',
        name: 'Crispy Jalapeño Smokehouse',
        description:
            'Smoked bacon, pepper jack cheese, crispy pickled jalapeños, and smoky BBQ glaze.',
        image:
            'https://images.unsplash.com/photo-1550547660-d9450f859349?w=800&q=80',
        price: 11.49,
        comparePrice: 13.50,
        isPublished: true,
      ),
    ];

    foodsByCategoryKey[_foodKey('shop_burger_district', 'cat_loaded_sides')] = [
      Food(
        id: 'food_truffle_fries',
        name: 'Parmesan Truffle Shoestring Fries',
        description:
            'Crispy golden fries tossed in white truffle oil, grated Parmigiano, and fresh parsley.',
        image:
            'https://images.unsplash.com/photo-1576107232684-1279f3908594?w=800&q=80',
        price: 5.99,
        comparePrice: 7.49,
        isPublished: true,
      ),
    ];

    foodsByCategoryKey[_foodKey('shop_sakura_sushi', 'cat_sushi_rolls')] = [
      Food(
        id: 'food_dragon_roll',
        name: 'Golden Dragon Tempura Roll',
        description:
            'Shrimp tempura, avocado, cucumber topped with torched unagi and sweet kabayaki glaze.',
        image:
            'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800&q=80',
        price: 14.50,
        comparePrice: 17.00,
        isPublished: true,
      ),
    ];

    foodsByCategoryKey[_foodKey('shop_napoli_pizza', 'cat_woodfired_pizza')] = [
      Food(
        id: 'food_margherita_dop',
        name: 'Margherita di Bufala D.O.P.',
        description:
            'San Marzano tomato sauce, fresh buffalo mozzarella, sweet basil, and extra virgin olive oil.',
        image:
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
        price: 13.99,
        comparePrice: 16.99,
        isPublished: true,
      ),
    ];

    vouchers.addAll([
      Voucher(
        id: 'vch_panda50',
        name: 'PANDA50',
        isNewUser: true,
        startingDate: now - 2 * dayMs,
        expiredDate: now + 30 * dayMs,
        createdDate: now,
        minPrice: 15.0,
        discountPrice: null,
        discountPercentage: 50.0,
        freeDelivery: true,
      ),
      Voucher(
        id: 'vch_feast10',
        name: 'FEAST10',
        isNewUser: false,
        startingDate: now - 5 * dayMs,
        expiredDate: now + 20 * dayMs,
        createdDate: now - 1000,
        minPrice: 25.0,
        discountPrice: 10.0,
        discountPercentage: null,
        freeDelivery: false,
      ),
    ]);

    banners.addAll([
      model.Banner(
        id: 'bnr_mega_fest',
        imageUrl:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
        description: 'Mega Food Fest: Up to 50% OFF Top Rated Restaurants!',
        creatorId: 'admin_01',
        shopListId: ['shop_burger_district', 'shop_sakura_sushi'],
        isApproved: true,
        createdAt: now,
        voucherId: 'vch_panda50',
      ),
      model.Banner(
        id: 'bnr_pizza_night',
        imageUrl:
            'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&q=80',
        description: 'Weekend Woodfired Pizza & Craft Burger Deals (\$10 Off)',
        creatorId: 'admin_01',
        shopListId: ['shop_napoli_pizza', 'shop_burger_district'],
        isApproved: true,
        createdAt: now - 3600000,
        voucherId: 'vch_feast10',
      ),
    ]);
  }
}
