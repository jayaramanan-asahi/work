-- alter function template
-- change _expectedVersion and _newVersion when you create new script
-- _expectedVersion: version of database on which this script should be launched
-- _newVersion: new version of database, that will be applied to sys_iam table after successfull run of script
CREATE OR REPLACE FUNCTION alterDatabase()
 RETURNS void AS $$
DECLARE 
	_expectedVersion varchar = '1.16.0';
	_newVersion varchar = '1.16.1';
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

alter table cht_datatype add column typeid integer default 0;

insert into cht_datatype (id, name, typeid) values (101, 'bool', 1);
insert into cht_datatype (id, name, typeid) values (102, 'bpchar', 1);
insert into cht_datatype (id, name, typeid) values (103, 'bytea', 1);
insert into cht_datatype (id, name, typeid) values (104, 'float', 1);
insert into cht_datatype (id, name, typeid) values (105, 'integer', 1);
insert into cht_datatype (id, name, typeid) values (106, 'numeric', 1);
insert into cht_datatype (id, name, typeid) values (107, 'text', 1);
insert into cht_datatype (id, name, typeid) values (108, 'timestamp', 1);
insert into cht_datatype (id, name, typeid) values (109, 'varchar', 1);

insert into cht_datatype (id, name, typeid) values (201, 'BLOB', 2);
insert into cht_datatype (id, name, typeid) values (202, 'CLOB', 2);
insert into cht_datatype (id, name, typeid) values (203, 'NUMBER', 2);
insert into cht_datatype (id, name, typeid) values (204, 'TIMESTAMP(6)', 2);
insert into cht_datatype (id, name, typeid) values (205, 'VARCHAR2', 2);
insert into cht_datatype (id, name, typeid) values (206, 'INT', 2);

insert into cht_datatype (id, name, typeid) values (301, 'bigint', 3);
insert into cht_datatype (id, name, typeid) values (302, 'bit', 3);
insert into cht_datatype (id, name, typeid) values (303, 'char', 3);
insert into cht_datatype (id, name, typeid) values (304, 'datetime', 3);
insert into cht_datatype (id, name, typeid) values (305, 'decimal', 3);
insert into cht_datatype (id, name, typeid) values (306, 'float', 3);
insert into cht_datatype (id, name, typeid) values (307, 'image', 3);
insert into cht_datatype (id, name, typeid) values (308, 'int', 3);
insert into cht_datatype (id, name, typeid) values (309, 'numeric', 3);
insert into cht_datatype (id, name, typeid) values (310, 'nvarchar', 3);
insert into cht_datatype (id, name, typeid) values (311, 'smallint', 3);
insert into cht_datatype (id, name, typeid) values (312, 'text', 3);
insert into cht_datatype (id, name, typeid) values (313, 'varbinary', 3);
insert into cht_datatype (id, name, typeid) values (314, 'varchar', 3);

alter table sys_object_attributes add column phys_datatypeid integer;

insert into sys_user_language values (1, 'PhysicalDatatype', 'Physical datatype');
insert into sys_user_language values (1, 'Length', 'Length');

update sys_object_attributes oa set phys_datatypeid = 
(select dt.id from cht_datatype dt, information_schema.tables o inner join information_schema.columns a on
	(o.table_catalog=a.table_catalog and o.table_schema=a.table_schema and o.table_name=a.table_name)
 where dt.name ilike a.udt_name and o.table_name ilike oa.inTable
	and lower(a.column_name) ilike oa.name and dt.typeid = 1);

CREATE OR REPLACE FUNCTION appendschematables(_schemaid bigint, _objectid bigint)
  RETURNS integer AS
$BODY$
    declare _timeStart timestamp;
	    _timeEnd timestamp; 
	    _timeTmp timestamp;
	    _Parent int;
	    _SQL text;
	    _errormsg text;

	NewTables cursor is
        select distinct 'CREATE TABLE '||replace(COALESCE(b.inTable,a.TableName),'dbo.','')||'(ID bigint NOT NULL, CONSTRAINT PK_'||replace(COALESCE(b.inTable,a.TableName),'dbo.','')||' PRIMARY KEY(ID))'
        from SYS_OBJECT_Definition a inner join SYS_OBJECT_Attributes b on (a.ID=b.ObjectDefinitionID)
        where not exists(select * 
            from information_schema.tables o
            where o.table_name iLike replace(COALESCE(b.inTable,a.TableName),'dbo.','')
            	and o.table_schema ilike current_schema()
                  and o.table_type='BASE TABLE')
            and upper(replace(COALESCE(COALESCE(b.inTable,a.TableName),''),'dbo.',''))!='CIS_EDGES'
            and upper(replace(COALESCE(COALESCE(b.inTable,a.TableName),''),'dbo.',''))!='CIS_NODES'
            and TableName is not null
            and a.ParentObjectID=_SchemaID;

	NewTableColumns cursor is 
	select distinct 'ALTER TABLE '||replace(COALESCE(t.inTable,d.TableName),'dbo.','')||' ADD '||t.name||
		' '||(select dt.name from cht_datatype dt where dt.id = t.phys_datatypeid)||
		case when phys_dt.name ilike 'varchar' and t.length is null then '(255)'
			when phys_dt.name ilike 'varchar' and t.length is not null then '('||t.length||')'
				else '' end||
	 ' NULL'  
	from cht_datatype phys_dt inner join SYS_OBJECT_Attributes t on phys_dt.id = t.phys_datatypeId 
			inner join SYS_OBJECT_Definition d on t.ObjectDefinitionID=d.id
        where not exists(select *
                from information_schema.tables o inner join information_schema.columns a on
			(o.table_catalog=a.table_catalog and o.table_schema=a.table_schema and o.table_name=a.table_name)
                where o.table_name iLike replace(COALESCE(t.inTable,d.TableName),'dbo.','') 
                    and a.column_name iLike t.name
                    and o.table_schema ilike current_schema()
                    and o.table_type='BASE TABLE')
            and upper(replace(COALESCE(COALESCE(t.inTable,d.TableName),''),'dbo.',''))!='CIS_EDGES'
            and upper(replace(COALESCE(COALESCE(t.inTable,d.TableName),''),'dbo.',''))!='CIS_NODES'
            and d.ParentObjectID=_SchemaID;


	DropTableColumns cursor is 
        select 'ALTER TABLE '||o.table_name||' DROP COLUMN '||a.column_name
        FROM information_schema.tables o inner join information_schema.columns a on(o.table_catalog=a.table_catalog and o.table_schema=a.table_schema and o.table_name=a.table_name)
        where not exists(select *
                from cht_datatype phys_dt inner join SYS_OBJECT_Attributes t on phys_dt.id = t.phys_datatypeId
				inner join SYS_OBJECT_Definition d on t.ObjectDefinitionID=d.id
                where o.table_name  iLike  replace(COALESCE(t.inTable,d.TableName),'dbo.','') 
                        and a.column_name  iLike t.name 
                        and (
                        	(a.udt_name like 'varchar' and phys_dt.name like 'varchar' and 
					((t.length = a.character_maximum_length) or (t.length is null)))
				or
				(a.udt_name like 'int4' and phys_dt.name like 'integer')
				or
				(a.udt_name like 'float8' and phys_dt.name like 'float')
				or 
				(a.udt_name ilike phys_dt.name)
                        )
                        and replace(COALESCE(t.inTable,d.TableName),'dbo.','')!='CIS_EDGES'
                        and d.ParentObjectID=_SchemaID)
              and lower(a.column_name) not in ('id','lon','lat','precision')
              and lower(o.table_name) in (select lower(replace(COALESCE(aa.inTable,tt.TableName),'dbo.',''))
                    from SYS_OBJECT_Definition tt inner join SYS_OBJECT_Attributes aa on aa.ObjectDefinitionID=tt.id
                    where tt.ParentObjectID=_SchemaID
                    and replace(tt.TableName,'dbo.','')!='CIS_EDGES') 
              and upper(o.table_name)!='CIS_EDGES'
                            and lower(o.table_name) in (select lower(replace(COALESCE(aa.inTable,tt.TableName),'dbo.',''))
                    from SYS_OBJECT_Definition tt inner join SYS_OBJECT_Attributes aa on aa.ObjectDefinitionID=tt.id
                    where tt.ParentObjectID=_SchemaID
                    and replace(tt.TableName,'dbo.','')!='CIS_NODES') 
              and upper(o.table_name)!='CIS_NODES'; 
BEGIN

    _timeStart := now();
    _timeTmp := _timeStart;

    _Parent:=nextval('seq_sys_log');
    insert into sys_log(id,Name,TimeStart,Message)
    values(_Parent,'appendSchemaTables',_timeStart,'START');

    begin
        open NewTables;

        fetch next from NewTables
        into _SQL;

        while FOUND loop
            execute _SQL;
            fetch next from NewTables
            into _SQL;
        end loop;
        close NewTables;

        open DropTableColumns;

        fetch next from DropTableColumns
        into _SQL;

        while FOUND loop
            execute _SQL;
            fetch next from DropTableColumns
            into _SQL;
        end loop;
        close DropTableColumns;

        open NewTableColumns;

        fetch next from NewTableColumns
        into _SQL;

        while FOUND loop
            execute _SQL;
            fetch next from NewTableColumns
            into _SQL;
        end loop;
        close NewTableColumns;

        _timeEnd=now();
	insert into sys_log(id,Name,TimeStart,TimeEnd,ExcTime,Message,Parent)
	values(nextval('seq_sys_log'),'appendSchemaTables',_timeStart,_timeEnd,_timeEnd-_timeStart,'OK',_Parent);
    exception
	    when OTHERS then
		_timeEnd:=now();
		insert into sys_log(id,Name,TimeStart,TimeEnd,ExcTime,Message,Parent)
		values(nextval('seq_sys_log'),'appendSchemaTables',_timeStart,_timeEnd,_timeEnd-_timeStart,'ERROR',_Parent);
    end;
    return 0;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION appendschematables(bigint, bigint) OWNER TO sa;

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
