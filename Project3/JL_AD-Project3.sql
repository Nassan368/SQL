use master;
GO
Alter database Project3  set single_user with rollback immediate;
GO
DROP Database Project3;
GO 

CREATE DATABASE Project3;
GO

USE Project3;
GO

-- 24f Initial Project3 Database script - ADD your solution to the END of this script for all the requirements of Project 3
CREATE TABLE dbo.Departments (
    DepartmentID       INT IDENTITY PRIMARY KEY,
    DepartmentName NVARCHAR(50) NOT NULL,
    DepartmentDesc  NVARCHAR(100) CONSTRAINT DF_DFDeptDesc DEFAULT 'Actual Dept. Desc to be determined'
);

CREATE TABLE dbo.Employees (
    EmployeeID               INT IDENTITY PRIMARY KEY,
    DepartmentID            INT CONSTRAINT FK_Employee_Department FOREIGN KEY REFERENCES dbo.Departments ( DepartmentID ),
    ManagerEmployeeID INT CONSTRAINT FK_Employee_Manager FOREIGN KEY REFERENCES dbo.Employees ( EmployeeID ),
    FirstName                  NVARCHAR(50),
    LastName                  NVARCHAR(50),
    Salary                        MONEY CONSTRAINT CK_EmployeeSalary CHECK ( Salary >= 0 ),
    CommissionBonus    MONEY CONSTRAINT CK_EmployeeCommission CHECK ( CommissionBonus >= 0 ),
    FileFolder                  NVARCHAR(256) CONSTRAINT DF_FileFolder DEFAULT 'ToBeCreated'
);

GO
INSERT INTO dbo.Departments ( DepartmentName, DepartmentDesc )
VALUES ( 'Management', 'Executive Management' ),
       ( 'HR', 'Human Resources' ),
       ( 'Database', 'Database Administration'),
       ( 'Support', 'Product Support' ),
       ( 'Software', 'Software Sales' ),
       ( 'Marketing', 'Digital Marketing' );
GO

SET IDENTITY_INSERT dbo.Employees ON;
GO

INSERT INTO dbo.Employees ( EmployeeID, DepartmentID, ManagerEmployeeID, FirstName, LastName, Salary, CommissionBonus, FileFolder )
VALUES ( 1, 4, NULL, 'Sarah', 'Campbell', 78000, NULL, 'SarahCampbell' ),
       ( 2, 3, 1, 'James', 'Donoghue',     68000 , NULL, 'JamesDonoghue'),
       ( 3, 1, 1, 'Hank', 'Brady',        76000 , NULL, 'HankBrady'),
       ( 4, 2, 1, 'Samantha', 'Jonus',    72000, NULL , 'SamanthaJonus'),
       ( 5, 3, 4, 'Fred', 'Judd',         44000, 5000, 'FredJudd'),
       ( 6, 3, NULL, 'Hanah', 'Grant',   65000, 4000 ,  'HanahGrant'),
       ( 7, 3, 4, 'Dhruv', 'Patel',       66000, 2000 ,  'DhruvPatel'),
       ( 8, 4, 3, 'Dash', 'Mansfeld',     54000, 5000 ,  'DashMansfeld');
GO

SET IDENTITY_INSERT dbo.Employees OFF;
GO

CREATE FUNCTION dbo.GetEmployeeID (
    -- Parameter datatype and scale match their targets
    @FirstName NVARCHAR(50),
    @LastName  NVARCHAR(50) )
RETURNS INT
AS
BEGIN;


    DECLARE @ID INT;

    SELECT @ID = EmployeeID
    FROM dbo.Employees
    WHERE FirstName = @FirstName
          AND LastName = @LastName;

    -- Note that it is not necessary to initialize @ID or test for NULL, 
    -- NULL is the default, so if it is not overwritten by the select statement
    -- above, NULL will be returned.
    RETURN @ID;
END;
GO


/* REQUIREMENT 1
Basic Stored Procedure
*/
CREATE PROCEDURE dbo.InsertDepartments(
@DepartmentName NVARCHAR(50),
@DepartmentDesc NVARCHAR(100) = 'Actual Dept. Desc to be determined'
)
AS
BEGIN;
	INSERT INTO dbo.Departments(DepartmentName, DepartmentDesc)
	VALUES(@DepartmentName, @DepartmentDesc)
END;
GO


/* REQUIREMENT 2
Basic Procedure Execution
*/
EXECUTE dbo.InsertDepartments 'QA', 'Quality Assurance';
EXECUTE dbo.InsertDepartments 'SysDev', 'Systems Development';
EXECUTE dbo.InsertDepartments 'Infrastructure', 'Deployment and Production Support';
EXECUTE dbo.InsertDepartments 'DesignEngineering', 'Project Initiation/Design/Engineering';
SELECT * FROM dbo.Departments;
GO


/* REQUIREMENT 3
Scalar Function
*/
CREATE FUNCTION dbo.GetDepartmentID (
	@DepartmentName NVARCHAR(50)
)
RETURNS INT
AS
BEGIN;
	--Declare ID variable
	DECLARE @DepartmentID INT;

	--Get the ID based on the Department Name
	SELECT @DepartmentID = DepartmentID
	FROM dbo.Departments
	WHERE DepartmentName = @DepartmentName;

	--Return the ID
	RETURN @DepartmentID;
END;
GO


/* REQUIREMENT 4
Intermediate Stored Procedure
*/
CREATE PROCEDURE dbo.InsertEmployee (
@DepartmentName NVARCHAR(50),
@EmployeeFirstName NVARCHAR(50),
@EmployeeLastName NVARCHAR(50),
@Salary MONEY = 46000, --Default Salary of 46000
@FileFolder NVARCHAR(256),
@ManagerFirstName NVARCHAR(50),
@ManagerLastName NVARCHAR(50),
@CommissionBonus MONEY = 5000 --Default CommissionBonus of 5000
)
AS
BEGIN;

	--Declaring the Variables for IDs
	DECLARE @DepartmentID INT;
	DECLARE @ManagerEmployeeID INT;
	--Set the filefolder name to concat the employee first and last name
	SET @FileFolder = CONCAT(@EmployeeFirstName, @EmployeeLastName);

	--Try catch so it is not committed if there is an error
	BEGIN TRY
	BEGIN TRANSACTION;

	--Check DepartmentID with GetDepartmentID, if it null insert the new department with InsertDepartment
	SELECT @DepartmentID = dbo.GetDepartmentID(@DepartmentName);
	IF(@DepartmentID IS NULL)
	BEGIN;
		EXECUTE dbo.InsertDepartments @DepartmentName;
		--Reassign the DepartmentID
		SELECT @DepartmentID = dbo.GetDepartmentID(@DepartmentName);
	END;

	--Check ManagerEmployeeId with GetEmployeeID, if it is null insert the new employee
	SELECT @ManagerEmployeeID = dbo.GetEmployeeID(@ManagerFirstName, @ManagerLastName);
	IF(@ManagerEmployeeID IS NULL)
	BEGIN;
		INSERT INTO dbo.Employees (DepartmentID, FirstName, LastName, Salary, CommissionBonus, FileFolder)
		VALUES (@DepartmentID, @ManagerFirstName, @ManagerLastName, (@Salary + 12000), @CommissionBonus, (@ManagerFirstName + @ManagerLastName));
		--Reassign the ManagerEmployeeID
		SELECT @ManagerEmployeeID = dbo.GetEmployeeID(@ManagerFirstName, @ManagerLastName);
	END;

		INSERT INTO dbo.Employees (DepartmentID, ManagerEmployeeID, FirstName, LastName, Salary, CommissionBonus, FileFolder)
		VALUES (@DepartmentID, @ManagerEmployeeID, @EmployeeFirstName, @EmployeeLastName, @Salary, @CommissionBonus, @FileFolder);

	COMMIT TRANSACTION;	
	--End try
	END TRY
	
	--Begin catch to rollback
	BEGIN CATCH
		ROLLBACK TRANSACTION;
	END CATCH;
END;
GO

--Test 1: Setting salary and commission to default and the file folder name will be set to the first & last name of the employee
EXECUTE dbo.InsertEmployee 'Deployment', 'Wherewolf', 'Waldo', DEFAULT, 'FirstNameLastName', 'Jacob', 'Liberatore', DEFAULT;
--Test 2:
EXECUTE dbo.InsertEmployee 'Database', 'Adnan', 'Nassan', 43000, 'YourFriendFirstNameYourFriendLastName', 'Sarah', 'Campbell', 4000;
--Selects
SELECT * FROM dbo.Employees
SELECT * FROM dbo.Departments
GO


/* REQUIREMENT 5
Table Value Function
*/
CREATE FUNCTION dbo.EmployeeCommission(
@Commission INT
)
RETURNS @Results Table(
	FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	Salary MONEY,
	CommissionBonus MONEY,
	FileFolder NVARCHAR(256),
	DepartmentName NVARCHAR(50),
	DepartmentDesc NVARCHAR(100)
)
AS
BEGIN;
	--Checking if @Commission is >= 0
	IF(@Commission >=0)
		BEGIN;
		--If the commission is >= 0 insert the data into the results table
			INSERT INTO @Results
			SELECT 
				e.FirstName, 
				e.LastName, 
				e.Salary, 
				e.CommissionBonus, 
				e.FileFolder, 
				d.DepartmentName, 
				d.DepartmentDesc
			FROM 
				dbo.Employees e
			INNER JOIN 
				dbo.Departments d ON e.DepartmentID = d.DepartmentID
			WHERE 
				CommissionBonus >= @Commission
		END;
	RETURN
END;
GO

-- Test with commission value of 5000
SELECT * FROM dbo.EmployeeCommission(5000);
-- Test with commission value of 4000
SELECT * FROM dbo.EmployeeCommission(4000);
GO


/* REQUIREMENT 6
Window Function
*/
WITH RankEmployees AS (
SELECT 
    DepartmentName,
    (FirstName + ' ' + LastName) AS EmployeeName,
    Salary,
    CommissionBonus AS Commission,
	
	--Using Salary + commission for compensation
	--ISNULL for commissionBonus in the case they don't have one, this allows us to properly find the correct rank
    (Salary + ISNULL(CommissionBonus, 0)) AS Compensation,
   
    -- Rank employees within each department by desc compensation
    RANK() OVER (PARTITION BY DepartmentName ORDER BY (Salary + ISNULL(CommissionBonus, 0)) DESC) AS RankInDepartment,
    
    -- Get the name and compensation of the person above them in rank
    LAG(FirstName + ' ' + LastName) OVER (PARTITION BY DepartmentName ORDER BY (Salary + ISNULL(CommissionBonus, 0)) DESC) AS PersonAboveName,
    LAG(Salary + ISNULL(CommissionBonus, 0)) OVER (PARTITION BY DepartmentName ORDER BY (Salary + ISNULL(CommissionBonus, 0)) DESC) AS PersonAboveSalary,
    
    -- Calculate the average compensation per department
    AVG(Salary + ISNULL(CommissionBonus, 0)) OVER (PARTITION BY DepartmentName) AS AvgDepartmentCompensation
FROM 
    dbo.Employees e
INNER JOIN 
    dbo.Departments d ON e.DepartmentID = d.DepartmentID
)
SELECT 
    DepartmentName,
	RankInDepartment,
	EmployeeName,
	Compensation,
    Salary,
    Commission,
    PersonAboveName,
    PersonAboveSalary,
    AvgDepartmentCompensation,
    Compensation - AvgDepartmentCompensation AS EmployeeVsDepartmentAvg -- Comparison between each person's compensation and department average
FROM 
    RankEmployees
ORDER BY 
    DepartmentName,
    RankInDepartment;

GO


/* REQUIREMENT 7
Recursive CTE
*/
WITH EmpByManagerCTE AS (
    -- Anchor Members for top level managers
    SELECT 
        EmployeeID, 
        FirstName, 
        LastName, 
        DepartmentID, 
        ManagerEmployeeID,
		-- Set ManagerFirstName and ManagerLastName to NULL for top level managers because they don't have a manager
        CAST(NULL AS NVARCHAR(50)) AS ManagerFirstName,
        CAST(NULL AS NVARCHAR(50)) AS ManagerLastName,	
		-- Create the FileFolder and FilePath by concatenating first and last names and casting them as NVARCHAR(MAX)
        CAST(FirstName + LastName AS NVARCHAR(MAX)) AS FileFolder,  
        CAST(FirstName + LastName AS NVARCHAR(MAX)) AS FilePath
    FROM dbo.Employees
    WHERE ManagerEmployeeID IS NULL --Only top level managers

UNION ALL

	-- Recursive Members: Employees reporting to a manager
    SELECT 
        e.EmployeeID, 
        e.FirstName, 
        e.LastName, 
        e.DepartmentID, 
        e.ManagerEmployeeID,	
		-- For employees we are using Manager's first and last names from the CTE
		CTE.FirstName AS ManagerFirstName,
		CTE.LastName AS ManagerLastName,		
		-- Create the FileFolder for this employee
        CAST(e.FirstName + e.LastName AS NVARCHAR(MAX)) AS FileFolder,
		-- Create the FilePath for this employee by Appending the managers FilePath with their first & last name
        CTE.FilePath + '\' + CAST(e.FirstName + e.LastName AS NVARCHAR(MAX)) AS FilePath
    FROM 
        dbo.Employees e
    JOIN 
		EmpByManagerCTE CTE ON e.ManagerEmployeeID = CTE.EmployeeID 
)
SELECT 
    e.LastName AS 'Employee LastName',
    e.FirstName AS 'Employee FirstName',
    e.DepartmentID AS 'Department ID',
    CTE.FileFolder,		-- FileFolder based on the employee name
	ManagerLastName AS 'Manager LastName',  
    ManagerFirstName AS 'Manager FirstName',
    CTE.FilePath		-- FilePath recursively appending managers names
FROM 
    EmpByManagerCTE CTE
JOIN 
    dbo.Employees e ON e.EmployeeID = CTE.EmployeeID
ORDER BY 
    CTE.FilePath; --Order by the file path
GO
