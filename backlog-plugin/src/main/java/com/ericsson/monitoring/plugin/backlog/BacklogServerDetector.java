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
package com.ericsson.monitoring.plugin.backlog;

import java.io.*;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.logging.Log;
import org.hyperic.hq.product.*;
import org.hyperic.util.config.ConfigResponse;

public class BacklogServerDetector extends ServerDetector implements AutoServerDetector {
    private static final String[] VALID_SERVER_TYPES = { "eniq_stats", "stats_coordinator" };
    private final File serverInstallFile = new File("/eniq/installation/config/installed_server_type");
    private static final String UTILITY_SCRIPT = "/opt/assuremonitoring-plugins/scripts/backlog.pl";
    private static final String SERVICE_TYPE = "Interface";
    private static final String SERVER_INSTALL_PATH = "Backlog Analysis";
    private static final String SERVER_DESCRIPTION = "ENIQ Backlog Analysis";
    private static final String SERVICE_DESCRIPTION = "ENIQ Interface";
    private final Log log;

    public BacklogServerDetector() {
        this.log = getLog();
    }

    @Override
    public ServerResource createServerResource(final String installpath) {
        return super.createServerResource(installpath);
    }

    @Override
    public void setMeasurementConfig(final ServerResource server, final ConfigResponse config) {
        super.setMeasurementConfig(server, config);
    }

    @Override
    public void setProductConfig(final ServerResource server, final ConfigResponse config) {
        super.setProductConfig(server, config);
    }

    @Override
    public ServiceResource createServiceResource(final String type) {
        return super.createServiceResource(type);
    }

    /**
     * Get the name of Server Type
     *
     * @param FILE
     *        object for install_server_type file
     *
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
            log.error("Unable to find file " + sTypeFile, e);
        } catch (IOException e) {
            log.error("Exception processing " + sTypeFile, e);
        } finally {
            if (inputLine != null) {
                try {
                    inputLine.close();
                } catch (IOException e) {
                    log.error(e);
                }
            }
        }

        log.debug("ServerType from getServerType is " + serverType);

        return serverType;
    }

    /**
     * Verify if the Server Type is valid
     *
     * @param String
     *        serverType
     * @return Boolean
     */
    public Boolean isValidServerType(final String serverType) {
        Boolean isValidServer = false;
        for (final String sType : VALID_SERVER_TYPES) {
            if (sType.equals(serverType)) {
                isValidServer = true;
            }
        }

        log.debug("isValidServerType returns " + isValidServer + " for serverType " + serverType);

        return isValidServer;
    }

    private ConfigResponse getMeasurementConfiguration() {
        final ConfigResponse measurementConfig = new ConfigResponse();

        /*
         * Setting this value here and not defining it as Option in hq-plugin.xml to not make it configurable through UI
         */

        measurementConfig.setValue("script", UTILITY_SCRIPT);
        measurementConfig.setValue("timeout", 60);
        return measurementConfig;
    }

    @Override
    public List<ServerResource> getServerResources(final ConfigResponse arg0) throws PluginException {

        if (isValidServerType(getServerType(serverInstallFile))) {

            log.debug("Auto-discovery conditions are valid for server type " + SERVER_INSTALL_PATH);

            final List<ServerResource> servers = new ArrayList<ServerResource>();
            final ServerResource server = createServerResource(SERVER_INSTALL_PATH);
            server.setDescription(SERVER_DESCRIPTION);

            final ConfigResponse measurementConfig = getMeasurementConfiguration();
            setMeasurementConfig(server, measurementConfig);
            final ConfigResponse productConfig = new ConfigResponse();
            setProductConfig(server, productConfig);

            servers.add(server);
            return servers;
        }

        log.debug("Auto-discovery conditions are not met for server type " + SERVER_INSTALL_PATH);

        return null;
    }

    /**
     * Execute get_active_interface to retrive active interfaces
     *
     * @param none
     * @return List<String>
     */
    public BufferedReader executeCommand() {
        final String[] command = { "/usr/bin/pfexec", UTILITY_SCRIPT, "-function", "get_active_interfaces" };

        log.debug("Executing command : /usr/bin/pfexec " + UTILITY_SCRIPT + " -function get_active_interfaces");

        try {
            final Process process = Runtime.getRuntime().exec(command);
            final BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            return reader;
        } catch (IOException e) {
            log.error("Exception executing getActiveInterfaces", e);
            return null;
        }

    }

    /**
     * Get list of active interfaces in the system.
     *
     * @param none
     * @return List<String>
     */
    public List<String> getActiveInterfaces() {
        final List<String> interfaces = new ArrayList<String>();

        try {
            final BufferedReader reader = executeCommand();
            String line = null;

            if (reader != null) {
                while (true) {
                    line = reader.readLine();

                    if (line == null) {
                        return interfaces;
                    } else {
                        final String splits[] = line.split(" ");

                        if (splits.length == 2) {
                            interfaces.add(splits[0] + "-" + splits[1]);
                        }
                    }
                }
            }
        } catch (IOException e) {
            log.error("Exception executing getActiveInterfaces", e);
        }

        return interfaces;
    }

    @Override
    public List<ServiceResource> discoverServices(final ConfigResponse config) throws PluginException {

        final List<String> interfaces = getActiveInterfaces();
        final List<ServiceResource> services = new ArrayList<ServiceResource>();

        for (final String intf : interfaces) {
            final ServiceResource service = createServiceResource(SERVICE_TYPE);
            service.setName(intf);
            service.setDescription(SERVICE_DESCRIPTION);

            final ConfigResponse measurementConfig = getMeasurementConfiguration();
            measurementConfig.setValue("interface_name", intf);
            service.setMeasurementConfig(measurementConfig);

            final ConfigResponse productConfig = new ConfigResponse();
            service.setProductConfig(productConfig);

            log.debug("Service of type " + SERVICE_TYPE + "added to server resource " + SERVER_INSTALL_PATH);

            services.add(service);
        }

        return (services.isEmpty() ? null : services);
    }
}
