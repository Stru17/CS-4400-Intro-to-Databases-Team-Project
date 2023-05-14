-- CS4400: Introduction to Database Systems (Fall 2022)
-- Project Phase III: Stored Procedures SHELL [v2] Monday, Oct 31, 2022
-- Selected version: Version 2
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

use restaurant_supply_express;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [1] add_owner()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new owner.  A new owner must have a unique
username.  Also, the new owner is not allowed to be an employee. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_owner;
delimiter //
create procedure add_owner (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date, out result varchar(500))
sp_main: begin
    -- ensure new owner has a unique username
    if (select count(*) from users where ip_username = username) > 0 then 
		set result = 'Username already taken!';
    leave sp_main; end if;
	insert users
    values (ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate);
    
    insert restaurant_owners
    values (ip_username);
    
    set result = 'Success';
end //
delimiter ;

-- [2] add_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new employee without any designated pilot or
worker roles.  A new employee must have a unique username unique tax identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_employee;
delimiter //
create procedure add_employee (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date,
    in ip_taxID varchar(40), in ip_hired date, in ip_employee_experience integer,
    in ip_salary integer, out result varchar(500))
sp_main: begin
	-- ensure tax_id is valid
    if ip_taxID not like '___-__-____' then 
		set result = 'Tax ID not valid!';
    leave sp_main; end if;
    -- ensure new owner has a unique username
    if exists (SELECT * FROM restaurant_owners WHERE username = ip_username)
    then 
		set result = 'Username already exists for an owner!';
    leave sp_main; end if;
    if exists (SELECT * FROM employees WHERE username = ip_username)
    then 
		set result = 'Username already exists for an employee!';
    leave sp_main; end if;
    -- ensure new employee has a unique tax identifier
    if exists (SELECT * FROM employees WHERE taxID = ip_taxID)
    then 
		set result = 'Tax ID already exists for an employee!';
    leave sp_main; end if;  
    if not exists (SELECT * FROM users WHERE username = ip_username)
    then insert into users values(ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate); end if;
    
    insert into employees values(ip_username, ip_taxID, ip_hired, ip_employee_experience, ip_salary);
    set result = 'Success';
end //
delimiter ;

-- [3] add_pilot_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the pilot role to an existing employee.  The
employee/new pilot must have a unique license identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_pilot_role;
delimiter //
create procedure add_pilot_role (in ip_username varchar(40), in ip_licenseID varchar(40),
	in ip_pilot_experience integer, out result varchar(500))
sp_main: begin
    -- ensure new employee exists
    if not exists (SELECT * FROM employees WHERE username = ip_username)
    then 
		set result = 'Employee username does not exist!';
    leave sp_main; end if; 
    -- ensure that user is not already a pilot
    if exists (SELECT * FROM pilots WHERE username = ip_username) then
		set result = 'Employee is already a pilot!';
	leave sp_main; end if;
    -- ensure new pilot has a unique license identifier
    if exists (SELECT * FROM pilots WHERE licenseID = ip_licenseID)
    then 
		set result = 'License ID is is not unique!';
    leave sp_main; end if; 
    
    insert pilots values(ip_username, ip_licenseID, ip_pilot_experience);
    set result = 'Success';
end //
delimiter ;

-- [4] add_worker_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the worker role to an existing employee. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_worker_role;
delimiter //
create procedure add_worker_role (in ip_username varchar(40), out result varchar(500))
sp_main: begin
    -- ensure employee exists
    	if not exists (SELECT * FROM employees WHERE username = ip_username)
		then 
			set result = 'Employee username does not exist!';
        leave sp_main; end if;
	-- ensure employee is not already a worker
		if exists (SELECT * FROM workers WHERE username = ip_username)
		then 
			set result = 'Employee is already a worker!';
        leave sp_main; end if;
	-- add the worker role
        insert into workers VALUES (ip_username);
        set result = 'Success';
end //
delimiter ;

-- [5] add_ingredient()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new ingredient.  A new ingredient must have a
unique barcode. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_ingredient;
delimiter //
create procedure add_ingredient (in ip_barcode varchar(40), in ip_iname varchar(100),
	in ip_weight integer, out result varchar(500))
sp_main: begin
	-- ensure new ingredient doesn't already exist
	if exists (SELECT * FROM ingredients WHERE barcode = ip_barcode)
    then 
		set result = 'Ingredient barcode already exists';
    leave sp_main; end if;
    
    insert into ingredients values(ip_barcode, ip_iname, ip_weight);
    set result = 'Success';
end //
delimiter ;

-- [6] add_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new drone.  A new drone must be assigned 
to a valid delivery service and must have a unique tag.  Also, it must be flown
by a valid pilot initially (i.e., pilot works for the same service), but the pilot
can switch the drone to working as part of a swarm later. And the drone's starting
location will always be the delivery service's home base by default. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_drone;
delimiter //
create procedure add_drone (in ip_id varchar(40), in ip_tag integer, in ip_fuel integer,
	in ip_capacity integer, in ip_sales integer, in ip_flown_by varchar(40), out result varchar(500))
sp_main: begin
	-- ensure new drone doesn't already exist
	if exists (SELECT * FROM drones WHERE id = ip_id and tag = ip_tag)
    then set result = 'New drone already exists'; leave sp_main; end if;
    
    -- ensure that the delivery service exists
	if not exists (SELECT * FROM delivery_services WHERE id = ip_id)
    then set result = 'Delivery service does not exist'; leave sp_main; end if;
    
    -- ensure that a valid pilot will control the drone
    if not exists (SELECT * FROM work_for WHERE username = ip_flown_by and id = ip_id) or not exists (SELECT * FROM pilots WHERE username = ip_flown_by)
    then set result = 'A valid pilot is not controlling drone'; leave sp_main; end if;
    
    set @homebase = (SELECT home_base FROM delivery_services WHERE id = ip_id);
    
    insert into drones values (ip_id, ip_tag, ip_fuel, ip_capacity, ip_sales, ip_flown_by, NULL, NULL, @homebase);
    set result = 'Success';
end //
delimiter ;

-- [7] add_restaurant()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new restaurant.  A new restaurant must have a
unique (long) name and must exist at a valid location, and have a valid rating.
And a resturant is initially "independent" (i.e., no owner), but will be assigned
an owner later for funding purposes. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_restaurant;
delimiter //
create procedure add_restaurant (in ip_long_name varchar(40), in ip_rating integer,
	in ip_spent integer, in ip_location varchar(40), out result varchar(400))
sp_main: begin
	-- ensure new restaurant doesn't already exist
    if exists (SELECT * FROM restaurants WHERE long_name = ip_long_name)
    then 
		set result = 'Restaurant name already taken!';
    leave sp_main; end if;
    -- ensure that the location is valid
    if not exists (SELECT * FROM locations WHERE label = ip_location)
    then 
		set result = 'Location does not exist';
    leave sp_main; end if;
    -- ensure that the rating is valid (i.e., between 1 and 5 inclusively)
    if not (ip_rating >= 1 and ip_rating <= 5) then 
		set result = 'Rating must be between 1 and 5 inclusive!';
    leave sp_main; end if;
    
    insert into restaurants values (ip_long_name, ip_rating, ip_spent, ip_location, NULL);
    set result = 'Success';
end //
delimiter ;

-- [8] add_service()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new delivery service.  A new service must have
a unique identifier, along with a valid home base and manager. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_service;
delimiter //
create procedure add_service (in ip_id varchar(40), in ip_long_name varchar(100),
	in ip_home_base varchar(40), in ip_manager varchar(40), out result varchar(500))
sp_main: begin
	-- ensure new delivery service doesn't already exist
    if exists (SELECT * FROM delivery_services WHERE id = ip_id)
    then
    set result ='Delivery service already exists';
    leave sp_main; end if;
    -- ensure that the home base location is valid
    if not exists (SELECT * FROM locations WHERE label = ip_home_base)
    then set result = 'Home base location is not valid'; leave sp_main; end if;
    -- ensure that the manager is valid
    if not exists (SELECT * FROM workers WHERE username = ip_manager)
    then set result = 'Manager is not valid';leave sp_main; end if;
    -- ensure that the worker is not already a manager
    if ip_manager in (select manager from delivery_services) then set result = 'Worker is already a manager!';leave sp_main; end if;
    
    insert into delivery_services values(ip_id, ip_long_name, ip_home_base, ip_manager);
    
    set result = 'Success';
end //
delimiter ;

-- [9] add_location()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new location that becomes a new valid drone
destination.  A new location must have a unique combination of coordinates.  We
could allow for "aliased locations", but this might cause more confusion that
it's worth for our relatively simple system. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_location;
delimiter //
create procedure add_location (in ip_label varchar(40), in ip_x_coord integer,
	in ip_y_coord integer, in ip_space integer, out result varchar(500))
sp_main: begin
	-- ensure new location doesn't already exist
    if ip_label in (select label from locations) 
    then 
		set result = 'Location already exists!';
    leave sp_main; end if;
    -- ensure that the coordinate combination is distinct
    if (select count(*) from locations where x_coord = ip_x_coord and y_coord = ip_y_coord) > 0 
    then 
		set result = 'Coordinates combination is not distinct!';
    leave sp_main; end if;
    
    insert locations
    values (ip_label, ip_x_coord, ip_y_coord, ip_space);
    set result = 'Success';
end //
delimiter ;

-- [10] start_funding()
-- -----------------------------------------------------------------------------
/* This stored procedure opens a channel for a restaurant owner to provide funds
to a restaurant. If a different owner is already providing funds, then the current
owner is replaced with the new owner.  The owner and restaurant must be valid. */
-- -----------------------------------------------------------------------------
drop procedure if exists start_funding;
delimiter //
create procedure start_funding (in ip_owner varchar(40), in ip_long_name varchar(40), out result varchar(500))
sp_main: begin
	-- ensure the owner and restaurant are valid
    if ip_long_name not in (select long_name from restaurants) then 
    set result = 'Restaurant does not exist';
    leave sp_main; end if;
    if ip_owner not in (select username from restaurant_owners) then
    set result = 'Owner does not exist';
    leave sp_main; end if;
    -- ensure the owner is not already funding the restaurant
    if exists (select * from restaurants where long_name = ip_long_name and ip_owner = funded_by) then
    set result = 'Owner is already funding this restaurant';
    leave sp_main; end if;
   
    update restaurants
    set funded_by = ip_owner
    where long_name = ip_long_name;
    set result = 'Success';
end //
delimiter ;

-- [11] hire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure hires an employee to work for a delivery service.
Employees can be combinations of workers and pilots. If an employee is actively
controlling drones or serving as manager for a different service, then they are
not eligible to be hired.  Otherwise, the hiring is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists hire_employee;
delimiter //
create procedure hire_employee (in ip_username varchar(40), in ip_id varchar(40), out result varchar(500))
sp_main: begin
	-- ensure that the employee hasn't already been hired
    if exists (SELECT * FROM work_for WHERE username = ip_username and id = ip_id)
    then 
		set result = 'Employee has already been hired!';
    leave sp_main; end if;
	-- ensure that the employee and delivery service are valid
    if not exists (SELECT * FROM employees WHERE username = ip_username)
    then 
		set result = 'Employee username does not exist!';
    leave sp_main; end if;
    if not exists (SELECT * FROM delivery_services WHERE id = ip_id)
    then 
		set result = 'Delivery Service ID does not exist!';
    leave sp_main; end if;
    -- ensure that the employee isn't a manager for another service
    if exists (SELECT * FROM delivery_services WHERE manager = ip_username)
    then 
		set result = 'Employee is a manager for another service!';
    leave sp_main; end if;
	-- ensure that the employee isn't actively controlling drones for another service
    if exists (SELECT * FROM drones WHERE flown_by = ip_username AND id <> ip_id)
    then 
		set result = 'Employee is currently controlling drones for another service!';
    leave sp_main; end if;
    
    insert work_for values(ip_username, ip_id);
    set result = 'Success';
end //
delimiter ;

-- [12] fire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure fires an employee who is currently working for a delivery
service.  The only restrictions are that the employee must not be: [1] actively
controlling one or more drones; or, [2] serving as a manager for the service.
Otherwise, the firing is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists fire_employee;
delimiter //
create procedure fire_employee (in ip_username varchar(40), in ip_id varchar(40), out result varchar(500))
sp_main: begin
	-- ensure that the employee is currently working for the service
    if not exists (SELECT * FROM work_for WHERE username = ip_username and id = ip_id)
    then 
		set result = 'Employee does not work at this service!';
    leave sp_main; end if;
    -- ensure that the employee isn't an active manager
    if exists (SELECT * FROM delivery_services WHERE manager = ip_username and id = ip_id)
    then 
		set result = 'Employee is an active manager for this service!';
    leave sp_main; end if;
	-- ensure that the employee isn't controlling any drones
    if exists (SELECT * FROM drones WHERE flown_by = ip_username AND id = ip_id)
    -- if exists (SELECT * FROM drones WHERE flown_by = ip_username AND ip = ip_id)
    then 
		set result = 'Employee is currently controlling at least one drone!';
    leave sp_main; end if;
    
    DELETE FROM work_for WHERE username = ip_username and id = ip_id;
    set result = 'Success';
end //
delimiter ;

-- [13] manage_service()
-- -----------------------------------------------------------------------------
/* This stored procedure appoints an employee who is currently hired by a delivery
service as the new manager for that service.  The only restrictions are that: [1]
the employee must not be working for any other delivery service; and, [2] the
employee can't be flying drones at the time.  Otherwise, the appointment to manager
is permitted.  The current manager is simply replaced.  And the employee must be
granted the worker role if they don't have it already. */
-- -----------------------------------------------------------------------------
drop procedure if exists manage_service;
delimiter //
create procedure manage_service (in ip_username varchar(40), in ip_id varchar(40), out result varchar(500))
sp_main: begin
	-- ensure that the employee is currently working for the service
    if ip_username not in (select username from work_for where id = ip_id) then
    set result = 'Employee is not working for the service';
    leave sp_main; end if;
	-- ensure that the employee is not flying any drones
    if ip_username in (select flown_by from drones) then
    set result = 'Employee is flying other drones';
    leave sp_main; end if;
    -- ensure that the employee isn't working for any other services
    if ip_username in (select username from work_for where id <> ip_id) then
    set result = 'Employee is working for other services';
    leave sp_main; end if;
    -- add the worker role if necessary
    if ip_username not in (select username from workers) then
		insert workers
        values (ip_username);
	end if;
    
    update delivery_services
    set manager = ip_username
    where id = ip_id;
    
    set result = 'Success';
end //
delimiter ;

-- [14] takeover_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a valid pilot to take control of a lead drone owned
by the same delivery service, whether it's a "lone drone" or the leader of a swarm.
The current controller of the drone is simply relieved of those duties. And this
should only be executed if a "leader drone" is selected. */
-- -----------------------------------------------------------------------------
drop procedure if exists takeover_drone;
delimiter //
create procedure takeover_drone (in ip_username varchar(40), in ip_id varchar(40),
	in ip_tag integer, out result varchar(500))
sp_main: begin
	-- ensure that the employee is currently working for the service
    if ip_username not in (select username from work_for where id = ip_id) then 
		set result = 'Employee is not working for the drone\'s service';
    leave sp_main; end if;
    
	-- ensure that the selected drone is owned by the same service and is a leader and not follower
    -- if not (ip_id, ip_tag) in (select id, tag from drones where flown_by is not null) then leave sp_main; end if;
	if not exists (select * from drones where flown_by is not null and id = ip_id and tag = ip_tag) then 
		set result = 'Drone is not a lone drone or leader drone';
    leave sp_main; end if;
    
	-- ensure that the employee isn't a manager
    if ip_username in (select manager from delivery_services) then 
		set result = 'Employee is an manager!';
    leave sp_main; end if;
    
    -- ensure that the employee is a valid pilot
    if not ip_username in (select username from pilots) then 
		set result = 'Employee is not a valid pilot!';
    leave sp_main; end if;
    
    update drones
    set flown_by = ip_username
    where id = ip_id and tag = ip_tag;
    
    set result = 'Success';
end //
delimiter ;

-- [15] join_swarm()
-- -----------------------------------------------------------------------------
/* This stored procedure takes a drone that is currently being directly controlled
by a pilot and has it join a swarm (i.e., group of drones) led by a different
directly controlled drone. A drone that is joining a swarm connot be leading a
different swarm at this time.  Also, the drones must be at the same location, but
they can be controlled by different pilots. */
-- -----------------------------------------------------------------------------
drop procedure if exists join_swarm;
delimiter //
create procedure join_swarm (in ip_id varchar(40), in ip_tag integer,
	in ip_swarm_leader_tag integer, out result varchar(500))
sp_main: begin
	-- ensure that the swarm leader is a different drone
    if ip_tag = ip_swarm_leader_tag then 
		set result = 'The drone is already part of the swarm!';
    leave sp_main; end if;
    
    -- ensure that the drone is not already part of the swarm leader
    if exists (select * from drones where id = ip_id and tag = ip_tag and swarm_tag = ip_swarm_leader_tag) then
		set result = 'The drone is already part of the swarm!';
    leave sp_main; end if;
    
	-- ensure that the drone joining the swarm is valid and owned by the service
    if (select count(*) from drones where id = ip_id and tag = ip_tag) = 0 then 
		set result = 'Swarm leader does not exist!';
    leave sp_main; end if;
        
    -- ensure that the drone joining the swarm is not already leading a swarm
    if (select count(*) from drones where swarm_id = ip_id and swarm_tag = ip_tag) != 0 then 
		set result = 'The drone is leading a swarm!';
    leave sp_main; end if;

	-- ensure that the swarm leader drone is directly controlled
    if (select flown_by from drones where id = ip_id and tag = ip_swarm_leader_tag) IS NULL then 
		set result = 'The swarm leader is not directly controlled!';
    leave sp_main; end if;
    
	-- ensure that the drones are at the same location
    if (select hover from drones where id = ip_id and tag = ip_tag) != (select hover from drones where id = ip_id and tag = ip_swarm_leader_tag) then 
		set result = 'The drone is not at the same location as the swarm!';
    leave sp_main; end if;
    
	update drones
	set flown_by = NULL, swarm_id = ip_id, swarm_tag = ip_swarm_leader_tag
	where id = ip_id and tag = ip_tag;
    
    set result = 'Success';
end //
delimiter ;

-- [16] leave_swarm()
-- -----------------------------------------------------------------------------
/* This stored procedure takes a drone that is currently in a swarm and returns
it to being directly controlled by the same pilot who's controlling the swarm. */
-- -----------------------------------------------------------------------------
drop procedure if exists leave_swarm;
delimiter //
create procedure leave_swarm (in ip_id varchar(40), in ip_swarm_tag integer, out result varchar(500))
sp_main: begin
    declare temp_flown varchar(40);
    set temp_flown = (select flown_by from drones where id = ip_id and tag = (select swarm_tag from drones where id = ip_id and tag = ip_swarm_tag));
    
    -- ensure the drone exists
    if not exists (select * from drones where id = ip_id and tag = ip_swarm_tag) then
    set result = 'Drone is not found!';
    leave sp_main; end if;
    
	-- ensure that the selected drone is owned by the service and flying in a swarm
	-- if (select count(*) from drones where id = ip_id and tag = ip_swarm_tag) = 0 then leave sp_main; end if;
	if (select count(flown_by) from drones where id = ip_id and tag = ip_swarm_tag) = 1 then
    set result = 'Selected drone is not owned by service or flying in a swarm';
    leave sp_main; end if;
    
    update drones
    set flown_by = temp_flown, swarm_id = NULL, swarm_tag = NULL
    where id = ip_id and tag = ip_swarm_tag;
    
    set result = 'Success';
end //
delimiter ;

-- [17] load_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add some quantity of fixed-size packages of
a specific ingredient to a drone's payload so that we can sell them for some
specific price to other restaurants.  The drone can only be loaded if it's located
at its delivery service's home base, and the drone must have enough capacity to
carry the increased number of items.

The change/delta quantity value must be positive, and must be added to the quantity
of the ingredient already loaded onto the drone as applicable.  And if the ingredient
already exists on the drone, then the existing price must not be changed. */
-- -----------------------------------------------------------------------------
drop procedure if exists load_drone;
delimiter //
create procedure load_drone (in ip_id varchar(40), in ip_tag integer, in ip_barcode varchar(40),
	in ip_more_packages integer, in ip_price integer, out result varchar(500))
sp_main: begin
-- ensure that the drone being loaded is owned by the service
    if (select count(*) from drones where id = ip_id and tag = ip_tag) = 0 then
    set result = 'Drone is not owned by service';
    leave sp_main; end if;
    
	-- ensure that the ingredient is valid
    if not ip_barcode in (select barcode from ingredients) then set result = 'Ingredient is not valid'; leave sp_main; end if;
    
    -- ensure that the drone is located at the service home base
    if (select hover from drones where id = ip_id and tag = ip_tag) != (select home_base from delivery_services where id = ip_id) then
    set result = 'Drone is not located at service home base';
    leave sp_main; end if;
    
	-- ensure that the quantity of new packages is greater than zero
    if ip_more_packages <= 0 then
    set result = 'The quantity of new packages is < 0';
    leave sp_main; end if;
    
	-- ensure that the drone has sufficient capacity to carry the new packages
    set @capacity = (select capacity from drones where id = ip_id and tag = ip_tag);
    set @currSize = (select sum(quantity) from payload where id = ip_id and tag = ip_tag);
    if (@currSize + ip_more_packages > @capacity) then
    set result = 'Drone does not have sufficient capacity';
    leave sp_main; end if;
    
    -- add more of the ingredient to the drone
	if (select count(*) from payload where id = ip_id and tag = ip_tag and barcode = ip_barcode) != 0 then 
    update payload 
    set quantity = quantity + ip_more_packages 
    where id = ip_id and tag = ip_tag and barcode = ip_barcode; end if;
    
    if (select count(*) from payload where id = ip_id and tag = ip_tag and barcode = ip_barcode) = 0 then 
    insert into payload 
    values (ip_id, ip_tag, ip_barcode, ip_more_packages, ip_price); end if;
    
    set result = 'Success';
end //
delimiter ;

-- [18] refuel_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add more fuel to a drone. The drone can only
be refueled if it's located at the delivery service's home base. */
-- -----------------------------------------------------------------------------
drop procedure if exists refuel_drone;
delimiter //
create procedure refuel_drone (in ip_id varchar(40), in ip_tag integer, in ip_more_fuel integer, out result varchar(500))
sp_main: begin
	-- ensure that the drone being switched is valid and owned by the service
    if not exists (select * from drones where tag = ip_tag and id = ip_id) then 
    set result = 'Drone is not valid';
    leave sp_main; end if;
    
    -- ensure that the drone is located at the service home base
    if (select hover as temp from drones where id = ip_id and tag = ip_tag) <> (select home_base as temp from delivery_services where id = ip_id) then
    set result = 'Drone is not located at service home base';
    leave sp_main; end if;
    
    update drones
    set fuel = fuel + ip_more_fuel
    where id = ip_id and tag = ip_tag;
    
    set result = 'Success';
end //
delimiter ;

-- [19] fly_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to move a single or swarm of drones to a new
location (i.e., destination). The main constraints on the drone(s) being able to
move to a new location are fuel and space.  A drone can only move to a destination
if it has enough fuel to reach the destination and still move from the destination
back to home base.  And a drone can only move to a destination if there's enough
space remaining at the destination.  For swarms, the flight directions will always
be given to the lead drone, but the swarm must always stay together. */
-- -----------------------------------------------------------------------------
drop function if exists fuel_required;
delimiter //
create function fuel_required (ip_departure varchar(40), ip_arrival varchar(40))
	returns integer reads sql data
begin
	if (ip_departure = ip_arrival) then return 0;
    else return (select 1 + truncate(sqrt(power(arrival.x_coord - departure.x_coord, 2) + power(arrival.y_coord - departure.y_coord, 2)), 0) as fuel
		from (select x_coord, y_coord from locations where label = ip_departure) as departure,
        (select x_coord, y_coord from locations where label = ip_arrival) as arrival);
	end if;
end //
delimiter ;

drop procedure if exists fly_drone;
delimiter //
create procedure fly_drone (in ip_id varchar(40), in ip_tag integer, in ip_destination varchar(40), out result varchar(500))
sp_main: begin
	declare droneCount, fuelToDest, fuelToHome integer;
    set droneCount = (select count(*) from drones where (id = ip_id and tag = ip_tag) or (swarm_id = ip_id and swarm_tag = ip_tag));
    set fuelToDest = (select fuel_required(hover, ip_destination) from drones where id = ip_id and tag = ip_tag);
    set @homeBase = (select home_base from delivery_services where id = ip_id);
    set fuelToHome = (select fuel_required(ip_destination, @homebase));

	-- ensure that the lead drone being flown is directly controlled and owned by the service
    if (select count(flown_by) from drones where id = ip_id and tag = ip_tag) = 0 then
    set result = 'Lead drone is not controlled or owned by the service';
    leave sp_main; end if;
    
    -- ensure that the destination is a valid location
	if not ip_destination in (select label from locations) then
    set result = 'Destination is not valid location';
    leave sp_main; end if;
    
    -- ensure that the drone isn't already at the location
    if (select hover from drones where id = ip_id and tag = ip_tag) = ip_destination then
    set result = 'Drone is already at the location';
    leave sp_main; end if;
    
    -- ensure that the drone/swarm has enough fuel to reach the destination and (then) home base    
    if (select count(*) from drones where (id = ip_id and tag = ip_tag) or (swarm_id = ip_id and swarm_tag = ip_tag)) != (select sum(fuel >= fuelToDest + fuelToHome) 
    from drones where (id = ip_id and tag = ip_tag) or (swarm_id = ip_id and swarm_tag = ip_tag)) then
	set result = 'Drone does not have fuel to reach destination';
    leave sp_main; end if;
        
    -- ensure that the drone/swarm has enough space at the destination for the flight
    set @locationSpace = (select space from locations where label = ip_destination);
    if droneCount > @locationSpace then
        set result = 'There is not enough space at the destination for the flight';
    leave sp_main; end if;
    
    update drones
    set hover = ip_destination, fuel = fuel - fuelToDest
    where (id = ip_id and tag = ip_tag) or (swarm_id = ip_id and swarm_tag = ip_tag);
    
    update locations
    set space = space - droneCount
    where label = ip_destination;
    set result = 'Success';
end //
delimiter ;

-- [20] purchase_ingredient()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a restaurant to purchase ingredients from a drone
at its current location.  The drone must have the desired quantity of the ingredient
being purchased.  And the restaurant must have enough money to purchase the
ingredients.  If the transaction is otherwise valid, then the drone and restaurant
information must be changed appropriately.  Finally, we need to ensure that all
quantities in the payload table (post transaction) are greater than zero. */
-- -----------------------------------------------------------------------------
drop procedure if exists purchase_ingredient;
delimiter //
create procedure purchase_ingredient (in ip_long_name varchar(40), in ip_id varchar(40),
	in ip_tag integer, in ip_barcode varchar(40), in ip_quantity integer, out result varchar(500))
sp_main: begin
	-- ensure that the restaurant is valid
    if not exists (select * from restaurants where long_name = ip_long_name) then
		set result = 'Restaurant does not exist';
    leave sp_main; end if;
    -- ensure that the drone is valid and exists at the resturant's location
    if not exists (select * from drones where id = ip_id and tag = ip_tag and hover = (select location from restaurants where long_name = ip_long_name)) then 
		set result = 'Drone does not exist or is not at the restaurant\'s location';
    leave sp_main; end if;
	-- ensure that the drone has enough of the requested ingredient
    set @quantity = (select quantity from payload where id = ip_id and tag = ip_tag and barcode = ip_barcode);
    if ip_quantity > coalesce(@quantity, 0) then 
		set result = 'Drones does not have enough of the request ingredient';
    leave sp_main; end if;
	
    set @price = (select price from payload where id = ip_id and tag = ip_tag and barcode = ip_barcode);
    -- update the drone's payload
    -- update the monies spent and gained for the drone and restaurant
    -- ensure all quantities in the payload table are greater than zero
    update payload
    set quantity = quantity - ip_quantity
    where id = ip_id and tag = ip_tag and barcode = ip_barcode;
    
    update drones
    set sales = sales + @price * ip_quantity
    where id = ip_id and tag = ip_tag;
    
    update restaurants
    set spent = spent + @price * ip_quantity
    where long_name = ip_long_name;
    
    set result = 'Success';
end //
delimiter ;

-- [21] remove_ingredient()
-- -----------------------------------------------------------------------------
/* This stored procedure removes an ingredient from the system.  The removal can
occur if, and only if, the ingredient is not being carried by any drones. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_ingredient;
delimiter //
create procedure remove_ingredient (in ip_barcode varchar(40), out result varchar(400))
sp_main: begin
	-- ensure that the ingredient exists
    if not exists (SELECT * FROM ingredients WHERE barcode = ip_barcode)
    then 
		set result = 'Ingredient barcode was not found';
    leave sp_main; end if;
    -- ensure that the ingredient is not being carried by any drones
    -- GET THE PAYLOAD HERE
    if exists (SELECT * FROM payload where barcode = ip_barcode)
    then 
		set result = 'Ingredient cannot be removed (drones are carrying it)';
    leave sp_main; end if;
    
    -- does the actual deleting
    DELETE FROM ingredients where barcode = ip_barcode;
    set result = 'Success';
end //
delimiter ;

-- [22] remove_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a drone from the system.  The removal can
occur if, and only if, the drone is not carrying any ingredients, and if it is
not leading a swarm. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_drone;
delimiter //
create procedure remove_drone (in ip_id varchar(40), in ip_tag integer, out result varchar(500))
sp_main: begin
	-- ensure that the drone exists
        if not exists (SELECT * FROM drones WHERE (ip_id = id and ip_tag = tag))
    then set result = 'Drone does not exist'; leave sp_main; end if;
    -- ensure that the drone is not carrying any ingredients, checking through payloads
    if exists (SELECT * FROM payload WHERE (ip_id = id and ip_tag = tag))
    then set result = 'Drone is carrying something!'; leave sp_main; end if;
	-- ensure that the drone is not leading a swarm TODO !!!!!!!!
    if exists (SELECT * FROM drones WHERE (ip_id = swarm_id and ip_tag = swarm_tag)) -- swarm id an
    then set result = 'Drone is leading a swarm! Cannot remove'; leave sp_main; end if;
    
    delete from drones where (ip_id = id and ip_tag = tag);
    
    set result = 'Success';
end //
delimiter ;

-- [23] remove_pilot_role()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a pilot from the system.  The removal can
occur if, and only if, the pilot is not controlling any drones.  Also, if the
pilot also has a worker role, then the worker information must be maintained;
otherwise, the pilot's information must be completely removed from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_pilot_role;
delimiter //
create procedure remove_pilot_role (in ip_username varchar(40), out result varchar(500))
sp_main: begin
	-- ensure that the pilot exists
    if not exists (SELECT * FROM pilots WHERE username = ip_username)
    then 
		set result = 'Pilot username does not exist!';
    leave sp_main; end if;
    -- ensure that the pilot is not controlling any drones
    if exists (SELECT * FROM drones WHERE flown_by = ip_username)
    then 
		set result = 'Pilot is currently controlling at least one drone';
    leave sp_main; end if;
    
    DELETE FROM pilots WHERE username = ip_username;
    -- remove all remaining information unless the pilot is also a worker
    if not exists (SELECT * FROM workers WHERE username = ip_username) then 
		DELETE FROM work_for WHERE username = ip_username;
		DELETE FROM employees WHERE username = ip_username;
		DELETE FROM users WHERE username = ip_username; 
	end if;
    set result = 'Success';
end //
delimiter ;

-- [24] display_owner_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an owner.
For each owner, it includes the owner's information, along with the number of
restaurants for which they provide funds and the number of different places where
those restaurants are located.  It also includes the highest and lowest ratings
for each of those restaurants, as well as the total amount of debt based on the
monies spent purchasing ingredients by all of those restaurants. And if an owner
doesn't fund any restaurants then display zeros for the highs, lows and debt. */
-- -----------------------------------------------------------------------------
create or replace view display_owner_view as
select username, first_name, last_name, address, 
count(long_name) as num_restaurants, count(distinct location) as num_places, 
coalesce(max(rating), 0) as highs, coalesce(min(rating), 0) as lows, coalesce(sum(spent), 0) as debt
from restaurant_owners
natural join users 
left join restaurants on funded_by = username
group by username;

-- [25] display_employee_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an employee.
For each employee, it includes the username, tax identifier, hiring date and
experience level, along with the license identifer and piloting experience (if
applicable), and a 'yes' or 'no' depending on the manager status of the employee. */
-- -----------------------------------------------------------------------------
create or replace view display_employee_view as
select e.username as username, taxID, salary, hired, e.experience as employee_experience, 
coalesce(licenseID, 'n/a') as licenseID, coalesce(p.experience, 'n/a') as piloting_experience, 
case 
	when d.id IS NOT NULL then 'yes'
    else 'no'
end as manager_status
from employees as e
left join pilots as p on e.username = p.username
left join delivery_services as d on manager = e.username;

-- [26] display_pilot_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a pilot.
For each pilot, it includes the username, licenseID and piloting experience, along
with the number of drones that they are controlling. */
-- -----------------------------------------------------------------------------
create or replace view display_pilot_view as
select username, licenseID, experience, count(distinct swarm.tag) + count(distinct leader.tag) as num_drones, count(distinct leader.hover) as num_locations
from pilots
left join drones as leader on flown_by = username
left join drones as swarm on leader.id = swarm.swarm_id and leader.tag = swarm.swarm_tag
group by username;

-- [27] display_location_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a location.
For each location, it includes the label, x- and y- coordinates, along with the
number of restaurants, delivery services and drones at that location. */
-- -----------------------------------------------------------------------------
create or replace view display_location_view as
select locations.label as label, x_coord, y_coord, count(distinct r.long_name) as num_restaurants, 
count(distinct ds.id) as num_delivery_services, num_drones
from locations
left join restaurants as r on location = label
left join delivery_services as ds on label = home_base
left join (
select label, sum(count_per_service) as num_drones
from (select label, id, count(distinct tag) as count_per_service
from locations
left join drones on hover = label
group by label, id) as temp1
group by label) as temp2 on temp2.label = locations.label
group by label;



-- [28] display_ingredient_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of the ingredients.
For each ingredient that is being carried by at least one drone, it includes a list of
the various locations where it can be purchased, along with the total number of packages
that can be purchased and the lowest and highest prices at which the ingredient is being
sold at that location. */
-- -----------------------------------------------------------------------------
create or replace view display_ingredient_view as
select iname as ingredient_name, hover as location, sum(quantity) as amount_available, 
min(price) as low_price, max(price) as high_price
from ingredients as i
join payload as p on i.barcode = p.barcode
join drones as d on d.id = p.id and d.tag = p.tag
group by iname, hover
order by ingredient_name, location;

-- [29] display_service_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a delivery
service.  It includes the identifier, name, home base location and manager for the
service, along with the total sales from the drones.  It must also include the number
of unique ingredients along with the total cost and weight of those ingredients being
carried by the drones. */
-- -----------------------------------------------------------------------------
create or replace view display_service_view as
select id, long_name, home_base, manager, coalesce(sum(sales), 0) as sales, ingredients_carried, cost_carried, weight_carried
from delivery_services
natural left join drones
natural left join
(select id, count(distinct barcode) as ingredients_carried, 
coalesce(sum(price * quantity), 0) as cost_carried, coalesce(sum(weight * quantity), 0) as weight_carried 
from delivery_services 
natural left join drones
natural left join payload
natural left join ingredients
group by delivery_services.id) as temp
group by id;
