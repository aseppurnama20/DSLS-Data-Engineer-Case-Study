USE Northwind
GO

-----------------------------Product and Order Analysis---------------------------------
---Trend Pemesanan tiap bulan berdasarkan category produk---
SELECT
	CONCAT(YEAR(o.OrderDate), '-', RIGHT(CONCAT('00', MONTH(o.OrderDate)), 2)) AS Months,
	SUM(ISNULL(CASE WHEN p.CategoryID = 1 THEN d.Quantity ELSE NULL END,0)) AS Beverages,
	SUM(ISNULL(CASE WHEN p.CategoryID = 2 THEN d.Quantity ELSE NULL END,0)) AS Condiments,
	SUM(ISNULL(CASE WHEN p.CategoryID = 3 THEN d.Quantity ELSE NULL END,0)) AS Confections,
	SUM(ISNULL(CASE WHEN p.CategoryID = 4 THEN d.Quantity ELSE NULL END,0)) AS 'Dairy Product',
	SUM(ISNULL(CASE WHEN p.CategoryID = 5 THEN d.Quantity ELSE NULL END,0)) AS 'Crain/Cereals',
	SUM(ISNULL(CASE WHEN p.CategoryID = 6 THEN d.Quantity ELSE NULL END,0)) AS 'Meat/Poultry',
	SUM(ISNULL(CASE WHEN p.CategoryID = 7 THEN d.Quantity ELSE NULL END,0)) AS Produce,
	SUM(ISNULL(CASE WHEN p.CategoryID = 8 THEN d.Quantity ELSE NULL END,0)) AS Seafood,
	SUM(d.Quantity) AS Total_Quantity
--INTO dbo.TrendOrder
FROM Orders o JOIN [Order Details] d 
ON (o.OrderID = d.OrderID) JOIN Products p
ON (d.ProductID = p.ProductID)
GROUP BY CONCAT(YEAR(o.OrderDate), '-', RIGHT(CONCAT('00', MONTH(o.OrderDate)), 2))
ORDER BY Months


SELECT 
	CONCAT(YEAR(o.OrderDate), '-', RIGHT(CONCAT('00', MONTH(o.OrderDate)), 2)) AS Months,
	p.CategoryID, 
	SUM(d.Quantity) AS TotalQuantity
INTO Trend
FROM Orders o LEFT JOIN [Order Details] d
ON (o.OrderID = d.OrderID) LEFT JOIN Products p
ON (d.ProductID = p.ProductID)
GROUP BY CONCAT(YEAR(o.OrderDate), '-', RIGHT(CONCAT('00', MONTH(o.OrderDate)), 2)), p.CategoryID
ORDER BY CONCAT(YEAR(o.OrderDate), '-', RIGHT(CONCAT('00', MONTH(o.OrderDate)), 2))

SELECT *
FROM TrendOrder
ORDER BY Months

DROP TABLE TrendOrder

---Perbandingan Rata-rata Unitprice per category
SELECT
	p.CategoryID,
	c.CategoryName,
	AVG(d.UnitPrice) AS 'Average Unit Price'
INTO AVGCat
FROM [Order Details] d LEFT JOIN Products p
ON (d.ProductID = p.ProductID) LEFT JOIN Categories c
ON (p.CategoryID = c.CategoryID)
GROUP BY p.CategoryID, c.CategoryName
ORDER BY 'Average Unit Price' DESC

---urutan kategori Produk yang paling banyak di order
SELECT
	c.CategoryName AS 'Category Name',
	SUM(d.Quantity) AS 'Total Quantity',
	SUM(d.Quantity * (1-d.Discount) * d.UnitPrice) AS 'Total Sales'
--INTO SalesCategory
FROM [Order Details] d JOIN Products p
ON (d.ProductID = p.ProductID) JOIN Categories c
ON (p.CategoryID = c.CategoryID)
GROUP BY c.CategoryName
ORDER BY 'Total Quantity' DESC

---Top 5 Produk dari masing-masing kategori yang paling banyak diorder
SELECT TOP 5(p.ProductName), SUM(d.Quantity) AS TotalQuantity, AVG(d.UnitPrice)
FROM [Order Details] d JOIN Products p
ON (d.ProductID = p.ProductID) JOIN Categories c
ON (p.CategoryID = c.CategoryID)
WHERE c.CategoryName = 'Meat/Poultry'
GROUP BY p.ProductName
ORDER BY TotalQuantity DESC

-------------Shipper Analysis----------------------

SELECT
	s.ShipperID,
	s.CompanyName,
	COUNT(o.ShipVia) AS Amount,
	SUM(o.Freight) AS 'Freight Amount'
INTO ship
FROM Orders o LEFT JOIN Shippers s
ON (o.ShipVia = s.ShipperID)
GROUP BY s.ShipperID, s.CompanyName

SELECT 
	DISTINCT(ShipCountry),
	COUNT(ShipVia) AS 'Amount'
INTO shipcountry
FROM Orders
GROUP BY ShipCountry


-----------Customer Segmentation Using RFM Analysis---------------
/** STEP 1. FILTER THE DATASET **/
WITH dtset (CustomerID, OrderID, OrderDate, Sales) AS 
(
	SELECT 
		c.CustomerID,
		o.OrderID, o.OrderDate,
		SUM(d.Quantity * (1-d.Discount) * d.UnitPrice) AS Sales
	FROM Customers c RIGHT JOIN Orders o 
	ON (c.CustomerID = o.CustomerID) RIGHT JOIN [Order Details] d
	ON (o.OrderID = d.OrderID)
	GROUP BY c.CustomerID, o.OrderID, o.OrderDate
)

/** STEP 2. PUT TOGETHER IN THE RFM REPORT **/
---rfm_data AS (CustomerID, Recency, Frequency, Monetary, RFM)
    SELECT
	t1.CustomerID,
	DATEDIFF(day, (SELECT MAX(OrderDate) FROM dtset WHERE CustomerID = t1.CustomerID), (SELECT MAX(OrderDate) FROM dtset)) AS Recency,
	COUNT(t1.OrderID) AS Frequency,
	SUM(t1.Sales) AS Monetary,
NTILE(4) OVER (ORDER BY DATEDIFF(day, (SELECT MAX(OrderDate) FROM dtset WHERE CustomerID = t1.CustomerID), (SELECT MAX(OrderDate) FROM dtset)) DESC) AS R,
NTILE(4) OVER (ORDER BY COUNT(t1.OrderID) ASC) AS F,
NTILE(4) OVER (ORDER BY SUM(t1.Sales) ASC) AS M
--INTO rfm_data
FROM dtset t1
GROUP BY t1.CustomerID
ORDER BY 1, 3 DESC

DROP TABLE rfm_data

---Creating case statement for customer segmenatation---
WITH rfm_class AS (
SELECT *, CONCAT(R,F,M) AS RFM_Class
FROM rfm_data
)

SELECT CustomerID, R, F, M, RFM_Class,
 CASE
   WHEN RFM_Class LIKE '[1-2][1-4][1-4]' THEN 'Lost Customers'
   WHEN RFM_Class LIKE '[1-3][3-4][3-4]' THEN 'Slipping away, cannot lose' -- Big spenders who haven’t purchased lately) slipping away
   WHEN RFM_Class LIKE '[3-4][1,3]1' THEN 'New Customer' --Customers who have only made a couple purchases
   WHEN RFM_Class LIKE '[2-3]2[2-3]' THEN 'Potential Churners'
   WHEN RFM_Class LIKE '[3-4][2-3][1-3]' THEN 'Active Customers' --(Customers who buy often & recently, but at low price points)
   WHEN RFM_Class LIKE '4[3-4][3-4]' THEN 'Loyal Customers'
ELSE 'Other Category' 
END AS rfm_category
--INTO CustomerAnalysis
FROM rfm_class

DROP TABLE rfm

SELECT a.rfm_category AS 'Customer Category', COUNT(c.CustomerID) AS Amount
--INTO rfm
FROM Customers c LEFT JOIN CustomerAnalysis a
ON (c.CustomerID = a.CustomerID)
GROUP BY a.rfm_category