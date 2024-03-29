/** * Copyright (c) 2009-2015 Social Vision GmbH. All rights reserved. */
package com.ni3.ag.adminconsole.server.service.impl.diag;

import java.math.BigDecimal;
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

public class NodeReferenceCheckTask extends HibernateDaoSupport implements DiagnosticTask{
	private static final String MY_DESCRIPTION = "Checking references to non existing nodes";
	private static final String TOOLTIP = "References to non existing nodes: ";
	private static final String ACTION_SQL = "select sum(count) from "
	        + "(select count(FromId) as count from cis_edges t where not exists "
	        + "(select * from cis_nodes tt where t.fromid=tt.id) " + "union "
	        + "select count(ToId) as count from cis_edges t where not exists "
	        + "(select * from cis_nodes tt where t.toid=tt.id)) as countsTable";
	private static final String[] FIX_SCRIPTS = {
	        "delete from cis_edges where fromid in " + "(select e.FromId from cis_edges e where not exists "
	                + "( select id from cis_nodes where id = e.fromid))",
	        "delete from cis_edges where toid in "
	                + "(select e.toid from cis_edges e where not exists ( select id from cis_nodes where id = e.toid ))" };

	@Override
	public DiagnoseTaskResult makeDiagnose(Schema sch){
		HibernateCallback callback = new HibernateCallback(){

			@Override
			public Object doInHibernate(org.hibernate.Session session) throws HibernateException, SQLException{
				SQLQuery query = (SQLQuery) session.createSQLQuery(ACTION_SQL);
				return query.uniqueResult();
			}
		};
		BigDecimal count = (BigDecimal) getHibernateTemplate().execute(callback);
		String errMsg = count.intValue() == 0 ? null : TOOLTIP + count.intValue();
		return new DiagnoseTaskResult(getClass().getName(), MY_DESCRIPTION, true, count.intValue() == 0
		        ? DiagnoseTaskStatus.Ok : DiagnoseTaskStatus.Error, errMsg, null);
	}

	@Override
	public DiagnoseTaskResult makeFix(DiagnoseTaskResult taskResult) throws ACFixTaskException, ACException{
		HibernateCallback callback = new HibernateCallback(){
			@Override
			public Object doInHibernate(org.hibernate.Session session) throws HibernateException, SQLException{
				for (int i = 0; i < FIX_SCRIPTS.length; i++){
					SQLQuery query = (SQLQuery) session.createSQLQuery(FIX_SCRIPTS[i]);
					query.executeUpdate();
				}
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
