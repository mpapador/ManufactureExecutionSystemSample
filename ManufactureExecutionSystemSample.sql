--General Exploritory-----------------------------------------------------

--All Employees Currently Clocked In
SELECT Username,
	AlternateUsername,
	FullName,
	StartDate,
	StopDate
FROM Employee AS EMP
JOIN EmployeeAttendance AS EMPA ON EMP.id = empa.EmployeeId
WHERE EMPA.AttendanceStatusId = 1
ORDER BY Startdate, Username

--All Employees Clocked In or Out
SELECT Id,
	EmployeeId,
	EmployeeNumber,
	Employee,
	StartDate,
	StopDate,
	AttendanceStatus
FROM [rpt].[EmployeeAttendance] WHERE AttendanceStatus IN (
		'Clocked-In',
		'Clocked-Out'
		) AND EmployeeNumber <> 'PPL3'
ORDER BY  Site,
	TransactionCalendarDate, EmployeeNumber

--All active users and their roles, concatenated
SELECT Username,
	FullName,
	EmailAddress,
	AlternateUsername,
	DefSite,
	DefWorkC,
	Culture,
	MultipleJobAllowedERP,
	MultipleJobAllowedOverrideERP,
	RoleName
FROM (
	SELECT EMP.Username,
		EMP.FullName,
		EMP.EmailAddress,
		EMP.AlternateUsername,
		Site.Name AS DefSite,
		WC.name DefWorkC,
		EMP.Culture,
		MultipleJobAllowedERP,
		MultipleJobAllowedOverrideERP,
		STUFF((
				SELECT ', ' + AR.Name
				FROM AspNetUserRoles AS AUR
				INNER JOIN AspNetRoles AS AR ON AUR.RoleId = AR.Id
				WHERE AUR.UserId = AU.Id
				FOR XML PATH('')
				), 1, 2, '') AS RoleName,
		ROW_NUMBER() OVER (
			PARTITION BY EMP.Username ORDER BY RL.Name
			) AS RowNumber
	FROM Employee AS EMP
	JOIN AspNetUsers AS AU ON EMP.Username = AU.UserName
	LEFT OUTER JOIN Site ON EMP.DefaultSiteId = Site.id
	LEFT OUTER JOIN WorkCenter AS WC ON EMP.DefaultWorkCenterId = WC.Id
	LEFT OUTER JOIN AspNetUserRoles AS AUR ON AUR.UserId = AU.Id
	LEFT OUTER JOIN AspNetRoles AS AR ON AUR.RoleId = AR.Id
	LEFT OUTER JOIN SystemRole AS RL ON RL.id = AR.IdInt
	WHERE EMP.SoftDeleted = 0 AND AU.IsApproved = 1 AND EMP.Username NOT LIKE 'PPL%'
	) AS T
WHERE RowNumber = 1
ORDER BY Username,
	RoleName;

--All Active Users (users that are set to active)
SELECT EMP.Username,
	EMP.FullName,
	EMP.EmailAddress,
	EMP.AlternateUsername,
	Site.Name AS DefSite,
	WC.name DefWorkC,
	EMP.Culture,
	MultipleJobAllowedERP,
	MultipleJobAllowedOverrideERP
FROM Employee AS EMP
JOIN AspNetUsers AS AU ON EMP.Username = AU.UserName
LEFT OUTER JOIN Site ON EMP.DefaultSiteId = Site.id
LEFT OUTER JOIN WorkCenter AS WC ON EMP.DefaultWorkCenterId = WC.Id
WHERE EMP.SoftDeleted = 0 AND AU.IsApproved = 1 AND EMP.Username NOT LIKE 'PPL%'
ORDER BY EMP.Username

--Current Running Labor (employees on a job)
SELECT ST.Description AS Site,
	WC.name AS WorkCenter,
	E.Username,
	E.FullName,
	L.StartDate,
	DATEDIFF(MINUTE, L.StartDate, GETUTCDATE()) AS [RunningTime(mins)],
	ORT.Name AS OrdType,
	LST.Name AS Labor,
	LT.Name AS LabType,
	n.Name AS Nest,
	Crw.Name AS Crew,
	MOO.Number,
	MOO.Operation,
	SMO.Description AS [Order Status],
	S.Description AS [Operation Status],
	L.softdeleted AS [LbrDel],
	MO.SoftDeleted AS [OrdDel],
	MOO.SoftDeleted AS [OpDel],
	L.id
FROM Labor AS L
JOIN Employee AS E ON L.EmployeeId = E.Id
JOIN OrderType AS ORT ON L.OrderTypeId = ORT.id
JOIN LaborType AS LT ON L.LaborTypeId = LT.id
JOIN LaborStatusType AS LST ON L.LaborStatusTypeId = LST.Id
JOIN Site AS ST ON L.SiteId = ST.Id
LEFT OUTER JOIN Nest AS N ON L.NestId = N.id
LEFT OUTER JOIN ManufactureOrderOperation AS MOO ON MOO.id = L.ManufactureOrderOperationId
LEFT OUTER JOIN WorkCenter AS WC ON WC.id = L.WorkCenterId
LEFT OUTER JOIN OrderStatus AS S ON MOO.OrderStatusId = S.Id
LEFT OUTER JOIN ManufactureOrder AS MO ON MOO.ManufactureOrderId = MO.Id
LEFT OUTER JOIN OrderStatus AS SMO ON MO.OrderStatusId = SMO.Id
LEFT OUTER JOIN CrewLabor AS CL ON L.CrewLaborId = CL.Id
LEFT OUTER JOIN Crew AS CRW ON CL.CrewId = CRW.Id
WHERE (L.LaborStatusTypeId = 1) AND (L.StopDate IS NULL) AND L.SoftDeleted = 0
ORDER BY L.StartDate, E.Username

--All labor Run
SELECT E.Username,
	E.FullName,
	MOO.Number,
	MOO.Operation,
	L.StartDate,
	L.StopDate,
	MO.OrderStatusId,
	MOO.OrderStatusId,
	MO.SoftDeleted,
	MO.SoftDeletedDate,
	MOO.SoftDeleted,
	MOO.SoftDeletedDate
FROM Labor AS L
JOIN ManufactureOrderOperation AS MOO ON L.ManufactureOrderOperationId = MOO.Id
JOIN ManufactureOrder AS MO ON L.ManufactureOrderOperationId = MO.Id
JOIN Employee AS E ON L.EmployeeId = E.Id
WHERE MOO.Number = '(MO)' AND MOO.Operation = '(OP)' --'MO' = manufacture order number, 'OP' = operation number of the respective manufacture order
ORDER BY StopDate