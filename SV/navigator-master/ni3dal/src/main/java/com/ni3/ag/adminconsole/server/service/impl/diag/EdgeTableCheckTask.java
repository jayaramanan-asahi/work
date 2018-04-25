/** * Copyright (c) 2009-2015 Social Vision GmbH. All rights reserved. */
package com.ni3.ag.adminconsole.server.service.impl.diag;

import java.math.BigInteger;
import java.sql.SQLException;

import org.hibernate.HibernateException;
import org.hibernate.SQLQuery;
import org.springframework.orm.hibernate3.HibernateCallback;
import org.springframework.orm.hibernate3.support.HibernateDaoSupport;

import com.ni3.ag.adminconsole.domain.Schema;
import com.ni3.ag.adminconsole.server.service.DiagnosticTask;
import com.ni3.ag.adminconsole.validation.ACException;
import com.ni3.ag.adminconsole.validation.ACFixTaskException;
import com.ni3.ag.adminconsole.validation.DiagnoseTaskResult;
import com.ni3.ag.adminconsole.validation.DiagnoseTaskStatus;

public class EdgeTableCheckTask extends HibernateDaoSupport implements DiagnosticTask{
	private static final String MY_DESCRIPTION = "Checking edge table";
	private static final String ACTION_SQL = "select count(*) from cis_edges " + "where not exists (select id "
	        + "from cis_objects t where t.id=cis_edges.id)";
	private static final String TOOLTIP = "Edges without records in objects table: ";

	@Override
	public DiagnoseTaskResult makeDiagnose(Schema sch){
		HibernateCallback callback = new HibernateCallback(){

			@Override
			public Object doInHibernate(org.hibernate.Session session) throws HibernateException, SQLException{
				SQLQuery query = (SQLQuery) session.createSQLQuery(ACTION_SQL);
				return query.uniqueResult();
			}
		};
		BigInteger count = (BigInteger) getHibernateTemplate().execute(callback);
		String errMsg = count.intValue() == 0 ? null : TOOLTIP + count.intValue();
		return new DiagnoseTaskResult(getClass().getName(), MY_DESCRIPTION, true, count.intValue() == 0
		        ? DiagnoseTaskStatus.Ok : DiagnoseTaskStatus.Error, errMsg, null);
	}

	@Override
	public DiagnoseTaskResult makeFix(DiagnoseTaskResult taskResult) throws ACFixTaskException, ACException{
		final Object[] params = taskResult.getFixParams();
		HibernateCallback callback = new HibernateCallback(){
			@Override
			public Object doInHibernate(org.hibernate.Session session) throws HibernateException, SQLException{
				String sql = "insert into cis_objects (id, objecttype, userid, creator, status)" + " select id, edgetype, "
				        + params[0] + ", " + params[0]
				        + ", 0 from cis_edges where not exists (select id from cis_objects t where t.id=cis_edges.id)";
				SQLQuery query = session.createSQLQuery(sql);
				query.executeUpdate();
				return 1;
			}
		};
		try{
			getHibernateTemplate().execute(callback);
			taskResult.setStatus(DiagnoseTaskStatus.Ok);
			return taskResult;
		} catch (Exception e){
			throw new ACFixTaskException(e.getClass().getName(), e.getMessage());
		}
	}

	@Override
	public String getTaskDescription(){
		return MY_DESCRIPTION;
	}

}
