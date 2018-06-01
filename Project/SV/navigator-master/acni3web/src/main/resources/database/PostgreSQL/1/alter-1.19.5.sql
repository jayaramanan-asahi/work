-- alter function template
-- change _expectedVersion and _newVersion when you create new script
-- _expectedVersion: version of database on which this script should be launched
-- _newVersion: new version of database, that will be applied to sys_iam table after successfull run of script
CREATE OR REPLACE FUNCTION alterDatabase()
 RETURNS void AS $$
DECLARE 
	_expectedVersion varchar = '1.19.4';
	_newVersion varchar = '1.19.5';
	_version varchar;
	fixedAttributes varchar(255)[];
BEGIN
	-- check version
	select version into _version from sys_iam where name = 'PostgreSQL';

	if (_version != _expectedVersion) then
		raise exception 'Wrong database version: expected - %, but was %', _expectedVersion, _version;
	elsif (_version = _newVersion) then
		raise exception 'New database version should differ from current : %', _version;
	end if;

	raise info 'Version check completed';

	fixedAttributes = ARRAY[
		'Directed',
		'ConnectionType',
		'FromID',
		'ToID'
	];
------------------------------------------------------------

for i in array_lower(fixedAttributes,1) .. array_upper(fixedAttributes,1) loop
	update sys_object_attributes oa set dbdatatypeid = 106 where oa.dbdatatypeid is null and oa.datatypeid = 2 and oa.name ilike fixedAttributes[i];
end loop;

------------------------------------------------------------------
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