# Dataset Description

## Overview

This project uses a **synthetic e-commerce dataset** generated with Python's `numpy` and `faker` libraries. All data is fictional and designed to mirror realistic retail patterns.

## Schema

### `orders`
| Column | Type | Description |
|--------|------|-------------|
| `order_id` | INTEGER | Unique order identifier |
| `customer_id` | INTEGER | Customer identifier (FK → customers) |
| `order_date` | DATE | Date the order was placed |
| `order_status` | TEXT | `completed`, `returned`, `cancelled` |
| `total_amount` | DECIMAL | Order total in AUD |

### `customers`
| Column | Type | Description |
|--------|------|-------------|
| `customer_id` | INTEGER | Unique customer identifier |
| `signup_date` | DATE | Date of first registration |
| `region` | TEXT | `NSW`, `VIC`, `QLD`, `WA`, `SA`, `Other` |
| `channel` | TEXT | Acquisition channel: `organic`, `paid`, `referral`, `email` |

### `order_items`
| Column | Type | Description |
|--------|------|-------------|
| `item_id` | INTEGER | Unique line-item identifier |
| `order_id` | INTEGER | FK → orders |
| `product_id` | INTEGER | FK → products |
| `quantity` | INTEGER | Units ordered |
| `unit_price` | DECIMAL | Price per unit at time of purchase |

### `products`
| Column | Type | Description |
|--------|------|-------------|
| `product_id` | INTEGER | Unique product identifier |
| `product_name` | TEXT | Product display name |
| `category` | TEXT | `Electronics`, `Clothing`, `Home & Garden`, `Beauty`, `Sports` |
| `cost_price` | DECIMAL | Internal cost (for margin calculation) |

## Generation Notes

- **Date range:** Jan 2022 – Dec 2023 (24 months)
- **Customers:** ~2,000 unique customers
- **Orders:** ~8,500 orders
- **Seasonality:** Q4 uplift (Oct–Dec) built into order volume
- **Return rate:** ~8% overall; elevated (~22%) for Clothing category
