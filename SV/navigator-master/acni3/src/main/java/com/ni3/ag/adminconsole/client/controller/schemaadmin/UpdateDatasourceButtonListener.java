/** * Copyright (c) 2009-2015 Social Vision GmbH. All rights reserved. */
package com.ni3.ag.adminconsole.client.controller.schemaadmin;

import java.awt.event.ActionEvent;
import java.util.ArrayList;
import java.util.List;

import com.ni3.ag.adminconsole.client.controller.AbstractController;
import com.ni3.ag.adminconsole.client.controller.ProgressActionListener;
import com.ni3.ag.adminconsole.client.service.ACSpringFactory;
import com.ni3.ag.adminconsole.client.session.SessionData;
import com.ni3.ag.adminconsole.client.view.schemaadmin.InfoPanel;
import com.ni3.ag.adminconsole.client.view.schemaadmin.SchemaAdminView;
import com.ni3.ag.adminconsole.dto.ErrorEntry;
import com.ni3.ag.adminconsole.remoting.ThreadLocalStorage;
import com.ni3.ag.adminconsole.shared.db.DatabaseInstance;
import com.ni3.ag.adminconsole.shared.language.TextID;
import com.ni3.ag.adminconsole.shared.service.def.AddDatasourceService;
import com.ni3.ag.adminconsole.shared.service.def.DatabaseSettingsService;
import com.ni3.ag.adminconsole.validation.ACException;

public class UpdateDatasourceButtonListener extends ProgressActionListener{

	// private final static Logger log = Logger.getLogger(UpdateDatasourceButtonListener.class);

	private SchemaAdminController controller;

	public UpdateDatasourceButtonListener(AbstractController controller){
		super(controller);
		this.controller = (SchemaAdminController) controller;
	}

	@Override
	public void performAction(ActionEvent e){
		SchemaAdminView view = controller.getView();
		InfoPanel infoPanel = view.getInfoPanel();
		String dbid = infoPanel.getDatabaseId();

		if (infoPanel.getDatasourceNames() == null || "".equals(infoPanel.getDatasourceNames()) || dbid == null
		        || "".equals(dbid.trim())){
			List<ErrorEntry> errors = new ArrayList<ErrorEntry>();
			errors.add(new ErrorEntry(TextID.MsgFillDatasourceNameAndId));
			view.renderErrors(errors);
			return;
		}
		DatabaseInstance dbi = SessionData.getInstance().getCurrentDatabaseInstance();
		AddDatasourceService service = ACSpringFactory.getInstance().getAddDatasourceService();
		try{
			if (service.databaseInstanceExists(dbi.getDatabaseInstanceId()))
				service.deleteDataSource(dbi.getDatabaseInstanceId());

			service.addDataSource(infoPanel.getNavigatorHost(), dbid, infoPanel.getDatasourceNames(),
			        infoPanel.getMappath(), infoPanel.getDocroot(), infoPanel.getRasterServer(),
			        infoPanel.getDeltaThreshold(), infoPanel.getDeltaOutThreshold(), infoPanel.getModulePath());
			initDatabaseInstances();
			DatabaseInstance current = controller.getModel().getCurrentDatabaseInstance();
			if (current != null)
				current.setInited(true);
			controller.reloadData();
			controller.updateInfoView();
			view.restoreSelection();
		} catch (ACException e1){
			view.renderErrors(e1.getErrors());
		}

	}

	private void initDatabaseInstances(){
		SessionData sData = SessionData.getInstance();
		ThreadLocalStorage tlStorage = ThreadLocalStorage.getInstance();
		DatabaseInstance instance = sData.getCurrentDatabaseInstance();

		DatabaseSettingsService dbService = ACSpringFactory.getInstance().getDatabaseSettingsService();
		List<DatabaseInstance> dbInstances = dbService.getDatabaseInstanceNames();
		sData.setDatabaseInstances(dbInstances);

		if (instance != null && instance.isConnected()){
			for (DatabaseInstance inst : dbInstances)
				if (instance.equals(inst)){
					sData.setDatabaseInstanceConnected(inst, true);
					sData.setCurrentDatabaseInstance(inst);
					sData.setDbName(inst.getDatabaseInstanceId());
					tlStorage.setCurrentDatabaseInstanceId(inst.getDatabaseInstanceId());
				}
		}

	}
}
