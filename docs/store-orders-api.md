# Store Orders API (Seller)

Bu hujjat seller (do‘kon egasi) uchun buyurtmalarni ko‘rish va statusini boshqarish endpointlarini jamlaydi.

## Base URL

```txt
http://localhost:3000
```

## Auth

Hammasi **Bearer token** bilan:

```txt
Authorization: Bearer <accessToken>
```

Seller user’da `role=seller` bo‘lishi kerak.

## Statuslar

```txt
pending | delivering | rejected | delivered
```

Status transitions:

```txt
pending    -> delivering (accept)
pending    -> rejected   (reject)
delivering -> delivered  (delivered)
```

## Endpoints

Do‘kon egasi faqat o‘z do‘koni bo‘yicha buyurtmalarni boshqaradi.

```http
GET   /me/stores/:id/orders?status=pending|delivering|rejected|delivered
GET   /me/stores/:id/orders/:orderId
PATCH /me/stores/:id/orders/:orderId/accept
PATCH /me/stores/:id/orders/:orderId/reject
PATCH /me/stores/:id/orders/:orderId/delivered
```

