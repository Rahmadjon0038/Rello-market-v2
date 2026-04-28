# Orders API (Savatcha → Buyurtma / Mening buyurtmalarim)

Bu hujjat user uchun **buyurtma yaratish** va **“Mening buyurtmalarim”** bo‘limini tushuntiradi.

## Base URL / Swagger

Base URL:

```txt
http://localhost:3000
```

Swagger UI:

```txt
http://localhost:3000/docs
```

OpenAPI JSON:

```txt
http://localhost:3000/openapi.json
```

## 1) Flow (mobile)

1) User savatchada mahsulotlarni tanlaydi (`cart_items.selected=true`).
2) User “Buyurtma berish” bosadi → `POST /orders`.
3) Backend:
   - faqat `selected=true` bo‘lgan item’lardan order yaratadi
   - client yuborgan narxga ishonmaydi (narx serverdan olinadi)
   - order paytidagi snapshot’ni saqlaydi (`productName`, `productImage`, `unitPrice`)
   - order yaratilgach `selected=true` cart item’larni cart’dan o‘chiradi (takroriy buyurtma ketmasin)
4) User “Mening buyurtmalarim”da `GET /orders` orqali history ko‘radi.
5) User order detail sahifasida `GET /orders/:id` orqali bitta order’ni ko‘radi.

## 2) Auth (User)

Hammasi **Bearer token** bilan:

```txt
Authorization: Bearer <accessToken>
```

Noto‘g‘ri token / token yo‘q bo‘lsa odatda:

```json
{ "error": "..." }
```

Status code: `401`.

## 3) Common response format

- Xatolik: har doim shu formatda:

```json
{ "error": "Xabar" }
```

- List endpoint’lar: odatda wrapper bilan:

```json
{ "data": [ ... ] }
```

- Detail endpoint’lar: ko‘pincha wrapper’siz **bitta object** qaytadi.

## 4) Order object (UI contract)

Backend order’ni shu ko‘rinishda qaytaradi (list ham, detail ham):

```json
{
  "id": "ORDER_ID",
  "userId": "USER_ID",
  "storeId": "STORE_ID",
  "status": "pending",
  "paymentMethod": "cod",
  "total": 250000,
  "currency": "UZS",
  "receiver": { "firstName": "Ali", "lastName": "Valiyev", "phone": "+998901234567" },
  "delivery": { "addressText": "Toshkent ...", "lat": 41.2995, "lng": 69.2401 },
  "items": [
    {
      "id": "ORDER_ITEM_ID",
      "productId": "PRODUCT_ID",
      "productName": "Mahsulot nomi (snapshot)",
      "productImage": "/uploads/products/....png",
      "unitPrice": 125000,
      "qty": 2,
      "lineTotal": 250000
    }
  ],
  "createdAt": "2026-04-24T00:00:00.000Z",
  "updatedAt": "2026-04-24T00:00:00.000Z"
}
```

UI uchun muhim:
- `items[]` ichida `productName`, `productImage`, `qty`, `unitPrice`, `lineTotal` bo‘lishi shart.
- `total` har doim server hisoblagan qiymat.

## 5) Create order (savatchadan)

Endpoint:

```http
POST /orders
```

Auth:

```txt
User (Bearer token)
```

Body:

```json
{
  "storeId": "STORE_ID",
  "receiver": {
    "firstName": "Ali",
    "lastName": "Valiyev",
    "phone": "+998901234567"
  },
  "delivery": {
    "addressText": "Toshkent sh., Chilonzor, ...",
    "lat": 41.2995,
    "lng": 69.2401
  },
  "paymentMethod": "cod"
}
```

Izoh:
- `storeId` majburiy va UUID bo‘lishi kerak.
- `paymentMethod`: `click | payme | cod`.
- `delivery.lat` va `delivery.lng` ixtiyoriy; lekin bittasi yuborilsa ikkalasi ham to‘g‘ri number bo‘lishi kerak.

Server nima qiladi:
- cart’dan faqat `selected=true` item’larni oladi (faqat shu `storeId` bo‘yicha)
- `unitPrice = products.price`
- `lineTotal = unitPrice * qty`, `total = sum(lineTotal)`
- `products.qty`ni kamaytiradi (ombor)
- `cart_items.selected=true` bo‘lganlarini o‘chiradi
- `orders` va `order_items`ga snapshot’larni yozadi

Success:
- `201 Created`
- response: **order detail object** (wrapper’siz)

Typical errors:
- `400 { "error": "Savatchada shu do'kon uchun tanlangan mahsulot yo'q" }`
- `400 { "error": "paymentMethod click, payme yoki cod bo'lishi kerak" }`
- `400 { "error": "Omborda yetarli mahsulot yo'q: <productName>" }`

## 6) Mening buyurtmalarim (history)

Endpoint:

```http
GET /orders
```

Auth:

```txt
User (Bearer token)
```

Success:

```json
{
  "data": [
    {
      "id": "ORDER_ID",
      "status": "pending",
      "paymentMethod": "cod",
      "total": 250000,
      "currency": "UZS",
      "delivery": { "addressText": "Toshkent ...", "lat": 41.2995, "lng": 69.2401 },
      "items": [
        {
          "productName": "Mahsulot nomi",
          "productImage": "/uploads/products/....png",
          "qty": 2,
          "unitPrice": 125000,
          "lineTotal": 250000
        }
      ],
      "createdAt": "2026-04-24T00:00:00.000Z",
      "updatedAt": "2026-04-24T00:00:00.000Z"
    }
  ]
}
```

Izoh:
- history `createdAt DESC` bo‘yicha qaytadi (eng oxirgisi birinchi).

## 7) Order detail

Endpoint:

```http
GET /orders/:id
```

Auth:

```txt
User (Bearer token)
```

Success:
- response: **order detail object** (wrapper’siz)

Errors:
- `400 { "error": "Order id UUID formatida bo'lishi kerak" }`
- `404 { "error": "Buyurtma topilmadi" }`

## 8) Statuslar va seller tomoni

User statuslarni `GET /orders` / `GET /orders/:id` orqali ko‘radi.

Statuslar:

```txt
pending | delivering | rejected | delivered
```

Seller order statusni o‘zgartiradi (seller’ga `role=seller` kerak).

Status transitions:

```txt
pending    -> delivering (accept)
pending    -> rejected   (reject)
delivering -> delivered  (delivered)
```

Seller endpoints (do‘kon egasi o‘z do‘koni bo‘yicha):

```http
GET   /me/stores/:id/orders?status=pending|delivering|rejected|delivered
GET   /me/stores/:id/orders/:orderId
PATCH /me/stores/:id/orders/:orderId/accept
PATCH /me/stores/:id/orders/:orderId/reject
PATCH /me/stores/:id/orders/:orderId/delivered
```

