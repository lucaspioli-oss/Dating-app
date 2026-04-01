import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    _isInitialized = true;
  }

  /// Reload products (e.g. after a failed initial load or when screen opens)
  Future<void> reloadProducts() async {
    if (_products.isNotEmpty) return;
    debugPrint('IAP: Reloading products...');
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    const maxRetries = 3;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('IAP: Loading products (attempt $attempt/$maxRetries)...');
        final response = await _iap.queryProductDetails(AppConfig.appleProductIds);

        if (response.error != null) {
          debugPrint('IAP: Error loading products: ${response.error}');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          return;
        }

        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('IAP: Products not found: ${response.notFoundIDs}');
        }

        _products = response.productDetails;
        debugPrint('IAP: Loaded ${_products.length} products: ${_products.map((p) => '${p.id}=${p.price}').join(', ')}');

        if (_products.isNotEmpty) return;

        // Products empty — retry
        debugPrint('IAP: No products returned, will retry...');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e) {
        debugPrint('IAP: Exception loading products: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
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
        final success = await _verifyAndActivate(purchase);
        _purchaseStatusController.add(
          success ? PurchaseStatus.purchased : PurchaseStatus.error,
        );
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

  Future<bool> _verifyAndActivate(PurchaseDetails purchase) async {
    const maxRetries = 3;

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Refresh session if needed
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          debugPrint('IAP: No active session, attempting refresh...');
          await Supabase.instance.client.auth.refreshSession();
          final refreshed = Supabase.instance.client.auth.currentSession;
          if (refreshed == null) {
            debugPrint('IAP: Session refresh failed');
            return false;
          }
        }

        final token = Supabase.instance.client.auth.currentSession!.accessToken;
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
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          debugPrint('IAP: Subscription activated successfully');
          return true;
        } else {
          debugPrint('IAP: Failed to activate (attempt $attempt/$maxRetries): ${response.body}');
        }
      } catch (e) {
        debugPrint('IAP: Error activating (attempt $attempt/$maxRetries): $e');
      }

      if (attempt < maxRetries) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    debugPrint('IAP: All activation attempts failed');
    return false;
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

  /// Restore purchases and wait for the result.
  /// Returns true if a purchase was successfully restored and activated.
  Future<bool> restorePurchases() async {
    final completer = Completer<bool>();
    StreamSubscription<PurchaseStatus>? sub;
    Timer? timeout;

    sub = purchaseStatusStream.listen((status) {
      if (status == PurchaseStatus.purchased) {
        timeout?.cancel();
        sub?.cancel();
        if (!completer.isCompleted) completer.complete(true);
      } else if (status == PurchaseStatus.error) {
        timeout?.cancel();
        sub?.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    // Timeout after 15 seconds if no response from Apple
    timeout = Timer(const Duration(seconds: 15), () {
      sub?.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    await _iap.restorePurchases();
    return completer.future;
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseStatusController.close();
  }
}
