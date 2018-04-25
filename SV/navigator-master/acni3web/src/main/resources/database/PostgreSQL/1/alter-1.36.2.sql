-- alter function template
-- change _expectedVersion and _newVersion when you create new script
-- _expectedVersion: version of database on which this script should be launched
-- _newVersion: new version of database, that will be applied to sys_iam table after successfull run of script
CREATE OR REPLACE FUNCTION alterDatabase()
 RETURNS void AS $$
DECLARE 
	_expectedVersion varchar = '1.36.1';
	_newVersion varchar = '1.36.2';
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
	insert into sys_user_language (languageid, prop, value) values (1, 'XLS', 'XLS');
	insert into sys_user_language (languageid, prop, value) values (1, 'PDF', 'PDF');
	insert into sys_user_language (languageid, prop, value) values (1, 'Save as XLS', 'Save as XLS');
	insert into sys_user_language (languageid, prop, value) values (1, 'Save as PDF', 'Save as PDF');
------------------------------------------------------------
-- update dbversion in cis_favorites (comment this line if script impacts favorites)
update cis_favorites set dbversion = _newVersion where dbversion = _expectedVersion;
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

