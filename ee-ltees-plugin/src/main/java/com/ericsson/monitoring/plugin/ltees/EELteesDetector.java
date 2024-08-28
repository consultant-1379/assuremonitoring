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
package com.ericsson.monitoring.plugin.ltees;

import org.apache.commons.logging.Log;

import java.io.*;
import java.util.ArrayList;
import java.util.List;

import org.hyperic.hq.product.*;
import org.hyperic.util.config.ConfigResponse;

public class EELteesDetector extends ServerDetector implements AutoServerDetector {
    private static final String[] validServerTypes = {"eniq_events", "eniq_coordinator"};
    private final File lteesFeatureDir = new File("/eniq/mediation_inter/M_E_LTEES");
    private final File serverInstallFile = new File("/eniq/installation/config/installed_server_type");
    private final File lteesPerfStatScript = new File ("/opt/assuremonitoring-plugins/scripts/ltees_perf_stat.pl");
    private final String pluginDescription;
    private final String pluginServerName;
    private final Log log;
    /* (non-Javadoc)
     * @see org.hyperic.hq.product.AutoServerDetector#getServerResources(org.hyperic.util.config.ConfigResponse)
     */
    public EELteesDetector() {
        super();
        this.log = getLog();
        this.pluginServerName = "EE-LTEES";
        this.pluginDescription ="Performance Metrics for ENIQ Events Mediation Layer - ltees feature.";
    }

    /**
     * Get method for plug-in name defined in constructor
     *
     * @return String pluginServerName
     */
    public String getPluginName() {
        return this.pluginServerName;
    }

    /**
     * Get method for plug-in description defined in constructor
     *
     * @return String pluginDescription
     */
    public String getPluginDescription() {
        return this.pluginDescription;
    }

    /**
     * Get the name of Server Type from File
     *
     * @param complete filename of install_server_type file
     * @return String serverType
     */
    public String getServerType(final File sTypeFile) {
        BufferedReader inputLine = null;
        String serverType = null;
        try {
            inputLine = new BufferedReader(new FileReader(sTypeFile));
            serverType = inputLine.readLine();
            inputLine.close();
        } catch (FileNotFoundException e) {
            log.error("Exception when attempting to open " + sTypeFile + " for reading", e);
        } catch (IOException e) {
            log.error("Exception processing " + sTypeFile, e);
        } finally {
            if (inputLine != null) {
                try {
                    inputLine.close();
                } catch (IOException e) {
                }
            }
        }
        if (log.isDebugEnabled()){
            log.debug(getClass().getSimpleName() + " serverType from getServerType is " + serverType );
        }

        return serverType;
    }

    /**
     * Verify if the Server Type is valid
     *
     * @param String serverType
     * @return Boolean
     */
    public Boolean isValidServerType (final String serverType) {
        Boolean isValidServer = false;
        for (final String sType : validServerTypes) {
            if (sType.equals(serverType)) {
                isValidServer = true;
            }
        }
        if (log.isDebugEnabled()){
            log.debug(getClass().getSimpleName() + " isValidServerType returns " + isValidServer + " for serverType " + serverType );
        }
        return isValidServer;
    }

    /**
     * Verify if ltees Feature is installed based on availability the install directory.
     *
     * @param complete directory name of the ltees Feature Install location
     * @return Boolean
     */
    public Boolean islteesFeatureInstalled (final File featFile) {
        return featFile.isDirectory();
    }

    /**
     * Verify if the script needed for Metric collect is available.
     *
     * @param complete filename of metric collection script
     * @return Boolean
     */
    public Boolean isMetricScriptPresent (final File metricScript) {
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
    protected ServerResource createServerResource (final String pluginName) {
        final ServerResource newResource = super.createServerResource(pluginName);
        return newResource;
    }

    @Override
    public List<ServerResource> getServerResources(final ConfigResponse platformConfig) throws PluginException {
        if (log.isDebugEnabled()) {
            log.debug(getClass().getSimpleName() + "getServerResources called.");
        }
        if (isMetricScriptPresent(lteesPerfStatScript) && isValidServerType(getServerType(serverInstallFile)) && islteesFeatureInstalled(lteesFeatureDir)) {

            if(log.isDebugEnabled()) {
                log.debug(getClass().getSimpleName() + "getServerResources conditions are valid.");
            }

            final List<ServerResource> servers = new ArrayList<ServerResource>();
            final ServerResource server = createServerResource(getPluginName());
            server.setDescription(getPluginDescription());

            final ConfigResponse measurementConfig = new ConfigResponse();
            setMeasurementConfig(server, measurementConfig);
            final ConfigResponse productConfig = new ConfigResponse();
            setProductConfig(server, productConfig);
            final ConfigResponse customProperties = new ConfigResponse();
            setCustomProperties(server, customProperties);

            servers.add(server);
            return servers;
        }
        else {
            if(log.isDebugEnabled()) {
                log.debug(getClass().getSimpleName() + " getServerResources  one or more conditions are not valid.");
                log.debug(getClass().getSimpleName() + " isMetricScriptPresent is " + isMetricScriptPresent(lteesPerfStatScript) + " for script " + lteesPerfStatScript);
                log.debug(getClass().getSimpleName() + " islteesFeatureInstalled is " + islteesFeatureInstalled(lteesFeatureDir) + " for directory " + lteesFeatureDir);
            }
            return null;
        }
    }

}