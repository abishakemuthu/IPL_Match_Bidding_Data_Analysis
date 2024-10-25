use ipl;
-- Questions – Write SQL queries to get data for the following requirements:

-- 1.	Show the percentage of wins of each bidder in the order of highest to lowest percentage.

with temp1 as(
select BIDDER_ID,count(BID_STATUS)over(partition by BIDDER_ID) as T1 
from ipl_bidding_details 
where BID_STATUS = 'Won'),
temp2 as(
select BIDDER_ID,count(BID_STATUS)over(partition by BIDDER_ID) as T2
from ipl_bidding_details)
select distinct temp1.BIDDER_ID,(temp1.T1/temp2.T2)*100 as `Percentage of Wins` 
from temp1 join temp2 on temp1.BIDDER_ID=temp2.BIDDER_ID
order by `Percentage of Wins` desc;


-- 2.	Display the number of matches conducted at each stadium with the stadium name and city.

select STADIUM_NAME, CITY, count(MATCH_ID) as `Count of Matches`
from ipl_match_schedule mc join ipl_stadium s on mc.STADIUM_ID=s.STADIUM_ID
group by STADIUM_NAME, CITY;


-- 3.	In a given stadium, what is the percentage of wins by a team that has won the toss?

select distinct STADIUM_ID, TOSS_WINNER, 
count(MATCH_WINNER)over(partition by STADIUM_ID,TOSS_WINNER order by STADIUM_ID, TOSS_WINNER)/
count(MATCH_WINNER)over(partition by STADIUM_ID order by STADIUM_ID)*100 as `Percentage of Wins`
from ipl_match_schedule ms join ipl_match m on ms.MATCH_ID=m.MATCH_ID;


-- 4.	Show the total bids along with the bid team and team name.

select BID_TEAM, TEAM_NAME, count(NO_OF_BIDS) as Total_bids
from ipl_bidder_points bp 
join ipl_bidding_details bd on bp.BIDDER_ID=bd.BIDDER_ID
join ipl_match_schedule ms on bd.SCHEDULE_ID=ms.SCHEDULE_ID
join ipl_match m on ms.match_id=m.match_id
join ipl_team t on m.TEAM_ID1=t.TEAM_ID
group by BID_TEAM, TEAM_NAME
order by Total_bids desc;


-- 5.	Show the team ID who won the match as per the win details.

select distinct MATCH_ID, WIN_DETAILS,case
when MATCH_WINNER = 1 then TEAM_ID1
when MATCH_WINNER = 2 then TEAM_ID2 end as Won_team_Id
from ipl_match;


-- 6.	Display the total matches played, total matches won and total matches lost by the team along with its team name.

select TEAM_NAME, sum(MATCHES_PLAYED) Total_Matches_Played, sum(MATCHES_WON) Total_Match_won, sum(MATCHES_LOST) Total_Matches_Lost
from ipl_team t join ipl_team_Standings ts on t.team_Id=ts.team_Id
group by TEAM_NAME;


-- 7.	Display the bowlers for the Mumbai Indians team.

select PLAYER_NAME, TEAM_NAME, PLAYER_ROLE
from ipl_team t join ipl_Team_players tp on t.TEAM_ID=tp.TEAM_ID 
join ipl_Player p on tp.PLAYER_ID=p.PLAYER_ID
where TEAM_NAME = 'Mumbai Indians' and PLAYER_ROLE = 'Bowler';


-- 8.	How many all-rounders are there in each team, Display the teams with more than 4 all-rounders in descending order.

select TEAM_ID, count(PLAYER_ID) Total_All_Rounder
from ipl_team_players
where PLAYER_ROLE = 'All-Rounder'
group by TEAM_ID
having Total_All_Rounder>4
order by Total_All_Rounder desc;


-- 9.	 Write a query to get the total bidders' points for each bidding status of those bidders who bid on CSK 
-- when they won the match in M. Chinnaswamy Stadium bidding year-wise.
-- Note the total bidders’ points in descending order and the year is the bidding year.
--   Display columns: bidding status, bid date as year, total bidder’s points

select BID_STATUS, year(BID_DATE) bid_date, TOTAL_POINTS
from ipl_Bidder_points bp 
join ipl_bidding_details bd on bp.BIDDER_ID=bd.BIDDER_ID
join ipl_match_schedule ms on bd.SCHEDULE_ID=ms.SCHEDULE_ID
join ipl_match m on ms.MATCH_ID=m.MATCH_ID
join ipl_team t on m.TEAM_ID1=t.team_Id
join ipl_stadium s on ms.stadium_Id=s.stadium_Id
where t.REMARKS = 'CSK' and BID_STATUS = 'Won' and STADIUM_NAME = 'M. Chinnaswamy Stadium';


-- 10.	Extract the Bowlers and All-Rounders that are in the 5 highest number of wickets.
-- Note 
-- 1. Use the performance_dtls column from ipl_player to get the total number of wickets
-- 2. Do not use the limit method because it might not give appropriate results when players have the same number of wickets
-- 3.	Do not use joins in any cases.
-- 4.	Display the following columns team_name, player_name, and player_role.

with temp as(
select team_name, player_name, player_role, dense_rank()over(order by wkt desc) as Rnk
from
(select team_Id, team_name from ipl_team) as sub1,
(select team_Id, player_Id, player_role from ipl_team_players) as sub2,
(select player_Id,player_name, trim(substr(PERFORMANCE_DTLS,(instr(PERFORMANCE_DTLS,'Wkt'))+4,2)) as wkt from ipl_player) as sub3 
where sub1.team_id=sub2.team_Id and sub2.player_id=sub3.player_Id and player_role in('Bowler','All-Rounder')
order by wkt desc)
select * from temp where rnk <=5;


-- 11.	show the percentage of toss wins of each bidder and display the results in descending order based on the percentage

with temp as(
select BIDDER_ID, BID_TEAM, case
when BID_TEAM = Toss_win then 'Win'
else 'Lose' end as Tw
from (
select BIDDER_ID, BID_TEAM, TEAM_ID1, TEAM_ID2, TOSS_WINNER, case
when TOSS_WINNER = 1 then TEAM_ID1
when TOSS_WINNER = 2 then TEAM_ID2 end as Toss_win
from ipl_match m 
join ipl_match_schedule ms on m.match_id=ms.match_id
join ipl_bidding_details bd on ms.schedule_Id=bd.schedule_Id)T)
select distinct BIDDER_ID, 
round(count(Tw)over(partition by BIDDER_ID)/(select Count(distinct BIDDER_ID) from temp)*100) as Win_Percendage
from temp
where Tw = 'Win';


-- 12.	find the IPL season which has a duration and max duration.
-- Output columns should be like the below:
-- Tournment_ID, Tourment_name, Duration column, Duration

select TOURNMT_ID, TOURNMT_NAME, datediff(TO_DATE,FROM_DATE) as Duration 
from ipl_tournament
order by Duration desc
limit 2;


-- 13.	Write a query to display to calculate the total points month-wise for the 2017 bid year.
-- sort the results based on total points in descending order and month-wise in ascending order.
-- Note: Display the following columns:
-- 1.	Bidder ID, 2. Bidder Name, 3. Bid date as Year, 4. Bid date as Month, 5. Total points Only use joins for the above query queries.

select bd.BIDDER_ID, BIDDER_NAME, year(bid_date) year_wise, month(BID_DATE) month_wise,sum(TOTAL_POINTS) total_point
from ipl_bidder_details bd join ipl_bidding_details bgd on bd.bidder_Id=bgd.bidder_Id
join ipl_Bidder_points bp on bgd.bidder_Id=bp.bidder_Id
where year(bid_date)= 2017
group by BIDDER_ID, BIDDER_NAME, year_wise, month_wise
order by month_wise asc, total_point desc;


-- 14.	Write a query for the above question using sub-queries by having the same constraints as the above question.

select sub1.BIDDER_ID, Bidder_Name, year_wise,month_wise,sum(TOTAL_POINTS) Total_point 
from 
(select BIDDER_ID, Bidder_Name 
from ipl_bidder_Details) as Sub1,
(select BIDDER_ID, year(bid_date) year_wise, month(bid_date) month_wise 
from ipl_bidding_details where year(bid_date)=2017) as Sub2,
(select BIDDER_ID, TOTAL_POINTS 
from ipl_Bidder_points) as sub3
where sub1.BIDDER_ID=sub2.BIDDER_ID and sub2.BIDDER_ID=sub3.BIDDER_ID
group by sub1.BIDDER_ID, Bidder_Name, year_wise,month_wise
order by month_wise,total_point desc;


-- 15.	Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
-- Output columns should be:
-- like
-- Bidder Id, Ranks (optional), Total points, Highest_3_Bidders --> columns contains name of bidder, Lowest_3_Bidders  
-- > columns contains name of bidder;

with temp as(
select bd.BIDDER_ID, BIDDER_NAME, year(bid_date) year_wise, month(BID_DATE) month_wise,sum(TOTAL_POINTS) total_point,
rank()over(order by sum(TOTAL_POINTS) desc)as rank_
from ipl_bidder_details bd join ipl_bidding_details bgd on bd.bidder_Id=bgd.bidder_Id
join ipl_Bidder_points bp on bgd.bidder_Id=bp.bidder_Id
where year(bid_date)= 2018
group by BIDDER_ID, BIDDER_NAME, year_wise, month_wise
order by month_wise asc, total_point desc)
(select BIDDER_ID, rank_, total_point, BIDDER_NAME
from temp order by rank_ limit 3)
union
(select BIDDER_ID, rank_, total_point, BIDDER_NAME
from temp order by rank_ desc limit 3);


-- 16.	Create two tables called Student_details and Student_details_backup. (Additional Question - Self Study is required)

-- Table 1: Attributes 		Table 2: Attributes
-- Student id, Student name, mail id, mobile no.	Student id, student name, mail id, mobile no.

-- Feel free to add more columns the above one is just an example schema.
-- Assume you are working in an Ed-tech company namely Great Learning where you will be inserting and
-- modifying the details of the students in the Student details table. 
-- Every time the students change their details like their mobile number, You need to update their details in the student details table.
-- Here is one thing you should ensure whenever the new students' details come, 
-- you should also store them in the Student backup table so that if you modify the details in the student details table, 
-- you will be having the old details safely.
-- You need not insert the records separately into both tables rather Create a trigger in such a way that It should 
-- insert the details into the Student back table when you insert the student details into the student table automatically.

create table Student_details(
Student_id int primary key,
Student_name varchar(20),
mail_id varchar(30),
mobile_no numeric);

create table Student_details_backup(
Student_id int,
Student_name varchar(20),
mail_id varchar(30),
mobile_no numeric,
date_modified timestamp default now());

delimiter $$
create trigger student_details_insert
before insert on student_details for each row
insert into Student_details_backup (Student_id, Student_name, mail_id, mobile_no)
value(new.Student_id, new.Student_name, new.mail_id, new.mobile_no);
end $$ delimiter ;

delimiter $$
create trigger student_details_delete
before delete on student_details for each row
insert into Student_details_backup (Student_id, Student_name, mail_id, mobile_no)
value(old.Student_id, old.Student_name, old.mail_id, old.mobile_no);
end $$ delimiter ;

delimiter $$
create trigger student_details_update
before update on student_details for each row
insert into Student_details_backup (Student_id, Student_name, mail_id, mobile_no)
value(new.Student_id, new.Student_name, new.mail_id, new.mobile_no);
end $$ delimiter ;

select * from student_details;
select * from student_details_backup;

insert into student_details value
(01,'Abi','abi@gmail.com','9080895842'),
(02,'Akhil','akhil@gmail.com','9080895842'),
(03,'Yogesh','yogesh@gmail.com','9080895842'),
(04,'Gaja','gaja@gmail.com','9080895842');

insert into student_details value
(05,'Ajay','ajay@gmail.com','9080895842'),
(06,'Sachin','sachin@gmail.com','9080895842');

update student_details
set mobile_no = '9876543210' 
where Student_id = 05;

delete from student_details
where Student_id in(01,04,06);

-- Thank You