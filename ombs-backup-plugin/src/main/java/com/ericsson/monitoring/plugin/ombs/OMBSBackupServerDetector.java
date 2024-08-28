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
package com.ericsson.monitoring.plugin.ombs;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.logging.Log;
import org.hyperic.hq.product.*;
import org.hyperic.util.config.ConfigResponse;

public class OMBSBackupServerDetector extends ServerDetector implements AutoServerDetector {

    public static final String SERVER_TYPE = "OMBS Backup";
    private final File backuplogfile = new File("/eniq/local_logs/backup_logs/prep_eniq_backup.log");
    private final File ombsBackupScript = new File("/opt/assuremonitoring-plugins/scripts/ombs_backup.pl");
    private final String pluginDescription;
    private final String pluginServerName;
    private final Log log;

    public OMBSBackupServerDetector() {
        super();
        this.log = getLog();
        this.pluginServerName = "OMBS Backup";
        this.pluginDescription = "Calculates availability and time since last successful backup for ombs backup utility.";
    }

    public String getPluginName() {
        return this.pluginServerName;
    }

    public String getPluginDescription() {
        return this.pluginDescription;
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

    public Boolean checkOmbsfiles(final File backuplogfile, final File ombsBackupScript) {
        if (backuplogfile.exists() && backuplogfile.canRead() && ombsBackupScript.exists())
            return true;
        else
            return false;
    }

    @Override
    public List<ServerResource> getServerResources(final ConfigResponse platformConfig) throws PluginException {

        if (log.isDebugEnabled()) {
            log.debug(getClass().getSimpleName() + ".getServerResources() called.");
        }
        List<ServerResource> servers = new ArrayList<ServerResource>();

        if (checkOmbsfiles(backuplogfile, ombsBackupScript)) {

            String installPath = "/" + SERVER_TYPE;
            ServerResource server = createServerResource(installPath);
            server.setName(getPlatformName() + " " + SERVER_TYPE);
            server.setDescription("The " + getPlatformName() + " " + SERVER_TYPE + " server.");

            ConfigResponse measurementConfig = new ConfigResponse();
            setMeasurementConfig(server, measurementConfig);
            ConfigResponse productConfig = new ConfigResponse();
            setProductConfig(server, productConfig);
            ConfigResponse customProperties = new ConfigResponse();
            setCustomProperties(server, customProperties);

            servers.add(server);
            return servers;
        } else {
            if (log.isDebugEnabled()) {
                log.debug("This platform does not have a readable OMBS Backup Log File (" + backuplogfile + ")");
            }
        }

        return null;
    }
}
