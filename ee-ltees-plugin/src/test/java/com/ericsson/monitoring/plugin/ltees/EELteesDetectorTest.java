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

import static org.junit.Assert.*;

import java.io.File;
import java.util.List;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.*;
import org.mockito.*;
import org.mockito.runners.MockitoJUnitRunner;
import static org.mockito.BDDMockito.*;

import org.hyperic.hq.product.PluginException;
import org.hyperic.hq.product.ServerDetector;
import org.hyperic.hq.product.ServerResource;
import org.hyperic.util.config.ConfigResponse;



@RunWith(MockitoJUnitRunner.class)
public class EELteesDetectorTest {


    @Mock ConfigResponse platformConfigMock;
    @Mock ServerResource server;
    @Mock ServerResource serverResourceMock;

    @Mock ServerDetector serverDetectorMock;
    @InjectMocks EELteesDetector EELteesDetectorUnderTest;

    @Before
    public void setUp() throws Exception {
        MockitoAnnotations.initMocks(this);
    }

    /**
     * Test getServerType to check if file is properly read and return true if servertype is expected one.
     *
     */
    @Test
    public void testGetServerType() {
        final File validServerTypeFile = new File ("src/test/java/test_case/installed_server_type");
        final String testServerType = EELteesDetectorUnderTest.getServerType(validServerTypeFile);
        assertEquals("eniq_coordinator", testServerType);

    }

    /**
     * Test isValidServerType to check if file returns expected output, then the test method return true.
     *
     */
    @Test
    public void testIsValidServerType() {
        final File validServerTypeFile = new File ("src/test/java/test_case/installed_server_type");
        final String testServerType = EELteesDetectorUnderTest.getServerType(validServerTypeFile);
        final Boolean testResult = EELteesDetectorUnderTest.isValidServerType(testServerType);
        assertTrue(testResult);
    }

    /**
     * Test getServerType to check if file is properly read and returns false if not expected one.
     *
     */
    @Test
    public void testGetServerTypeFalse() {
        final File invalidServerTypeFile = new File ("src/test/java/test_case/unwanted_installed_server_type");
        final String testServerType = EELteesDetectorUnderTest.getServerType(invalidServerTypeFile);
        assertNotEquals("coordinator",testServerType);
    }

    /**
     * Test isValidServerType to check if file returns unexpected output, then the test method return false.
     *
     */
    @Test
    public void testIsValidServerTypeFalse() {
        final File invalidServerTypeFile = new File ("src/test/java/test_case/unwanted_installed_server_type");
        final String testServerType = EELteesDetectorUnderTest.getServerType(invalidServerTypeFile);
        final Boolean testResult = EELteesDetectorUnderTest.isValidServerType(testServerType);
        assertFalse(testResult);
    }

    /**
     * Test islteesFeatureInstalled to check it returns true if feature directory exist.
     *
     */
    @Test
    public void testIslteesFeatureInstalled() {
        final File featDir = Mockito.mock(File.class);
        doReturn(new Boolean(true)).when(featDir).isDirectory();
        final Boolean testResult = EELteesDetectorUnderTest.islteesFeatureInstalled(featDir);
        assertTrue(testResult);
    }

    /**
     * Test islteesFeatureInstalled to check it returns false if feature directory does not exist.
     *
     */
    @Test
    public void testIslteesFeatureInstalledFalse() {
        final File featDir = Mockito.mock(File.class);
        doReturn(new Boolean(false)).when(featDir).isDirectory();
        final Boolean testResult = EELteesDetectorUnderTest.islteesFeatureInstalled(featDir);
        assertFalse(testResult);
    }

    /**
     * Test isMetricScriptPresent to check it returns true if metric collection script exist.
     *
     */
    @Test
    public void testIsMetricScriptPresent() {
        final File mockScript = Mockito.mock(File.class);
        doReturn(new Boolean(true)).when(mockScript).isFile();
        final Boolean testResult = EELteesDetectorUnderTest.isMetricScriptPresent(mockScript);
        assertTrue(testResult);
    }

    /**
     * Test isMetricScriptPresent to check it returns false if metric collection script does not exist.
     *
     */
    @Test
    public void testIsMetricScriptPresentFalse() {
        final File mockScript = Mockito.mock(File.class);
        doReturn(new Boolean(false)).when(mockScript).isFile();
        final Boolean testResult = EELteesDetectorUnderTest.isMetricScriptPresent(mockScript);
        assertFalse(testResult);
    }

    /**
     * Test a server resource is created if all the conditions are met.
     *
     */
    @Test
    public void testGetServerResource() throws PluginException {
        final EELteesDetector eelteesDetectorMock = Mockito.spy(new EELteesDetector());
        final String validServerType = "eniq_coordinator";
        doReturn(validServerType).when(eelteesDetectorMock).getServerType(any(File.class));
        doReturn(new Boolean(true)).when(eelteesDetectorMock).isMetricScriptPresent(any(File.class));
        doReturn(new Boolean(true)).when(eelteesDetectorMock).isValidServerType(any(String.class));
        doReturn(new Boolean(true)).when(eelteesDetectorMock).islteesFeatureInstalled(any(File.class));

        doReturn(serverResourceMock).when(eelteesDetectorMock).createServerResource(any(String.class));
        doNothing().when(Mockito.mock(ServerResource.class)).setDescription(any(String.class));
        doNothing().when(eelteesDetectorMock).setMeasurementConfig(any(ServerResource.class),any(ConfigResponse.class));
        doNothing().when(eelteesDetectorMock).setProductConfig(any(ServerResource.class), any(ConfigResponse.class));
        doNothing().when(eelteesDetectorMock).setCustomProperties(any(ServerResource.class), any(ConfigResponse.class));

        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServerResource> servers = eelteesDetectorMock.getServerResources(platformConfig);
        assertNotNull(servers);
        assertEquals(1, servers.size());
    }


    /**
     * Test a server resource is not created if any one of the condition is not met.
     *
     */
    @Test
    public void testGetServerResourceNegative() throws PluginException {
        final EELteesDetector eelteesDetectorMock = Mockito.spy(new EELteesDetector());
        final String inValidServerType = "eniq_mz";
        doReturn(inValidServerType).when(eelteesDetectorMock).getServerType(any(File.class));
        doReturn(new Boolean(false)).when(eelteesDetectorMock).isMetricScriptPresent(any(File.class));
        doReturn(new Boolean(true)).when(eelteesDetectorMock).isValidServerType(any(String.class));
        doReturn(new Boolean(true)).when(eelteesDetectorMock).islteesFeatureInstalled(any(File.class));
        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServerResource> servers = eelteesDetectorMock.getServerResources(platformConfig);
        assertNull(servers);
    }

}