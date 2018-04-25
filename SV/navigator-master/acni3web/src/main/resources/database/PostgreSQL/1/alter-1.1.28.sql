-- alter function template
-- change _expectedVersion and _newVersion when you create new script
-- _expectedVersion: version of database on which this script should be launched
-- _newVersion: new version of database, that will be applied to sys_iam table after successfull run of script
CREATE OR REPLACE FUNCTION alterDatabase()
 RETURNS void AS $$
DECLARE 
	_expectedVersion varchar = '1.1.27';
	_newVersion varchar = '1.1.28';
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
	select count(*) into _cc from sys_user_language where prop = 'AllwaysAsk';
	if(_cc = 0) then
		insert into sys_user_language(languageid, prop, value) values (1, 'AllwaysAsk', 'Allways ask');
	else
		update sys_user_language set value = 'Allways ask' where languageid = 1 and prop = 'AllwaysAsk';
	end if;
	
	select count(*) into _cc from sys_user_language where prop = 'TabSwitchAction';
	if(_cc = 0) then
		insert into sys_user_language(languageid, prop, value) values (1, 'TabSwitchAction', 'Tab switch default action');
	else
		update sys_user_language set value = 'Tab switch default action' where languageid = 1 and prop = 'TabSwitchAction';
	end if;

	select count(*) into _cc from sys_user_language where prop = 'NotSet';
	if(_cc = 0) then
		insert into sys_user_language(languageid, prop, value) values (1, 'NotSet', 'Not set');
	else
		update sys_user_language set value = 'Not set' where languageid = 1 and prop = 'NotSet';
	end if;
------------------------------------------------------------
	raise info 'Database update script is completed';
--	-- update database version to _newVersion
	update sys_iam set version=_newVersion where name = 'PostgreSQL';
	raise info 'Database version updated: % -> %', _version, _newVersion;
END;
$$ LANGUAGE plpgsql;


-- launch function
select alterDatabase();
-- drop function
drop function alterDatabase();
