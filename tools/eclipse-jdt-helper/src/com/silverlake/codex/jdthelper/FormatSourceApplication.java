package com.silverlake.codex.jdthelper;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

public class FormatSourceApplication implements IApplication {

	@Override
	public Object start(IApplicationContext context) throws Exception {
		Object value = context.getArguments().get(IApplicationContext.APPLICATION_ARGS);
		if (value instanceof String[] arguments) {
			FormatSourceCore.runFormatting(arguments);
		} else {
			FormatSourceCore.runFormatting(new String[0]);
		}
		return IApplication.EXIT_OK;
	}

	@Override
	public void stop() {
		// No background services to stop.
	}
}
