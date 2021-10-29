Select *
From dbo.dailyActivity_merged

--Check distinct users 

Select Distinct Id
From dbo.dailyActivity_merged


--Check NULL values

Select Id, ActivityDate, TotalSteps, Calories
From dbo.dailyActivity_merged
Where TotalSteps IS NULL OR Calories IS NULL


--Check total users' data for each day

Select ActivityDate, Count(*) TotalUsers
From dbo.dailyActivity_merged
Group by ActivityDate
Order by ActivityDate


--Check each users total data
Select Id, Count(ActivityDate)
From dbo.dailyActivity_merged
Group by Id
Order by Id


--Check duplicates

WITH RowNumCTE AS(
Select *,
	Row_Number() OVER (
	PARTITION BY Id,
				 ActivityDate,
				 TotalSteps,
				 TotalDistance,
				 TrackerDistance,
				 Calories
				 ORDER BY
					Id
					) row_num
From dbo.dailyActivity_merged
)
Select*
From RowNumCTE
Where row_num>1


--Remove users with total data <20 and ActivityDate = 2016-05-12

Select Id, Count(ActivityDate)
From dbo.dailyActivity_merged
Where ActivityDate<>'2016-05-12'
Group by Id
Having Count(ActivityDate)<20
Order by Id

Delete from dailyActivity_merged
where Id=2347167796 OR Id=4057192912 OR Id=8253242879
	OR ActivityDate='2016-05-12'

Select *
From dbo.dailyActivity_merged
Where ActivityDate='2016-05-12'

/* Check percentage 10k steps in a month*/
Select Id, Count(TotalSteps), Count(TotalSteps)/30 * 100.0 Percent10kSteps
From dbo.dailyActivity_merged
Where TotalSteps >= 10000
Group by Id
Order by Count(TotalSteps) DESC

--Compare TotalSteps vs Calories

Select Id, Avg(TotalSteps) AvgSteps, Avg(Calories) AvgCals
From dbo.dailyActivity_merged
--Where TotalSteps >= 10000
Group by Id
Order by Id



--Check into SleepDay_merged table and standardize date format and update table

Select SleepDay, Convert(Date,SleepDay)
From dbo.sleepDay_merged

Update sleepDay_merged
Set SleepDay=Convert(Date,SleepDay)


Select *
From dbo.sleepDay_merged
Order by Id

-- Join tables dailyActivity and sleepDay

Select Act.Id,
	Act.ActivityDate, 
	Act.Calories,
	Act.TotalSteps, 
	Act.VeryActiveMinutes,
	Act.FairlyActiveMinutes,
	Act.LightlyActiveMinutes,
	Act.SedentaryMinutes,
	Act.SedentaryMinutes-Sleep.TotalTimeInBed As NewSedentaryMinutes,
	Sleep.Id,
	Sleep.SleepDay,
	Sleep.TotalMinutesAsleep,
	Sleep.TotalTimeInBed,
	Sleep.TotalTimeInBed-TotalMinutesAsleep As AwakeMinutes
From dbo.dailyActivity_merged Act
Full Outer Join dbo.sleepDay_merged Sleep
	On Act.Id=Sleep.Id
	And Act.ActivityDate=Sleep.SleepDay



-- Temp Table

Drop Table if exists ActivityVsSleep
Create Table ActivityVsSleep
(
	Id numeric,
	ActivityDate date,
	Calories numeric,
	TotalSteps numeric,
	VeryActiveMinutes numeric,
	FairlyActiveMinutes numeric,
	LightlyActiveMinutes numeric,
	SedentaryMinutes numeric,
	NewSedentaryMinutes numeric,
	SleepId numeric,
	SleepDate date,
	TotalTimeInBed numeric,
	TotalMinutesAsleep numeric,
	TotalMinutesAwake numeric
  )

Insert into ActivityVsSleep
Select Act.Id, 
	Act.ActivityDate, 
	Act.Calories,
	Act.TotalSteps, 
	Act.VeryActiveMinutes,
	Act.FairlyActiveMinutes,
	Act.LightlyActiveMinutes,
	Act.SedentaryMinutes,
	Act.SedentaryMinutes-Sleep.TotalTimeInBed As NewSedentaryMinutes,
	Sleep.Id,
	Sleep.SleepDay,
	Sleep.TotalTimeInBed,
	Sleep.TotalMinutesAsleep,
	Sleep.TotalTimeInBed-TotalMinutesAsleep As AwakeMinutes
From dbo.dailyActivity_merged Act
Full Outer Join dbo.sleepDay_merged Sleep
	On Act.Id=Sleep.Id
	And Act.ActivityDate=Sleep.SleepDay

Select*
From dbo.ActivityVsSleep
Where ActivityDate='2016-05-12'



--Remove duplicates ActivityVsSleep dbo

WITH RowNumCTE AS(
Select *,
	Row_Number() OVER (
	PARTITION BY Id,
				 ActivityDate,
				 Calories,
				 TotalSteps,
				 SleepId,
				 SleepDate
				 ORDER BY
					Id
					) row_num
From dbo.ActivityVsSleep
)
Select * 
From RowNumCTE
Where row_num>1


--Delete rows having Sleep data but no daily activity data

Select*
From dbo.ActivityVsSleep
Where ActivityDate IS NULL

Delete from ActivityVsSleep
Where ActivityDate IS NULL


-- Check weekend users & non-users

Select ActivityDate, 
	Sum(CASE WHEN TotalSteps <> 0 THEN 1 Else 0 END) as Weekend_User,
	Sum(CASE WHEN TotalSteps = 0 THEN 1 Else 0 END) as Weekend_NonUser,
	Count(Activitydate) as Total_Users
From dbo.ActivityVsSleep
Where ActivityDate IN ('2016-04-16', 
						'2016-04-17',
						'2016-04-23',
						'2016-04-24', 
						'2016-04-30',
						'2016-05-01', 
						'2016-05-06', 
						'2016-05-07')
Group by ActivityDate


--Check users with and without sleep data

Select ActivityDate, 
	SUM(CASE WHEN TotalTimeInBed IS NOT NULL THEN 1 Else 0 END) as Sleep_User,
	SUM(CASE WHEN TotalTimeInBed IS NULL THEN 1 Else 0 END) as Sleep_NonUser,
	Count(ActivityDate) as Total_Users
From dbo.ActivityVsSleep
Group by ActivityDate
Order by ActivityDate

Select*
From dbo.ActivityVsSleep
--Group by Id
Order by Id

--Check average activity intensity per user

Select Id,Avg(Calories) Cals, Avg(TotalSteps) Steps, Avg(VeryActiveMinutes) Very_Active,Avg(FairlyActiveMinutes) Fairly_Active, Avg(LightlyActiveMinutes)Lightly_Active, Avg(NewSedentaryMinutes) Sedentary
From dbo.ActivityVsSleep
--Where NewSedentaryMinutes IS NOT NULL
Group by Id
Order by Id
--Select Id,ActivityDate, 
--	CASE When TotalMins >1440 then 'NEGATIVE' END as value FROM (VeryActiveMinutes+FairlyActiveMinutes+LightlyActiveMinutes+SedentaryMinutes+TotalTimeInBed) as TotalMins
----Group by Id, ActivityDate
--From dbo.ActivityVsSleep


----Create View to store data for visualisation

--Create View ActivityVsSleepView as
--Select Act.Id, 
--	Act.ActivityDate, 
--	Act.Calories,
--	Act.TotalSteps, 
--	Act.VeryActiveMinutes, 
--	Act.FairlyActiveMinutes,
--	Act.LightlyActiveMinutes,
--	Act.SedentaryMinutes-Sleep.TotalTimeInBed As NewSedentaryMinutes,
--	Sleep.TotalTimeInBed, TotalMinutesAsleep, 
--	Sleep.TotalTimeInBed-TotalMinutesAsleep As AwakeMinutes
--From dbo.dailyActivity_merged Act
--Join dbo.sleepDay_merged Sleep
--	On Act.Id=Sleep.Id
--	And Act.ActivityDate=Sleep.SleepDay


--Select Id, Count(ActivityDate)
--From dbo.ActivityVsSleepView
--Group by Id


--Select *
--From dbo.ActivityVsSleepView
--Where Id=8378563200
--Order by ActivityDate

--Select *
--From dbo.ActivityVsSleepView
--Where Id=5553957443
--Order by ActivityDate

-- Look inside hourlySteps table

Select *
From dbo.hourlySteps_merged


-- To make total users consistent, users with <20 ActivityDates will be excluded

Delete from hourlySteps_merged
where Id=2347167796 OR Id=4057192912 OR Id=8253242879


-- Check what time of the day users go for a walk

--Select StepTotal
--	Sum(CASE WHEN TotalSteps <> 0 THEN 1 Else 0 END) as Weekend_User,
--	Sum(CASE WHEN TotalSteps = 0 THEN 1 Else 0 END) as Weekend_NonUser,
--	Count(Activitydate) as Total_Users



----SET DATEFIRST 1
--Select --DATEPART(DW, CAST(ActivityHour as datetime)) DW_No,
--	DATEPART(HOUR, CAST(ActivityHour as datetime)) Hour_No,
--	Avg(Cast(StepTotal AS Int)) as Total_Steps
--From dbo.hourlySteps_merged
--GROUP BY
--	--DATEPART(DW,CAST(ActivityHour as datetime))
--	DATEPART(HOUR, CAST(ActivityHour as datetime))
--Order by Hour_No


SELECT DATENAME(WEEKDAY,'ActivityHour'), AVG(Cast(StepTotal as int)
FROM dbo.hourlySteps_merged
--WHERE    DAYOFWEEK(`date`) BETWEEN 2 AND 6
GROUP BY DATENAME(WEEKDAY,'ActivityHour')

Select Avg(Cast(StepTotal AS Int)) as Total_Steps,
	Cast(ActivityHour as Date)
From dbo.hourlySteps_merged
GROUP BY ActivityHour
Order By ActivityHour




Select Id, Count(StepTotal)
From dbo.hourlySteps_merged
Group by Id
Order by Id
