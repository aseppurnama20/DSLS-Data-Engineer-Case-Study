USE Northwind
GO

---Jumlah customer tiap bulan pada tahun 1997---
SELECT DATEPART(MONTH, OrderDate) AS 'Month', count(customerID) 'Number of Customer'
FROM Orders
WHERE OrderDate >= '1997-01-01' AND OrderDate <= '1997-12-31'
GROUP BY DATEPART(MONTH, OrderDate)

---Employee who are sales representative---
SELECT CONCAT(FirstName, ' ', LastName) AS 'Employee Name', Title AS 'Title'
FROM Employees
WHERE Title = 'Sales Representative'

---Top 5 Ordered of Product Quantity in 1997---
SELECT TOP 5(p.ProductName) AS 'Product Name', d.Quantity AS 'Qunatity'
FROM Products p JOIN [Order Details] d
ON (p.ProductID = d.ProductID)
JOIN Orders o ON (d.OrderID = o.OrderID)
WHERE OrderDate >= '1997-01-01' AND OrderDate <= '1997-12-31'
ORDER BY d.Quantity DESC

---Company Name which order Chai in 1997---
SELECT c.CompanyName, p.ProductName, o.OrderDate
FROM Customers c 
JOIN Orders o
ON (c.CustomerID = o.CustomerID)
JOIN [Order Details] d
ON (o.OrderID = d.OrderID)
JOIN Products p
ON (d.ProductID = p.ProductID)
WHERE p.ProductName = 'Chai' AND o.OrderDate >= '1997-01-01' AND o.OrderDate <= '1997-12-31'

---OrderID with selected total price---
SELECT
COUNT(CASE WHEN (Quantity * UnitPrice) <= 100 THEN OrderID ELSE NULL END) AS 'Sales <=100',
COUNT(CASE WHEN (Quantity * UnitPrice) <100 AND (Quantity * UnitPrice) <=250 THEN OrderID ELSE NULL END) AS '100<Sales<=250',
COUNT(CASE WHEN (Quantity * UnitPrice) <250 AND (Quantity * UnitPrice) <=050 THEN OrderID ELSE NULL END) AS '250<Sales<=500',
COUNT(CASE WHEN (Quantity * UnitPrice) > 500 THEN OrderID ELSE NULL END) AS 'Sales >500'
FROM [Order Details]

---Company Name which order >500 1997--
SELECT c.CompanyName AS 'Company Name', (d.UnitPrice * (1- d.Discount)* d.Quantity) AS 'Total Sales', o.OrderDate AS 'Order Date'
FROM Orders o JOIN [Order Details] d
ON (o.OrderID = d.OrderID) JOIN Customers c
ON (o.CustomerID = c.CustomerID)
WHERE (d.UnitPrice * d.Quantity) > 500 AND o.OrderDate >= '1997-01-01' AND o.OrderDate <= '1997-12-31'

---Top 5 Product with highest sales in 1997---
SELECT TOP 5
 p.ProductName AS 'Product Name',
 (d.UnitPrice *(1-d.Discount)* d.Quantity) AS 'Total Sales',
 o.OrderDate AS 'Order Date'
FROM Products p JOIN [Order Details] d
ON (p.ProductID = d.ProductID) JOIN Orders o
ON (d.OrderID = o.OrderID)
WHERE o.OrderDate >= '1997-01-01' AND o.OrderDate <= '1997-12-31'
ORDER BY 'Total Sales' DESC

---View for Order Detail with total price after discount---
ALTER VIEW view_orderdetails AS 
SELECT OrderID, ProductID, UnitPrice, Quantity, Discount, (UnitPrice * Quantity - (UnitPrice * Quantity * Discount)) AS RealPrice
FROM [Order Details]

SELECT *
FROM view_orderdetails

SELECT *
FROM Customers

---Create Procedure Invoice---
CREATE PROCEDURE ProcedureInvoice
	@CustomerID nvarchar(10)
AS
	SELECT
		c.CustomerID,
		c.ContactName AS CustomerName,
		o.OrderID,
		o.OrderDate,
		o.RequiredDate,
		o.ShippedDate
	FROM Customers c LEFT JOIN Orders o
	ON (c.CustomerID = o.CustomerID)
	WHERE c.CustomerID = @CustomerID
GO

EXECUTE ProcedureInvoice @CustomerID = 'ANATR';  
GO  