-- LAB 1 - STRUCT AND ARRAYS IN A CUMMULATIVE TABLE

select * from player_seasons ps

-- This has 2 "mixed entities": player and seasons. We want to compress the table to have a row for a single player

-- W create a data type for stats

create type season_stats as (
 season integer,
 gp integer,
 pts real,
 reb real,
 ast real
)

--  We create a players table, to avoid duplicating players

drop table players

create table players (
	player_name text,
	height text,
	college text,
	country text,
	draft_year text,
	draft_round text,
	draft_number text,
	season_stats season_stats[], -- new type we created
	current_season integer,
	primary key(player_name, current_season)
)

-- we created a compose index, what happens if we query just by one column
explain analyze
select * from players p where p.player_name = 'test' -- index scan, because player name is the first element of the compose index

explain analyze
select * from players p where p.current_season = 1 -- also uses index scan, I thought it would be sequential as this column is the second field of the compose index


explain analyze
select * from players p where p.country = 'test' -- sequential scan



insert into players
with yesterday as (

select * from players where current_season = 1995 -- this is null at this stage because there is no 1995

), today as (

select * from player_seasons ps where season = 1996

)

select
	coalesce(t.player_name,
	y.player_name) as player_name,
	coalesce(t.country, y.country) as country,
	coalesce(t.height,
	y.height) as height,
	coalesce(t.college,
	y.college) as college,
	coalesce(t.draft_year,
	y.draft_year) as draft_year,
	coalesce(t.draft_round,
	y.draft_round) as draft_round,
	coalesce(t.draft_number,
	y.draft_number) as draft_number,
	case
		when y.season_stats is null then array[row(t.season,
		t.gp,
		t.pts,
		t.reb,
		t.ast)::season_stats]
		when t.season is not null then y.season_stats || array[row(t.season,
		t.gp,
		t.pts,
		t.reb,
		t.ast)::season_stats]
		else y.season_stats
	end as season_stats,
	coalesce(t.season, y.current_season + 1) as current_season

from
	today t
full outer join yesterday y on
	t.player_name = y.player_name

-- At this point we have the first season, and one player per season
select * from players p

-- Now, we gonna run the cummulation:

insert into players
with yesterday as (

select * from players where current_season = 1996 -- we change the value to the next season

), today as (

select * from player_seasons ps where season = 1997

)

select
	coalesce(t.player_name,
	y.player_name) as player_name,
	coalesce(t.country, y.country) as country,
	coalesce(t.height,
	y.height) as height,
	coalesce(t.college,
	y.college) as college,
	coalesce(t.draft_year,
	y.draft_year) as draft_year,
	coalesce(t.draft_round,
	y.draft_round) as draft_round,
	coalesce(t.draft_number,
	y.draft_number) as draft_number,
	case
		when y.season_stats is null then array[row(t.season,
		t.gp,
		t.pts,
		t.reb,
		t.ast)::season_stats]
		when t.season is not null then y.season_stats || array[row(t.season,
		t.gp,
		t.pts,
		t.reb,
		t.ast)::season_stats]
		else y.season_stats
	end as season_stats,
	coalesce(t.season, y.current_season + 1) as current_season

from
	today t
full outer join yesterday y on
	t.player_name = y.player_name


select * from players where current_season = 1997 -- at this point, we have season stats for a couple of years, for players that played 2 seasons, but only one for the onas that have joined in the current year


-- we will add until 2011

insert into players
with yesterday as (

select * from players where current_season = 2000 -- we change the value to the next season

), today as (

select * from player_seasons ps where season = 2001

)

select
	coalesce(t.player_name,
	y.player_name) as player_name,
	coalesce(t.country, y.country) as country,
	coalesce(t.height,
	y.height) as height,
	coalesce(t.college,
	y.college) as college,
	coalesce(t.draft_year,
	y.draft_year) as draft_year,
	coalesce(t.draft_round,
	y.draft_round) as draft_round,
	coalesce(t.draft_number,
	y.draft_number) as draft_number,
	case
		when y.season_stats is null then array[row(t.season,
		t.gp,
		t.pts,
		t.reb,
		t.ast)::season_stats]
		when t.season is not null then y.season_stats || array[row(t.season,
		t.gp,
		t.pts,
		t.reb,
		t.ast)::season_stats]
		else y.season_stats
	end as season_stats,
	coalesce(t.season, y.current_season + 1) as current_season

from
	today t
full outer join yesterday y on
	t.player_name = y.player_name


-- i.e, we know tht Michael Jordan had a gap in his career, we should see that

select * from players where player_name = 'Michael Jordan' and current_season = 2001


-- Now, we are also able to turn this table back into player_season table, using UNNEST

select
	player_name,
	unnest(season_stats)::season_stats as seasons_stats
from
	players p
where
	current_season = 2001
	and player_name = 'Michael Jordan'


-- More cool stuff

-- cardinality(season_stats) return the number of elements in the array season stats
-- so season_stats[cardinality(season_stats)] returns the element in the last position,
-- similarly as we do season_stats[1] to get the first element. common index accessing in arrays
select
	player_name,
	season_stats[1]::season_stats as first_season,
	season_stats[cardinality(season_stats)] as latest_season
from
	players
where
	current_season = 2001

-- Now we get onlyy the points of the first season
select
	player_name,
	season_stats[1].pts as first_season_points,
	season_stats[cardinality(season_stats)].pts as latest_season_points
from
	players
where
	current_season = 2001

-- we want to know the improvement a player did from first season to last season
-- so we divide last season points with the first one
-- dividing this values gives us a metric of improvement

-- The power of this query is that it does not have any group by, no agregation etc... it's insanely fast

select
	player_name,
	season_stats[cardinality(season_stats)].pts / case
		when season_stats[1].pts = 0 then 1
		else season_stats[1].pts
	end

from
	players
where
	current_season = 2001
order by 2 desc












