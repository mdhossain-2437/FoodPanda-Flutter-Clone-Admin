import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodpanda_admin/common/local_admin_store.dart';
import 'package:foodpanda_admin/models/voucher.dart';

class VoucherController {
  final LocalAdminStore _store = LocalAdminStore.instance;

  Future<String?> addNewVoucher({
    required Voucher voucher,
  }) async {
    final duplicateError = _store.addVoucher(voucher);
    if (duplicateError != null) {
      return duplicateError;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final result = await firestore
          .collection('vouchers')
          .where('name', isEqualTo: voucher.name)
          .get()
          .timeout(const Duration(seconds: 3));
      if (result.docs.isEmpty) {
        final ref = firestore.collection('vouchers').doc(voucher.id);
        await ref.set(voucher.toMap()).timeout(const Duration(seconds: 3));
      }
    } catch (error) {
      debugPrint(error.toString());
    }
    return null;
  }

  Stream<List<Voucher>> fetchVouchers() {
    return _store.watch(() => List<Voucher>.from(_store.vouchers));
  }

  Future<void> deleteVoucher({
    required String id,
  }) async {
    _store.removeVoucher(id);
    try {
      await FirebaseFirestore.instance
          .collection('vouchers')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint(error.toString());
    }
  }
}
