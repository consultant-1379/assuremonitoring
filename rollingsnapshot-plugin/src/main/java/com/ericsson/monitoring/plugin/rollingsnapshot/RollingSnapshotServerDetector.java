/*------------------------------------------------------------------------------ 
 *******************************************************************************
 * COPYRIGHT Ericsson 2014
 *
 * The copyright to the computer program(s) herein is the property of
 * Ericsson Inc. The programs may be used and/or copied only with written
 * permission from Ericsson Inc. or in accordance with the terms and
 * conditions stipulated in the agreement/contract under which the
 * program(s) have been supplied.
 *******************************************************************************
 *----------------------------------------------------------------------------*/
package com.ericsson.monitoring.plugin.rollingsnapshot;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.logging.Log;
import org.hyperic.hq.product.*;
import org.hyperic.util.config.ConfigResponse;

public class RollingSnapshotServerDetector extends ServerDetector implements AutoServerDetector {

    public static final String SERVER_TYPE = "RollingSnapshot";
    private final String SNAPSHOT_LOG_FILE = "/eniq/local_logs/rolling_snapshot_logs/prep_roll_snap.log";
    private final File rollingSnapshotScript = new File("/opt/assuremonitoring-plugins/scripts/rollingsnapshot.pl");
    private final String pluginDescription;
    private final String pluginServerName;
    private final Log log;

    public RollingSnapshotServerDetector() {
        super();
        this.log = getLog();
        this.pluginServerName = "RollingSnapshot";
        this.pluginDescription = "Calculates availability and seconds since last backup for rolling snapshot utility.";
    }

    public String getPluginName() {
        return this.pluginServerName;
    }

    public String getPluginDescription() {
        return this.pluginDescription;
    }

    public Boolean isMetricScriptPresent(final File metricScript) {
        return metricScript.isFile();
    }

    public Boolean isLogFilePresent(final File logFile) {
        return logFile.isFile();
    }

    @Override
    protected void setMeasurementConfig(final ServerResource server, final ConfigResponse configResponse) {
        super.setMeasurementConfig(server, configResponse);
    }

    @Override
    protected void setProductConfig(final ServerResource server, final ConfigResponse configResponse) {
        super.setProductConfig(server, configResponse);
    }

    @Override
    protected void setCustomProperties(final ServerResource server, final ConfigResponse configResponse) {
        super.setCustomProperties(server, configResponse);
    }

    @Override
    protected ServerResource createServerResource(final String pluginName) {
        final ServerResource newResource = super.createServerResource(pluginName);
        return newResource;
    }

    @Override
    public List<ServerResource> getServerResources(final ConfigResponse platformConfig) throws PluginException {

        if (log.isDebugEnabled()) {
            log.debug(getClass().getSimpleName() + ".getServerResources() called.");
        }

        List<ServerResource> servers = new ArrayList<ServerResource>();

        File snapshotlogfile = new File(SNAPSHOT_LOG_FILE);

        if (snapshotlogfile.exists() && snapshotlogfile.canRead() && isLogFilePresent(snapshotlogfile)
                && isMetricScriptPresent(rollingSnapshotScript)) {

            String installPath = "/" + SERVER_TYPE;
            ServerResource server = createServerResource(installPath);
            server.setName(getPlatformName() + " " + SERVER_TYPE);

            server.setDescription("The " + getPlatformName() + " " + SERVER_TYPE + " server.");

            ConfigResponse measurementConfig = new ConfigResponse();
            setMeasurementConfig(server, measurementConfig);

            ConfigResponse controlConfig = new ConfigResponse();
            setControlConfig(server, controlConfig);

            ConfigResponse productConfig = new ConfigResponse();
            setProductConfig(server, productConfig);

            ConfigResponse customProperties = new ConfigResponse();
            setCustomProperties(server, customProperties);

            servers.add(server);
            return servers;
        } else {
            if (log.isDebugEnabled()) {
                log.debug("This platform does not have a readable EE Backup Log File (" + snapshotlogfile + ")");
            }
        }

        return null;
    }
}
