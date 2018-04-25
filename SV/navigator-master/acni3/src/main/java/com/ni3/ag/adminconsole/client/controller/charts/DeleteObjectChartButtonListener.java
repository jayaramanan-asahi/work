/** * Copyright (c) 2009-2015 Social Vision GmbH. All rights reserved. */
package com.ni3.ag.adminconsole.client.controller.charts;

import java.awt.event.ActionEvent;

import com.ni3.ag.adminconsole.client.controller.ProgressActionListener;
import com.ni3.ag.adminconsole.client.view.charts.ChartView;
import com.ni3.ag.adminconsole.domain.Chart;
import com.ni3.ag.adminconsole.shared.model.impl.ChartModel;

public class DeleteObjectChartButtonListener extends ProgressActionListener{

	public DeleteObjectChartButtonListener(ChartController chartController){
		super(chartController);
	}

	@Override
	public void performAction(ActionEvent e){
		ChartController controller = (ChartController) getController();
		ChartModel model = (ChartModel) controller.getModel();
		Object o = model.getCurrentObject();
		if (o == null || !(o instanceof Chart))
			return;
		ChartView view = (ChartView) controller.getView();
		view.stopTableEditing();
		view.renderErrors(null);
		controller.deleteObjectChart();

	}

}
