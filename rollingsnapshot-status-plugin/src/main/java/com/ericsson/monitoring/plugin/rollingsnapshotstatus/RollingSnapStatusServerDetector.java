/*------------------------------------------------------------------------------
 *******************************************************************************
 * COPYRIGHT Ericsson 2016
 *
 * The copyright to the computer program(s) herein is the property of
 * Ericsson Inc. The programs may be used and/or copied only with written
 * permission from Ericsson Inc. or in accordance with the terms and
 * conditions stipulated in the agreement/contract under which the
 * program(s) have been supplied.
 *******************************************************************************
 *----------------------------------------------------------------------------*/
package com.ericsson.monitoring.plugin.rollingsnapshotstatus;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.logging.Log;
import org.hyperic.hq.product.*;
import org.hyperic.util.config.ConfigResponse;

public class RollingSnapStatusServerDetector extends ServerDetector implements AutoServerDetector {

    public static final String SERVER_TYPE = "Rolling Snapshot Status";
    private final File alarmScript = new File("/opt/assuremonitoring-plugins/scripts/rollingsnapshot_status.pl");
    private final String pluginDescription;
    private final String pluginServerName;
    private final Log log;

    public RollingSnapStatusServerDetector() {
        super();
        this.log = getLog();
        this.pluginServerName = "Rolling Snapshot Status";
        this.pluginDescription = "ENIQ Rolling Snapshot Failure due to db corruption";
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

        if (isMetricScriptPresent(alarmScript)) {

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
                log.debug("This platform does not have alarm metric script file (" + alarmScript + ")");
            }
        }

        return null;
    }
}
