# โครงสร้างโปรเจค POS App (แยกไฟล์แล้ว)

## โครงสร้างโฟลเดอร์

```
lib/
├── main.dart                      # ไฟล์หลัก - เริ่มต้นแอป
├── models/
│   └── product.dart               # Model สำหรับ Product และ CartItem
├── services/
│   └── api_service.dart           # บริการเรียก API (GraphQL และ PhaJay Payment)
├── state/
│   └── cart_state.dart            # จัดการ State ของตะกร้าสินค้า
└── pages/
    ├── product_list_page.dart     # หน้ารายการสินค้า (หน้าแรก)
    ├── product_detail_page.dart   # หน้ารายละเอียดสินค้า
    ├── cart_page.dart              # หน้าตะกร้าสินค้า
    ├── customer_info_page.dart    # หน้ากรอกข้อมูลลูกค้า
    └── payment_page.dart           # หน้าชำระเงิน (PhaJay Payment Gateway)
```

## คำอธิบายแต่ละไฟล์

### 1. `main.dart`
- ไฟล์เริ่มต้นแอปพลิเคชัน
- กำหนดธีม และ Material App
- เรียก `ProductListPage` เป็นหน้าแรก

### 2. `models/product.dart`
**ประกอบด้วย:**
- `Product` class - โมเดลข้อมูลสินค้า
  - id, name, price, category
  - imageUrl, description, stock
  - isUsingSalePage (สถานะสินค้าในสต็อก)
- `CartItem` class - ข้อมูลสินค้าในตะกร้า
  - product, qty, lineTotal

### 3. `services/api_service.dart`
**API Services:**
- `fetchProducts()` - ดึงรายการสินค้าจาก GraphQL API
  - Endpoint: https://api.bbbb.com.la
  - Shop ID: 6864d7d2f32c2508f58eb7e8
- `createPaymentLink()` - สร้าง Payment Link ผ่าน PhaJay Gateway
  - Endpoint: https://payment-gateway.phajay.co/v1/api/link/payment-link
  - รองรับ BCEL, JDB, LDB, IB

### 4. `state/cart_state.dart`
**Cart Management:**
- `addToCart()` - เพิ่มสินค้าในตะกร้า
- `removeFromCart()` - ลบสินค้าจากตะกร้า
- `increaseQty()` / `decreaseQty()` - เพิ่ม/ลดจำนวน
- `clear()` - ล้างตะกร้า
- `total` - คำนวณราคารวม
- บันทึกลง SharedPreferences อัตโนมัติ

### 5. `pages/product_list_page.dart`
**หน้ารายการสินค้า:**
- แสดงสินค้าในรูปแบบ Grid (2 คอลัมน์)
- ฟีเจอร์:
  - ค้นหาสินค้า
  - กรองตาม Stock Status (All/In Stock/Out of Stock)
  - กรองตามหมวดหมู่
  - แสดงจำนวนในตะกร้า
  - ปุ่มเพิ่มสินค้า (disabled ถ้าสินค้าหมด)

### 6. `pages/product_detail_page.dart`
**หน้ารายละเอียดสินค้า:**
- แสดงรูปภาพสินค้าขนาดใหญ่
- ชื่อ, ราคา, คำอธิบาย
- เลือกจำนวนสินค้า
- เพิ่มลงตะกร้าพร้อมจำนวนที่เลือก

### 7. `pages/cart_page.dart`
**หน้าตะกร้าสินค้า:**
- แสดงรายการสินค้าในตะกร้า
- เพิ่ม/ลดจำนวนแต่ละรายการ
- แสดงราคารวม
- ปุ่มไปหน้ากรอกข้อมูลลูกค้า

### 8. `pages/customer_info_page.dart`
**หน้ากรอกข้อมูลลูกค้า:**
- ฟอร์มกรอกข้อมูล:
  - ชื่อ-นามสกุล
  - เบอร์โทร
  - แขวง, เมือง, บ้าน
  - ประเภทสมาชิก (ลาคะสูด/Affiliate)
- Validation ข้อมูล
- ไปหน้าชำระเงิน

### 9. `pages/payment_page.dart`
**หน้าชำระเงิน:**
- แสดง Order Summary
- เลือกวิธีการชำระเงิน
- แสดงราคารวมทั้งหมด
- **PhaJay Payment Integration:**
  - สร้าง Payment Link อัตโนมัติ
  - แสดงธนาคารที่รองรับ (BCEL, JDB, LDB, IB)
  - คัดลอก Payment Link ได้
  - ล้างตะกร้าหลังสร้าง Payment Link

## การติดตั้งและใช้งาน

### 1. ติดตั้ง Dependencies
```bash
flutter pub get
```

### 2. ตั้งค่า Payment API Key
แก้ไขไฟล์ `lib/pages/payment_page.dart`:
```dart
static const String PAYMENT_API_KEY = 'YOUR_PHAJAY_SECRET_KEY_HERE';
```

### 3. รันแอป
```bash
flutter run
```

## Features

### ✅ Stock Management
- กรองสินค้าตามสถานะสต็อก (In Stock / Out of Stock)
- ปุ่ม "ໝົດ" สำหรับสินค้าหมด
- ป้องกันการเพิ่มสินค้าที่หมดสต็อก

### ✅ Payment Gateway (PhaJay)
- สร้าง Payment Link อัตโนมัติ
- รองรับ 4 ธนาคาร: BCEL, JDB, LDB, IB
- Order Number ไม่ซ้ำ (timestamp-based)
- บันทึก Pending Orders

### ✅ Cart Management
- บันทึก Cart ลง Local Storage
- เพิ่ม/ลด/ลบสินค้า
- คำนวณราคารวมอัตโนมัติ

## API Endpoints

### 1. Product API (GraphQL)
```
POST https://api.bbbb.com.la
Query: StocksV2
Shop ID: 6864d7d2f32c2508f58eb7e8
```

### 2. Payment Gateway (PhaJay)
```
POST https://payment-gateway.phajay.co/v1/api/link/payment-link
Authorization: Basic {base64(SECRET_KEY)}
Body: {
  "orderNo": "ORDER...",
  "amount": 1000,
  "description": "Purchase: ...",
  "tag1": "4B-SHOP",
  "tag2": "POS-APP",
  "tag3": "timestamp"
}
Response: {
  "message": "SUCCESSFULLY",
  "redirectURL": "https://...",
  "orderNo": "ORDER..."
}
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.6.0                    # HTTP requests
  shared_preferences: ^2.5.3      # Local storage
  cupertino_icons: ^1.0.8
```

## หมายเหตุ

- ✅ แยกไฟล์เรียบร้อย - โค้ดอ่านง่ายขึ้น
- ✅ แต่ละไฟล์มีหน้าที่ชัดเจน
- ✅ ง่ายต่อการแก้ไขและดูแลรักษา
- ⚠️ ต้องใส่ Payment API Key ของจริงก่อนใช้งาน Payment Gateway
- ⚠️ รูปภาพ S3 ยังคง Error 403 (ต้องแก้ที่ Backend)

## การพัฒนาต่อ

หากต้องการแก้ไขหรือเพิ่มฟีเจอร์:

1. **เพิ่ม Model** → แก้ไขใน `models/`
2. **เพิ่ม API** → แก้ไขใน `services/`
3. **แก้ Cart Logic** → แก้ไขใน `state/`
4. **แก้ UI หน้าใดหน้าหนึ่ง** → แก้ไขในไฟล์ `pages/` ที่เกี่ยวข้อง

---

✨ **โครงสร้างใหม่นี้ทำให้โค้ดจัดการง่าย แก้ไขสะดวก และเข้าใจง่ายขึ้นมาก!**
