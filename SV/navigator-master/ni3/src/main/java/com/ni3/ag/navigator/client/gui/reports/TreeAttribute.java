/** * Copyright (c) 2009-2015 Social Vision GmbH. All rights reserved. */
package com.ni3.ag.navigator.client.gui.reports;

import com.ni3.ag.navigator.client.domain.Attribute;

public class TreeAttribute{
	private Attribute attribute;
	private boolean isSelected = true;

	public TreeAttribute(Attribute attribute){
		this.attribute = attribute;
	}

	public boolean isSelected(){
		return isSelected;
	}

	public void setSelected(boolean isSelected){
		this.isSelected = isSelected;
	}

	public Attribute getAttribute(){
		return attribute;
	}

	@Override
	public boolean equals(java.lang.Object obj){
		if (this == obj){
			return true;
		}
		if (obj == null
		        || !(obj instanceof TreeAttribute || attribute == null || ((TreeAttribute) obj).getAttribute() == null)){
			return false;
		}
		return attribute.ID == ((TreeAttribute) obj).getAttribute().ID;
	}

	@Override
	public String toString(){
		return attribute.label;
	}
}
