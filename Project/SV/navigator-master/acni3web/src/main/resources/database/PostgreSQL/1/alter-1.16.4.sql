-- alter function template
-- change _expectedVersion and _newVersion when you create new script
-- _expectedVersion: version of database on which this script should be launched
-- _newVersion: new version of database, that will be applied to sys_iam table after successfull run of script
CREATE OR REPLACE FUNCTION alterDatabase()
 RETURNS void AS $$
DECLARE 
	_expectedVersion varchar = '1.16.3';
	_newVersion varchar = '1.16.4';
	_version varchar;
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

alter table sys_report_template add column schemaid integer;
alter table sys_report_template add constraint fk_sys_report_template_sys_schema foreign key (schemaid) references sys_schema (id);

insert into sys_user_language values (1, 'ReportAdministration', 'Report Administration');
insert into sys_user_language values (1, 'MsgEnterNameOfNewReportTemplate', 'Please enter name of a new report template');
insert into sys_user_language values (1, 'MsgDuplicateReportTemplateName', 'Duplicate report template name: `{1}`');
insert into sys_user_language values (1, 'NewReportTemplate', 'New report template');

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