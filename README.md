# 🛒 E-Commerce Retail Analytics

> End-to-end analytical project covering SQL querying, Python EDA, and customer segmentation — using a realistic synthetic retail dataset.

---

## 📌 Project Overview

This project simulates the kind of analysis a **Data Analyst** would perform on an e-commerce platform's transactional data. It answers real business questions using SQL and Python, and is structured to mirror professional workflows.

**Business Questions Answered:**
- How is revenue trending month-over-month, and which categories drive growth?
- Which customer segments generate the most lifetime value?
- How do customer cohorts behave over time (retention & revenue)?
- Which products are underperforming despite high order volume?
- What does an RFM segmentation reveal about the customer base?

---

## 🗂️ Repository Structure

```
ecommerce-analysis/
│
├── README.md                     ← You are here
├── requirements.txt              ← Python dependencies
│
├── data/
│   └── README.md                 ← Dataset description & schema
│
├── sql/
│   ├── 01_schema.sql             ← Table definitions & sample data notes
│   ├── 02_revenue_analysis.sql   ← MoM revenue, category breakdown
│   ├── 03_cohort_analysis.sql    ← Monthly cohort retention
│   ├── 04_rfm_segmentation.sql   ← RFM scoring & customer tiers
│   └── 05_product_performance.sql← Return rates, margin proxies
│
└── notebooks/
    └── ecommerce_analysis.ipynb  ← Full Python EDA + visualisations
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **PostgreSQL / SQLite** | SQL analysis (queries are ANSI-compatible) |
| **Python 3.10+** | EDA, visualisation, segmentation |
| **Pandas** | Data wrangling |
| **Matplotlib / Seaborn** | Charts |
| **Jupyter Notebook** | Reproducible analysis |

---

## 🚀 Getting Started

### 1. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/ecommerce-analysis.git
cd ecommerce-analysis
```

### 2. Install Python dependencies
```bash
pip install -r requirements.txt
```

### 3. Run the notebook
```bash
jupyter notebook notebooks/ecommerce_analysis.ipynb
```

### 4. Run SQL scripts
The SQL scripts are written in standard ANSI SQL. Run them in order (01 → 05) in any SQL client (DBeaver, pgAdmin, DB Browser for SQLite, or Mode/BigQuery).

---

## 📊 Key Findings (Preview)

| Insight | Finding |
|--------|---------|
| 📈 Revenue trend | 23% MoM growth in Q4 driven by Electronics |
| 🔁 Cohort retention | Month-1 retention averages ~38%; drops sharply after Month-3 |
| 🎯 RFM top tier | "Champions" = 12% of customers, 41% of revenue |
| ⚠️ Risk segment | "At-Risk" customers = 19% of base, declining spend |
| 📦 Product issue | High-volume items in Clothing have 3× avg return rate |

---

## 📁 Dataset

Synthetic dataset generated in Python — **no real customer data used**. Designed to reflect realistic e-commerce patterns including seasonality, cohort effects, and product return behaviour.

See [`data/README.md`](data/README.md) for full schema.

---

## 👤 Author

**Ranim** — aspiring Data Analyst transitioning from Finance & Administration.

🔗 [LinkedIn](#) · 🐙 [GitHub](#) · 📧 your@email.com

---

## 📄 License

MIT — free to fork, adapt, and use as a portfolio template.
