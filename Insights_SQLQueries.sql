/* The top customer cities. */
	SELECT Count(l.Customer_ID) as CountCity, l.City
	FROM Location l
	GROUP BY l.City
	ORDER BY CountCity DESC


/* Best selling products in every state. */
	WITH Num_Product_Every_State
	AS (
		SELECT I.Product_ID, L.[State], COUNT (I.Product_ID) AS Number_Of_Products
		FROM [dbo].[Product] AS P
		INNER JOIN [dbo].[Item] AS I
		ON P.ID = I.Product_ID
		INNER JOIN [dbo].[Order] AS O
		ON O.ID = I.Order_ID
		INNER JOIN [dbo].[Location] AS L
		ON L.ID = O.Location_ID
		GROUP BY I.Product_ID, L.[State]
	)

	SELECT Product_ID AS [Best_Product], [State], Number_Of_Products 
	FROM (
		SELECT * , ROW_NUMBER() OVER (PARTITION BY [State] ORDER BY Number_Of_Products DESC) AS [rank_num]
		FROM Num_Product_Every_State
	) AS A
	WHERE [rank_num] = 1
	ORDER BY Number_Of_Products DESC



/*
	* People who have purchased over 5,000 in 2018?
*/
	Go;
	CREATE FUNCTION Purchased_Over (@money INT, @year NVARCHAR(4))
	RETURNS TABLE AS
	RETURN 
		SELECT O.Customer_ID, SUM(O.Pay_Amount) AS [Purchased]
		FROM [dbo].[Order] AS O
		WHERE O.Customer_ID IS NOT NULL AND YEAR(O.Act_Date) = @year
		GROUP BY O.Customer_ID
		HAVING SUM(O.Pay_Amount) > @money
	
	Go;
	SELECT * FROM Purchased_Over(5000, '2018')

/*
	* What type of payment is used? And how many use each type?
*/

	GO;
	CREATE PROC Payment_Type
	AS (
		SELECT O.Pay_Type, Count(Pay_Type) AS [Number_Used]
		FROM [dbo].[Order] AS O
		GROUP BY O.Pay_Type
	)

	EXEC Payment_Type


/*
	* The number of orders in each status.
*/
	GO;
	CREATE VIEW Orders_in_Status
	AS (
		SELECT O.[Status], COUNT(O.[Status]) AS Number_of_Orders
		FROM [dbo].[Order] AS O
		GROUP BY O.[Status]
	)

	Go;
	SELECT * FROM Orders_in_Status


/*
	* Top 10 sellers in a given year in terms of number of products sold .
*/
	Go;
	CREATE PROC Top_sellers @year NVARCHAR(4)
	AS (
		SELECT ID, [Number_of_Products_Sold]
		FROM (
			SELECT *, ROW_NUMBER() OVER (ORDER BY [Number_of_Products_Sold] DESC) AS [rank_num]
			FROM (
				SELECT S.ID, Count(S.ID) AS [Number_of_Products_Sold]
				FROM [dbo].[Seller] AS S
				INNER JOIN [dbo].[Product] AS P
				ON S.ID = P.Seller_ID
				INNER JOIN [dbo].[Item] AS I
				ON P.ID = I.Product_ID
				INNER JOIN [dbo].[Order] AS O
				ON O.ID = I.Order_ID
				WHERE year(o.Act_Date) = @year
				GROUP BY S.ID) AS A) AS B
		WHERE [rank_num] <= 10
	)

	Go;
	EXEC Top_sellers '2018'


/*
	* Number of delivered orders every year.
*/
	Go;
	CREATE VIEW Orders_Year
	AS (
		SELECT YEAR(O.Act_Date) AS [Year], COUNT(Act_Date) AS [Number_of_Orders]
		FROM [dbo].[Order] AS O
		WHERE O.Status = 'delivered' AND Act_Date IS NOT NULL
		GROUP BY YEAR(O.Act_Date)
	)

	Go;
	SELECT * FROM Orders_Year



/*
	* Number of delivered orders in every state in 2018.
*/

	Go;
	CREATE FUNCTION Deliverd_Orders_State (@year NVARCHAR(4), @status NVARCHAR(20))
	RETURNS TABLE AS
	RETURN (
		SELECT L.State, COUNT(L.State) AS Number_OF_Orders
		FROM [dbo].[Order] AS O
		INNER JOIN [dbo].[Location] AS L
		ON L.ID = O.Location_ID
		WHERE O.Status = @status AND YEAR(O.Act_Date) = @year 
		GROUP BY L.State
	)

	Go;
	SELECT * 
	FROM Deliverd_Orders_State('2018', 'delivered')
	ORDER BY Number_OF_Orders DESC
	


/*
	* Number of orders that reviewed by rate from 1 to 5.
*/
	Go;
	CREATE VIEW Orders_Rate
	AS (
		SELECT R.Rate, COUNT(R.Rate) As [Number_of_Rates]
		FROM [dbo].[Review] AS R
		RIGHT OUTER JOIN [dbo].[Order] AS O
		ON O.ID = R.Order_ID
		WHERE R.Rate IS NOT NULL
		GROUP BY R.Rate
	)

	Go;
	SELECT * FROM Orders_Rate


/* Number of orders in every month in specific year. */
	Go;
	ALTER PROC Orders_in_Months @year NVARCHAR(4)
	AS 
		SELECT FORMAT(O.Act_Date,'MMMM') AS [Month], COUNT(O.ID) AS [Number_of_Orders]
		FROM [dbo].[Order] AS O
		WHERE O.[Status] = 'delivered' AND YEAR(O.Act_Date) = @year
		GROUP BY FORMAT(O.Act_Date,'MMMM')
		ORDER BY MONTH(FORMAT(O.Act_Date,'MMMM') + '1,1') 
	

	EXEC Orders_in_Months '2017'



/* best product every month in a gaivin year. */
	Go;
	CREATE FUNCTION Num_Product_Every_Month(@year NVARCHAR(4))
	RETURNS TABLE AS
	RETURN (
		SELECT Product_ID AS [Best_Product], [Month], Number_Of_Products 
		FROM (
			SELECT * , ROW_NUMBER() OVER (PARTITION BY [Month] ORDER BY Number_Of_Products DESC) AS [rank_num]
			FROM (
				SELECT I.Product_ID, FORMAT(O.Act_Date,'MMMM') AS [Month], COUNT (I.Product_ID) AS Number_Of_Products
				FROM [dbo].[Product] AS P
				INNER JOIN [dbo].[Item] AS I
				ON P.ID = I.Product_ID
				INNER JOIN [dbo].[Order] AS O
				ON O.ID = I.Order_ID
				INNER JOIN [dbo].[Location] AS L
				ON L.ID = O.Location_ID
				WHERE YEAR(O.Act_Date) = '2017'
				GROUP BY I.Product_ID, FORMAT(O.Act_Date,'MMMM')
			) AS B
		) AS A
		WHERE [rank_num] = 1
	)
	Go;

	SELECT * 
	FROM Num_Product_Every_Month('2017')
	ORDER BY MONTH([Month] + '1,1') 



/* The orders which quantity is one */
	Go;
	CREATE PROCEDURE Quantity
	AS (
		select [Order_ID]
		from [dbo].[Item]
		where [Quantity] = 1)

	EXEC Quantity


/* Comparison between 2017 and 2018 in each month. */	
	SELECT [Month], [2017],[2018]
	FROM (
		SELECT FORMAT(O.Act_Date,'MMMM') AS [Month], FORMAT(Act_Date,'yyyy') AS [Year], O.ID 
		FROM [dbo].[Order] AS O
		WHERE O.[Status] = 'delivered' AND YEAR(O.Act_Date) IN ('2017', '2018') 
		GROUP BY FORMAT(O.Act_Date,'yyyy'), FORMAT(O.Act_Date,'MMMM'), O.ID
	) AS T1 
	PIVOT (  
		COUNT(ID) 
		FOR  [Year]
		IN ([2017], [2018])  
	) AS T2  
	ORDER BY MONTH([Month] + '1,1') 
	

/* Number of Customers who did not make any purchases. */
	Go;
	CREATE VIEW Customers_not_purchases
	AS (
		SELECT Count(C.ID) AS [Number of Customers]
		FROM [dbo].[Customer] AS C
		WHERE C.ID  NOT IN (
			SELECT O.Customer_ID FROM [dbo].[Order] AS O)
	)
	GO;

	SELECT * FROM Customers_not_purchases



