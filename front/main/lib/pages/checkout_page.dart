import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'order_history_page.dart';

/// 주문/결제 페이지
/// 배송지 정보, 결제 수단 입력 및 최종 주문
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  // 배송지 정보
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // 결제 정보
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvcController = TextEditingController();
  final _cardHolderController = TextEditingController();

  String _selectedPaymentMethod = 'card'; // card, bank, mobile
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _postalCodeController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final productProvider = context.watch<ProductProvider>();
    final total = cartProvider.calculateTotal(productProvider);
    final deliveryFee = 3000;
    final finalTotal = total + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('주문/결제'),
        backgroundColor: const Color.fromARGB(255, 0, 108, 82),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 주문 상품 정보
            _buildSectionTitle('주문 상품'),
            _buildOrderSummary(cartProvider, productProvider),
            const SizedBox(height: 24),

            // 배송지 정보
            _buildSectionTitle('배송지 정보'),
            _buildDeliverySection(),
            const SizedBox(height: 24),

            // 결제 수단
            _buildSectionTitle('결제 수단'),
            _buildPaymentMethodSection(),
            const SizedBox(height: 24),

            // 결제 금액
            _buildSectionTitle('결제 금액'),
            _buildPriceBreakdown(total, deliveryFee, finalTotal),
            const SizedBox(height: 24),

            // 약관 동의
            _buildTermsSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, finalTotal, cartProvider, productProvider),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 56, 41),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider, ProductProvider productProvider) {
    final items = cartProvider.items.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.map((item) {
              final product = productProvider.findById(item.productId);
              if (product == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${product.name} x ${item.quantity}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      _formatPrice(product.price * item.quantity),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '받는 사람',
                hintText: '이름을 입력하세요',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '받는 사람 이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '연락처',
                hintText: '010-1234-5678',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '연락처를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(
                      labelText: '우편번호',
                      hintText: '12345',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '우편번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // 우편번호 검색 기능 (추후 구현)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('우편번호 검색 기능은 추후 추가됩니다')),
                    );
                  },
                  child: const Text('검색'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '주소',
                hintText: '기본 주소를 입력하세요',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '주소를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailAddressController,
              decoration: const InputDecoration(
                labelText: '상세 주소',
                hintText: '동/호수 등 상세 주소를 입력하세요',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '상세 주소를 입력해주세요';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 결제 수단 선택
            RadioListTile<String>(
              title: const Text('신용/체크카드'),
              value: 'card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('계좌이체'),
              value: 'bank',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('휴대폰 결제'),
              value: 'mobile',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),

            // 카드 결제 정보 입력
            if (_selectedPaymentMethod == 'card') ...[
              const Divider(height: 32),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: '카드 번호',
                  hintText: '0000-0000-0000-0000',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
                validator: (value) {
                  if (_selectedPaymentMethod == 'card') {
                    if (value == null || value.replaceAll('-', '').length != 16) {
                      return '유효한 카드 번호를 입력해주세요';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cardExpiryController,
                      decoration: const InputDecoration(
                        labelText: '유효기간',
                        hintText: 'MM/YY',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateFormatter(),
                      ],
                      validator: (value) {
                        if (_selectedPaymentMethod == 'card') {
                          if (value == null || value.replaceAll('/', '').length != 4) {
                            return 'MM/YY 형식으로 입력';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cardCvcController,
                      decoration: const InputDecoration(
                        labelText: 'CVC',
                        hintText: '123',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      obscureText: true,
                      validator: (value) {
                        if (_selectedPaymentMethod == 'card') {
                          if (value == null || value.length != 3) {
                            return '3자리 입력';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  labelText: '카드 소유자명',
                  hintText: '카드에 기재된 이름',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (_selectedPaymentMethod == 'card') {
                    if (value == null || value.trim().isEmpty) {
                      return '카드 소유자명을 입력해주세요';
                    }
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(int total, int deliveryFee, int finalTotal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('상품 금액', total),
            const SizedBox(height: 8),
            _buildPriceRow('배송비', deliveryFee),
            const Divider(height: 24),
            _buildPriceRow(
              '총 결제 금액',
              finalTotal,
              isBold: true,
              color: const Color.fromARGB(255, 0, 108, 82),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int price, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          _formatPrice(price),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Card(
      child: CheckboxListTile(
        title: const Text('주문 내용을 확인했으며, 결제에 동의합니다.'),
        subtitle: const Text(
          '개인정보 수집·이용 및 제3자 제공 동의 포함',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        value: _agreeToTerms,
        onChanged: (value) {
          setState(() {
            _agreeToTerms = value ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    int finalTotal,
    CartProvider cartProvider,
    ProductProvider productProvider,
  ) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최종 결제 금액',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatPrice(finalTotal),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 108, 82),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _agreeToTerms ? () => _processPayment(context, cartProvider, productProvider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 108, 82),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '결제하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    CartProvider cartProvider,
    ProductProvider productProvider,
  ) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력 정보를 확인해주세요')),
      );
      return;
    }

    // 결제 처리 로딩
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Color.fromARGB(255, 0, 108, 82),
                ),
                SizedBox(height: 16),
                Text('결제 처리 중...'),
              ],
            ),
          ),
        ),
      ),
    );

    // 결제 처리 시뮬레이션 (2초 대기)
    await Future.delayed(const Duration(seconds: 2));

    // 주문 완료 처리
    await cartProvider.checkout(productProvider);

    if (context.mounted) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      Navigator.of(context).pop(); // 결제 페이지 닫기

      // 성공 다이얼로그
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('결제 완료'),
            ],
          ),
          content: const Text('주문이 완료되었습니다.\n구매 내역에서 확인하실 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                );
              },
              child: const Text('구매내역 보기'),
            ),
          ],
        ),
      );
    }
  }

  String _formatPrice(int value) {
    final formatted = value
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted원';
  }
}

// 카드 번호 포매터 (0000-0000-0000-0000)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// 유효기간 포매터 (MM/YY)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
