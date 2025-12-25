// ============================================================================
// QUICK REFERENCE: Multi-Device Payment Fix
// ============================================================================

// 1. SessionService.dart - สร้าง ID ที่ไม่ซ้ำกันสำหรับแต่ละเครื่อง
// ============================================================================

SessionService.getSessionId()
  → ดึง/สร้าง UUID ที่ไม่ซ้ำกัน
  → เก็บไว้ใน SharedPreferences (ยังคงอยู่ตลอดเวลา)
  → ตัวอย่าง: "f47ac10b-58cc-4372-a567-0e02b2c3d479"

SessionService.verifySessionId(sessionId)
  → ตรวจสอบว่า sessionId ตรงกับเครื่องปัจจุบันหรือไม่
  → ใช้ที่ Backend เพื่อยืนยันว่า payment นี้เป็นของเครื่องไหน


// 2. Payment WebView Flow
// ============================================================================

payment_webview_page.dart:

  initState() {
    _sessionId = await SessionService.getSessionId()  // ← เรียก Session ID
    // ... setup WebView ...
  }

  _handlePaymentSuccess() {
    await ApiService.createOrderAndUpdateStock(
      transactionId: widget.orderNo,
      cartItems: cartItems,
      customerName: widget.customerName,
      customerPhone: widget.customerPhone,
      shopId: "6864d7d2f32c2508f58eb7e8",
      shopName: "Jop Jip",
      sessionId: _sessionId,  // ← ส่ง session ID ไปกับ order
    );
  }


// 3. API Service Updates
// ============================================================================

ApiService.createOrderAndUpdateStock():
  - เพิ่ม parameter: String? sessionId
  - ส่ง sessionId ไป _createOrderRecord()

ApiService._createOrderRecord():
  - เพิ่ม parameter: String? sessionId
  - บันทึก sessionId ลงในฟิลด์ 'sessionId' ของ orderGroup

GraphQL Mutation Data:
  {
    'orderGroup': {
      'shop': shopId,
      'transactionId': transactionId,
      'sessionId': sessionId,        // ← ใหม่
      'amount': cartItems.fold(...),
      'address': customerAddress,
      'totalPrice': cartItems.fold(...),
      'sumPriceBaht': 0.0,
      'sumPriceUsd': 0.0,
      'sumPrice': cartItems.fold(...),
      'customerName': customerName,
      'status': 'COMPLETED',
      'code': 'SP-${DateTime.now().millisecondsSinceEpoch}',
      'createdAt': DateTime.now().toIso8601String(),
    },
    'orders': [...]
  }


// 4. Backend Implementation (Optional but Recommended)
// ============================================================================

เมื่อ Payment Gateway ส่ง callback กลับมา:

1. ดึง sessionId จากข้อมูล callback
2. เปรียบเทียบ sessionId กับ transaction record ที่เก็บไว้
3. ถ้าตรงกัน → ประมวลผลการชำระเงิน
4. ถ้าไม่ตรง → ปฏิเสธ (ป้องกัน duplicate order)

Example:
  - Device A จ่ายเงิน → backend เก็บ sessionId: "abc-123"
  - Device B ได้รับ callback → ส่ง sessionId: "abc-123" (ตรงกัน)
    → แต่ backend ตรวจพบว่า sessionId นี้ถูกใช้แล้ว
    → ปฏิเสธการสร้าง order ซ้ำ


// 5. Dependencies
// ============================================================================

pubspec.yaml:
  uuid: ^4.0.0       // ← ใหม่ (สำหรับสร้าง UUID)
  shared_preferences: ^2.5.3  // (มีอยู่แล้ว)


// 6. Testing Scenario
// ============================================================================

Test Case: 2 Devices, 1 Payment

Setup:
  Device A: เปิด app → ไปหน้าชำระเงิน → Session ID = "abc-123"
  Device B: เปิด app → ไปหน้าชำระเงิน → Session ID = "def-456"

Payment:
  Device A: สแกน QR และจ่ายเงิน

Result:
  Payment Gateway: ส่ง callback success
  ↓
  Device A: ได้รับ callback → sessionId = "abc-123" ✓ → สร้าง Order
  Device B: ได้รับ callback → sessionId = "abc-123" ✗ → ไม่สร้าง Order

✅ Order สร้างได้เพียง 1 ครั้ง (เครื่องที่จ่ายจริง)


// 7. Debugging
// ============================================================================

ดูใน Console/Logs:

Payment Webview:
  🆕 Generated new session ID: f47ac10b-58cc-4372-a567-0e02b2c3d479
  ♻️ Using existing session ID: f47ac10b-58cc-4372-a567-0e02b2c3d479

Payment Success:
  ✅ Payment success detected on session: f47ac10b-58cc-4372-a567-0e02b2c3d479
  📤 Sending GraphQL request for order creation...

Error (if session mismatch):
  ❌ Session mismatch! Expected: abc-123, Got: def-456
  ❌ Error processing payment: ...


// 8. Files Modified/Created
// ============================================================================

CREATED:
  ✨ lib/services/session_service.dart

MODIFIED:
  📝 lib/pages/payment_webview_page.dart
  📝 lib/services/api_service.dart
  📝 pubspec.yaml

DOCUMENTATION:
  📋 MULTI_DEVICE_PAYMENT_FIX.md (Thai explanation)
  📋 MULTI_DEVICE_PAYMENT_IMPLEMENTATION.dart (this file)

============================================================================
