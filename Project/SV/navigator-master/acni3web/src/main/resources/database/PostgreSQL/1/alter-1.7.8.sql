-- alter function template
-- change _expectedVersion and _newVersion when you create new script
-- _expectedVersion: version of database on which this script should be launched
-- _newVersion: new version of database, that will be applied to sys_iam table after successfull run of script
CREATE OR REPLACE FUNCTION alterDatabase()
 RETURNS void AS $$
DECLARE 
	_expectedVersion varchar = '1.7.7';
	_newVersion varchar = '1.7.8';
	_version varchar;
	_cc integer;
BEGIN
	-- check version
	select version into _version from sys_iam where name = 'PostgreSQL';

	if (_version != _expectedVersion) then
		raise exception 'Wrong database version: expected - %, but was %', _expectedVersion, _version;
	elsif (_version = _newVersion) then
		raise exception 'New database version should differ from current : %', _version;
	end if;

	raise info 'Version check completed';
------------------------------------------------------------
select count(*) into _cc from sys_settings_application where prop = 'ObjectUpdateRights';
if(_cc = 0) then
	insert into sys_settings_application values ('Applet', 'ObjectUpdateRights', '3');
else
	update sys_settings_application set value = '3' where prop = 'ObjectUpdateRights';
end if;

select count(*) into _cc from sys_settings_application where prop = 'ObjectDeleteRights';
if(_cc = 0) then
	insert into sys_settings_application values ('Applet', 'ObjectDeleteRights', '3');
else
	update sys_settings_application set value = '3' where prop = 'ObjectDeleteRights';
end if;
------------------------------------------------------------
	raise info 'Database update script is completed';
	-- update database version to _newVersion
	update sys_iam set version=_newVersion where name = 'PostgreSQL';
	raise info 'Database version updated: % -> %', _version, _newVersion;
END;
$$ LANGUAGE plpgsql;


-- launch function
select alterDatabase();
-- drop function
drop function alterDatabase();