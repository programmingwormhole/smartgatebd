import 'package:get/get.dart';
import '../services/payment_gateway_service.dart';

class PaymentGatewayController extends GetxController {
  final PaymentGatewayService _service = PaymentGatewayService();

  final RxList<dynamic> gateways = <dynamic>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPaymentGateways();
  }

  Future<void> fetchPaymentGateways() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _service.getPaymentGateways();
      gateways.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      gateways.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createPaymentGateway(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final result = await _service.createPaymentGateway(data);
      await fetchPaymentGateways();
      Get.back();
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updatePaymentGateway(
    int gatewayId,
    Map<String, dynamic> data,
  ) async {
    try {
      isLoading.value = true;
      await _service.updatePaymentGateway(gatewayId, data);
      await fetchPaymentGateways();
      Get.back(); 
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletePaymentGateway(int gatewayId) async {
    try {
      isLoading.value = true;
      await _service.deletePaymentGateway(gatewayId);
      await fetchPaymentGateways();
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
