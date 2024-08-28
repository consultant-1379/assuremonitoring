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
package com.ericsson.monitoring.plugin.backlog.test;

import static org.junit.Assert.*;
import static org.mockito.Matchers.*;
import static org.mockito.Mockito.*;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.hyperic.hq.product.*;
import org.hyperic.util.config.ConfigResponse;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.*;
import org.mockito.runners.MockitoJUnitRunner;

import com.ericsson.monitoring.plugin.backlog.BacklogServerDetector;

@RunWith(MockitoJUnitRunner.class)
public class BacklogServerDetectorTest {

    @InjectMocks
    BacklogServerDetector backLogServerDetectorTest;

    @Mock
    ServerResource serverResourceMock;

    @Mock
    ServiceResource serviceResourceMock;

    @Before
    public void setUp() throws Exception {
        MockitoAnnotations.initMocks(this);
    }

    /**
     * Test getServerType to check if file is properly read and return true if servertype is expected one.
     *
     */
    @Test
    public void testGetServerTypeValidServer() {
        final File validServerTypeFile = new File("src/test/java/test_case/installed_server_type");
        final String testServerType = backLogServerDetectorTest.getServerType(validServerTypeFile);
        assertEquals("stats_coordinator", testServerType);
    }

    /**
     * Test getServerType to check if file is properly read and return true if servertype is expected one.
     *
     */
    @Test
    public void testGetServerTypeInvalidServer() {
        final File validServerTypeFile = new File("src/test/java/test_case/invalid_server_type");
        final String testServerType = backLogServerDetectorTest.getServerType(validServerTypeFile);
        assertFalse("eniq_coordinator".equalsIgnoreCase(testServerType));

    }

    /**
     * Test getServerType to check if it handles exception.
     *
     */
    @Test
    public void testGetServerTypeThrowException() {
        final File validServerTypeFile = new File("src/test/java/test_case/invalid_server");
        final String testServerType = backLogServerDetectorTest.getServerType(validServerTypeFile);
        assertFalse("eniq_coordinator".equalsIgnoreCase(testServerType));

    }

    /**
     * Test isValidServerType to check if it can identify proper server type.
     *
     */
    @Test
    public void testisValidServerTypeValidServer() {
        final String serverType = "stats_coordinator";
        assertTrue(backLogServerDetectorTest.isValidServerType(serverType));
    }

    /**
     * Test isValidServerType to check if it can identify proper server type.
     *
     */
    @Test
    public void testisValidServerTypeInvalidServer() {
        final String serverType = "coordinator";
        assertFalse(backLogServerDetectorTest.isValidServerType(serverType));
    }

    /**
     * Test a server resource is created if all the conditions are met.
     *
     */
    @Test
    public void testGetServerResource() throws PluginException {
        final BacklogServerDetector backlogServerDetectorMock = Mockito.spy(new BacklogServerDetector());
        final String validServerType = "eniq_coordinator";

        doReturn(validServerType).when(backlogServerDetectorMock).getServerType(any(File.class));
        doReturn(new Boolean(true)).when(backlogServerDetectorMock).isValidServerType(any(String.class));
        doNothing().when(Mockito.mock(ServerResource.class)).setDescription(any(String.class));
        doReturn(serverResourceMock).when(backlogServerDetectorMock).createServerResource(any(String.class));
        doNothing().when(backlogServerDetectorMock).setMeasurementConfig(any(ServerResource.class), any(ConfigResponse.class));
        doNothing().when(backlogServerDetectorMock).setProductConfig(any(ServerResource.class), any(ConfigResponse.class));

        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServerResource> servers = backlogServerDetectorMock.getServerResources(platformConfig);
        assertNotNull(servers);
        assertEquals(1, servers.size());
    }

    /**
     * Test if getServerResource return null is auto discovery conditions are not met.
     *
     */
    @Test
    public void testGetServerResourceReturnsNull() throws PluginException {
        final BacklogServerDetector backlogServerDetectorMock = Mockito.spy(new BacklogServerDetector());
        final String validServerType = "coordinator";

        doReturn(validServerType).when(backlogServerDetectorMock).getServerType(any(File.class));
        doReturn(new Boolean(false)).when(backlogServerDetectorMock).isValidServerType(any(String.class));
        doNothing().when(Mockito.mock(ServerResource.class)).setDescription(any(String.class));
        doReturn(serverResourceMock).when(backlogServerDetectorMock).createServerResource(any(String.class));
        doNothing().when(backlogServerDetectorMock).setMeasurementConfig(any(ServerResource.class), any(ConfigResponse.class));
        doNothing().when(backlogServerDetectorMock).setProductConfig(any(ServerResource.class), any(ConfigResponse.class));

        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServerResource> servers = backlogServerDetectorMock.getServerResources(platformConfig);
        assertNull(servers);
    }

    /**
     * Test if discoverServices return null when there are no active interfaces.
     *
     */
    @Test
    public void testDiscoverServicesReturnsNull() throws PluginException {
        final BacklogServerDetector backlogServerDetectorMock = Mockito.spy(new BacklogServerDetector());

        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServiceResource> services = backlogServerDetectorMock.discoverServices(platformConfig);
        assertNull(services);
    }

    /**
     * Test if discoverServices return services list when there are active interfaces.
     *
     */
    @Test
    public void testDiscoverServices() throws PluginException {
        final BacklogServerDetector backlogServerDetectorMock = Mockito.spy(new BacklogServerDetector());
        final List<String> interfaces = new ArrayList<String>();
        interfaces.add("INFT");

        doReturn(interfaces).when(backlogServerDetectorMock).getActiveInterfaces();
        doReturn(serviceResourceMock).when(backlogServerDetectorMock).createServiceResource(any(String.class));
        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServiceResource> services = backlogServerDetectorMock.discoverServices(platformConfig);
        assertNotNull(services);
    }
}
