/** * Copyright (c) 2009-2015 Social Vision GmbH. All rights reserved. */
package com.ni3.ag.navigator.server.calc;

import com.ni3.ag.adminconsole.domain.FormulaHolder;

public class FormulaHolderImpl implements FormulaHolder{
	private int attributeId;
	private String formula;

	public FormulaHolderImpl(int id, String formula){
		this.attributeId = id;
		this.formula = formula;
	}

	@Override
	public Integer getAttributeId(){
		return attributeId;
	}

	@Override
	public String getFormula(){
		return formula;
	}

	@Override
	public void setFormula(String formula){
		this.formula = formula;
	}
}
