import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AppleIAPService {
  static final AppleIAPService _instance = AppleIAPService._internal();
  factory AppleIAPService() => _instance;
  AppleIAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isInitialized = false;

  final _purchaseStatusController = StreamController<PurchaseStatus>.broadcast();
  Stream<PurchaseStatus> get purchaseStatusStream => _purchaseStatusController.stream;

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _isAvailable = await _iap.isAvailable();
    } catch (e) {
      debugPrint('IAP: Error checking availability: $e');
      _isAvailable = false;
      return;
    }

    if (!_isAvailable) {
      debugPrint('IAP: Store not available');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (error) {
        debugPrint('IAP: Purchase stream error: $error');
        _purchaseStatusController.add(PurchaseStatus.error);
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(AppConfig.appleProductIds);

    if (response.error != null) {
      debugPrint('IAP: Error loading products: ${response.error}');
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('IAP: Loaded ${_products.length} products');
  }

  Future<bool> buySubscription(String productId) async {
    if (!_isAvailable) {
      debugPrint('IAP: Store not available, cannot purchase');
      return false;
    }

    if (_products.isEmpty) {
      debugPrint('IAP: No products loaded, retrying...');
      await _loadProducts();
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Produto não encontrado. Verifique sua conexão e tente novamente.'),
    );

    debugPrint('IAP: Purchasing ${product.id} - ${product.title} - ${product.price}');
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    debugPrint('IAP: Purchase update - ${purchase.productID} status: ${purchase.status}');

    switch (purchase.status) {
      case PurchaseStatus.pending:
        _purchaseStatusController.add(PurchaseStatus.pending);
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyAndActivate(purchase);
        _purchaseStatusController.add(PurchaseStatus.purchased);
        break;

      case PurchaseStatus.error:
        debugPrint('IAP: Purchase error: ${purchase.error}');
        _purchaseStatusController.add(PurchaseStatus.error);
        break;

      case PurchaseStatus.canceled:
        _purchaseStatusController.add(PurchaseStatus.canceled);
        break;
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();

      final plan = _productIdToPlan(purchase.productID);

      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/apple/activate-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productId': purchase.productID,
          'transactionId': purchase.purchaseID,
          'plan': plan,
          'verificationData': purchase.verificationData.serverVerificationData,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('IAP: Subscription activated successfully');
      } else {
        debugPrint('IAP: Failed to activate: ${response.body}');
      }
    } catch (e) {
      debugPrint('IAP: Error activating subscription: $e');
    }
  }

  String _productIdToPlan(String productId) {
    switch (productId) {
      case AppConfig.appleMonthlyProductId:
        return 'monthly';
      case AppConfig.appleQuarterlyProductId:
        return 'quarterly';
      case AppConfig.appleYearlyProductId:
        return 'yearly';
      default:
        return 'monthly';
    }
  }

  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseStatusController.close();
  }
}
