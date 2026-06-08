import 'package:dio/dio.dart';

import '../models/subscription_info.dart';
import 'api_client.dart';

class SubscriptionApi {
  const SubscriptionApi(this._apiClient);

  final ApiClient _apiClient;

  Future<SubscriptionInfo> getSubscription() async {
    final Response<dynamic> response = await _apiClient.dio.get(
      '/me/subscription',
    );

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      response.data as Map,
    );

    final dynamic raw = data['subscription'];
    if (raw == null) {
      throw StateError('Сервер не вернул данные подписки');
    }

    return SubscriptionInfo.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<String> createCheckout({required int months}) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/me/subscription/checkout',
      data: <String, dynamic>{'months': months},
    );

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      response.data as Map,
    );

    final String? paymentUrl = data['payment_url'] as String?;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      throw StateError('Сервер не вернул ссылку на оплату');
    }

    return paymentUrl;
  }
}
