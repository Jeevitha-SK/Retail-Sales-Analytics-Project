-- 1. Create Tables Based on ERD 
-- Use CREATE TABLE statements to replicate the exact structure of the  ER diagram (with constraints). 

CREATE DATABASE retail_sales;
USE retail_sales;

--  Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    street VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10)
);

--  Stores Table
CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    street VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10)
);
--  Staffs Table
CREATE TABLE staffs (
    staff_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    active TINYINT,
    store_id INT,
    manager_id INT NULL,   -- MUST be NULLABLE

    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

--  Categories Table
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100)
);


--  Brands Table
CREATE TABLE brands (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(100)
);

--  Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    brand_id INT,
    category_id INT,
    model_year INT,          -- year column
    list_price DECIMAL(10,2),
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);
--  Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_status INT,
    status_order VARCHAR(20),
    order_date DATE,
    required_date DATE,
    shipped_date DATE,
    store_id INT,
    staff_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (staff_id) REFERENCES staffs(staff_id)
);
--  Order_Items Table
CREATE TABLE order_items (
    order_id INT,
    item_id INT,
    product_id INT,
    product_name VARCHAR(100),       -- extra column
    category_id INT,                 -- extra column
    category_name VARCHAR(100),   -- extra column
    quantity INT,
    list_price DECIMAL(10,2),
    discount DECIMAL(4,2),
    total_price DECIMAL(10,2),      -- extra column
    PRIMARY KEY (order_id, item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);
--  Stocks Table
CREATE TABLE stocks (
    store_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (store_id, product_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM brands;
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM stores;
SELECT COUNT(*) FROM staffs;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT * FROM order_items;
SELECT COUNT(*) FROM stocks;
SELECT * FROM order_items;

-- 3. Inner Join for Order Details 
-- Join orders, order_items, and products to display detailed line items.
 
SELECT 
    o.order_id,
    o.order_date,
    o.status_order,
    oi.item_id,
    p.product_name,
    oi.quantity,
    oi.list_price,
    oi.discount,
    oi.total_price
FROM orders o
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
INNER JOIN products p
    ON oi.product_id = p.product_id;
    
 -- 4. Total Sales by Store 
-- Write a query to group sales (total_price) by each store_id 
  
 SELECT 
    o.store_id,
    SUM(oi.total_price) AS total_sales
FROM orders o
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.store_id;

 -- 5.Top 5 Selling Products 
-- Use ORDER BY and LIMIT to get the top 5 most sold products by quantity. 

SELECT 
    product_name,
    SUM(quantity) AS total_quantity_sold
FROM order_items
GROUP BY product_name
ORDER BY total_quantity_sold DESC
LIMIT 5;


-- 6.Customer Purchase Summary 
-- For each customer, return total orders placed, total items purchased, and total revenue. 

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS total_items_purchased,
    SUM(oi.total_price) AS total_revenue
FROM customers c
INNER JOIN orders o
    ON c.customer_id = o.customer_id
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- 7. Segment Customers by Total Spend 
-- Write a query to classify customers into spending brackets (e.g., low,  medium, high).

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(oi.total_price) AS total_spent,
    CASE
        WHEN SUM(oi.total_price) < 5000 THEN 'Low'
        WHEN SUM(oi.total_price) BETWEEN 5000 AND 13000 THEN 'Medium'
        ELSE 'High'
    END AS spending_segment
FROM customers c
INNER JOIN orders o
    ON c.customer_id = o.customer_id
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name;

--  8.Staff Performance Analysis 
-- Analyze total revenue generated by each staff member based on their  handled orders.

SELECT 
    s.staff_id,
    CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
    SUM(oi.total_price) AS total_revenue_generated
FROM staffs s
INNER JOIN orders o
    ON s.staff_id = o.staff_id
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY total_revenue_generated DESC;

--  9. Stock Alert Query 
-- Write a query to list products where stock quantity < 10 in any store.

SELECT 
    s.store_id,
    p.product_id,
    p.product_name,
    s.quantity
FROM stocks s
JOIN products p
    ON s.product_id = p.product_id
WHERE s.quantity < 10;

-- 10.Create Final Segmentation Table 
-- Create a table customer_segments that will be populated from Python  ML results later.

CREATE TABLE customer_segments (
    customer_id INT PRIMARY KEY,
    total_spend DECIMAL(12,2),
    segment VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


select * from orders;
SELECT status_order, COUNT(*) 
FROM orders 
GROUP BY status_order;

select * from orders;



   


