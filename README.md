# VERA Ecommerce Demo

Premium React/Vite ecommerce storefront built as a First Draft Studio client demo.

## Included
- Responsive Home, Shop, Product Details, Cart, Checkout and Order Confirmation flows
- Product variants: color + size
- Inventory-aware quantity controls
- Persistent cart via localStorage
- Calculated subtotal, shipping, tax and total
- Demo checkout with no real payment processing
- Clean separation of product data, cart state, pages and UI components
- No Shopify dependency

## Run
```bash
npm install
npm run dev
```

## Production build
```bash
npm run build
npm run preview
```

## Backend-ready structure
The current `src/data` layer is intentionally local demo data. Replace that source with API calls later without changing the storefront contract. Cart operations are isolated in `CartProvider`, making it straightforward to replace localStorage with server-side carts/auth/orders.

## Demo note
Images are served from Unsplash URLs for presentation purposes. Replace them with client-owned CDN/storage assets for production.
