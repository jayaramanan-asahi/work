/** * Copyright (c) 2009-2015 Social Vision GmbH. All rights reserved. */
package com.ni3.ag.adminconsole.shared.service.def;

public interface ChecksumEncoder{
	public String encode(Integer userId, String entityId);
}
