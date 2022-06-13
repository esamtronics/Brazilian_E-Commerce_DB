 /*
	* This queries that we used to fill our database by data from 'Brazilian E-Commerce Public Dataset by Olist' 
		'https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce?select=product_category_name_translation.csv'
	* This queries will doesn't work because we removed the dataset tables.
 */


	/* Fill Location table by data from Location dataset */
		Go;
		ALTER PROCEDURE Fill_Location_Data
		AS 
			INSERT INTO [dbo].[Location] ([ID],[Name],[Phone],[Country],[City],[State],[Area],[Lon],[Lat],[Customer_ID], [Postal_Code])
			SELECT NEWID(),null,null,null,[geolocation_city],[geolocation_state],null,geolocation_lng,geolocation_lat,null, geolocation_zip_code_prefix
			FROM [dataset].[location_dataset]

		EXEC Fill_Location_Data


	/* Fill Customer table by data from Customer dataset */
		Go;
		CREATE PROCEDURE Fill_Customer_Data
		AS 
			INSERT INTO [dbo].[Customer]([ID],[Name],[Email],[Password],[Phone],[City],[State],[Postal_Code])
			SELECT [customer_id],null,null,null,null,customer_city,customer_state,customer_zip_code_prefix
			FROM [dataset].[customers_dataset]

		EXEC Fill_Customer_Data;


	/* Fill review table by data from review dataset */
		Go;
		CREATE PROC Fill_Review_Data
		AS 
			INSERT INTO [dbo].[Review]([ID],[Date], [Rate], [Comment],[Customer_ID],[Order_ID])
			SELECT [review_id], [review_creation_date], [review_score], [review_comment_message], null, [order_id]
			FROM [dataset].[review_dataset]
			WHERE [order_id] in (SELECT ID FROM [dbo].[Order])

		Go;

		EXEC Fill_Review_Data;


	/* Fill category table by data from category dataset */
		Go;
		ALTER PROC Fill_Category_Data
		AS
			INSERT INTO [dbo].[Category]([ID], [Name],[Description],[Photo],[Super_Category_ID])
			SELECT NEWID(), column2, column1,null,null
			FROM [dataset].[category_dataset]
			WHERE column1 != 'product_category_name'
		Go

		EXEC Fill_Category_Data;


	/* Fill order table by data from order dataset */
		Go;
		CREATE PROCEDURE Fill_Order_Data
		AS
			INSERT INTO [dbo].[Order]([ID],[Status],[Est_Date],[Act_Date],[Pay_Date],[Pay_Amount],[Pay_Type],[Pay_Discount],[Customer_ID],[Location_ID])
			SELECT O.[order_id], O.[order_status],O.[order_estimated_delivery_date],O.[order_delivered_customer_date],O.[order_approved_at],P.[payment_value],P.[payment_type],null,o.[customer_id],null
			FROM [dataset].[order_dataset] AS O
			INNER JOIN [dataset].[payment_dataset] AS P
			ON O.order_id = P.order_id

		EXEC  Fill_Order_Data;


	/* Fill item table by data from item dataset */
		Go;
		CREATE PROCEDURE Fill_Item_Data
		AS
			INSERT INTO [dbo].[Item]([ID],[Unit_Price],[Quantity],[Freight_Value],[Order_ID],[Product_ID])
			SELECT NEWID(),[price],[order_item_id],[freight_value],[order_id],[product_id]
			FROM [dataset].[item_dataset]

		EXEC  Fill_Item_Data;



	/* Fill product table by data from product dataset */
		Go;
		CREATE PROCEDURE Fill_Products_Data
		AS 
			INSERT INTO [dbo].[Product]
			([ID], [Name], [Description], [Quantity], [Wight], [Lenght], [Width], [Height],[Category_ID], [Photo_ID])
			SELECT product_id, product_name_lenght, product_description_lenght, null, product_weight_g, 
			product_length_cm, product_width_cm, product_height_cm, product_category_name, product_photos_qty 
			FROM [dataset].[product_dataset]

		EXEC Fill_Products_Data;


	/* Fill seller table by data from seller dataset */
		Go;
		CREATE PROCEDURE Fill_Seller_Data
		AS 
			INSERT INTO [dbo].[Seller]
			([ID], [Name], [Email])
			SELECT seller_id, null, null
			FROM [dataset].[seller_dataset]
		GO;

		EXEC Fill_Seller_Data


	/* Fill Location table by customer id */
		Go;
		CREATE PROC Fill_Location_Customer_id
		AS 
			UPDATE L
			SET L.Customer_ID = C.ID
			FROM [dbo].[Location] AS L
			INNER JOIN [dbo].[Customer] AS C
			ON C.Postal_Code = L.Postal_Code

		EXEC Fill_Location_Customer_id;



	/* Fill Order table by location_id */
		Go;
		CREATE PROC Fill_Order_Location_id
		AS 
			UPDATE O
			SET O.Location_ID = L.ID
			FROM [dbo].[Order] AS O
			INNER JOIN [dbo].[Customer] AS C
			ON C.ID = O.Customer_ID
			INNER JOIN [dbo].[Location] AS L
			ON C.ID = L.Customer_ID

		EXEC Fill_Order_Location_id;



	/* Fill Review table by customer_id  */
		Go;
		CREATE PROC Fill_Review_customer_id
		AS 
			UPDATE R
			SET R.Customer_ID = O.Customer_ID
			FROM [dbo].[Review] AS R
			INNER JOIN [dbo].[Order] AS O
			ON O.ID = R.Order_ID
	
		EXEC Fill_Review_customer_id



	/* get seller id from items and set in product. */
		Go;
		ALTER PROCEDURE Fill_Product_Seller_ID
		AS 
			UPDATE P
			SET P.[Seller_ID] = S.seller_id
			FROM [dbo].[Product] AS P
			INNER JOIN [dataset].[item_dataset] AS I
			ON P.ID = I.product_id 
			INNER JOIN [dataset].[seller_dataset] AS S
			ON S.seller_id = I.seller_id
		GO;

		EXEC Fill_Product_Seller_ID


	/* Replace category name by category id in products */
		Go;
		CREATE PROC Replace_Name_by_Id
		AS 
			UPDATE P
			SET P.Category_ID = C.ID
			FROM [dbo].[Product] AS P
			INNER JOIN [dbo].[Category] AS C
			ON C.Description = P.Category_ID

		EXEC Replace_Name_by_Id;


	/* Remove Duplicate data from customer */
		Go;
		WITH Remove_Dublicate_customer AS (
			SELECT *, ROW_NUMBER() OVER (PARTITION BY [ID] ORDER BY ID) AS row_num
			FROM [dbo].[Customer]
		)

		DELETE FROM Remove_Dublicate_customer
		WHERE row_num > 1;


	/*remove conflict data between order and item*/
		WITH Remove_Conflict_Item_Order
		AS (
			SELECT * 
			FROM [dbo].[Item]
			WHERE order_id not in ( SELECT ID FROM [dbo].[Order]))

		DELETE FROM Remove_Conflict_Item_Order


	/*remove conflict data between order and Customer*/
		WITH Remove_Conflict_Order_Customer
		AS (
		SELECT * 
		FROM [dbo].[Order] AS O
		WHERE O.Customer_ID NOT IN (
									SELECT ID
									FROM [dbo].[Customer]
								)
		)

		UPDATE Remove_Conflict_Order_Customer SET Customer_ID = null


	/*remove conflict data between order and Customer*/
		Go;
		ALTER PROC Remove_Conflict_Product_Category
		AS 
			UPDATE [dbo].[Product] 
			SET Category_ID = null 
			WHERE Category_ID NOT IN (SELECT ID FROM [dbo].[Category] )
	
		EXEC Remove_Conflict_Product_Category


	/* Remove Duplicate data from review */
		WITH cte AS (
			SELECT [review_id], ROW_NUMBER() OVER (PARTITION BY [review_id] ORDER BY [review_id]) row_num
			FROM [dataset].[review_dataset]
		)

		DELETE FROM cte
		WHERE row_num > 1;


	/* Remove Duplicate data from payment */
		Go;
		WITH Remove_Duplicate_Payment 
		AS (
				SELECT P.order_id, ROW_NUMBER() OVER (PARTITION BY P.order_id ORDER BY P.order_id) AS row_num
				FROM [dataset].[payment_dataset] AS P
				)

		DELETE FROM Remove_Duplicate_Payment
		WHERE row_num > 1;
