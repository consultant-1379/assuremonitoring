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
package com.ericsson.monitoring.plugin.lteefa;

import static org.junit.Assert.*;
import static org.mockito.Matchers.*;
import static org.mockito.Mockito.*;

import java.io.File;
import java.util.List;

import org.hyperic.hq.product.*;
import org.hyperic.util.config.ConfigResponse;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.*;
import org.mockito.runners.MockitoJUnitRunner;

@RunWith(MockitoJUnitRunner.class)
public class EELteefaDetectorTest {

    @Mock
    ConfigResponse platformConfigMock;
    @Mock
    ServerResource server;
    @Mock
    ServerResource serverResourceMock;

    @Mock
    ServerDetector serverDetectorMock;
    @InjectMocks
    EELteefaDetector EELteefaDetectorUnderTest;

    @Before
    public void setUp() throws Exception {
        MockitoAnnotations.initMocks(this);
    }

    /**
     * Test getServerType to check if file is properly read and return true if servertype is expected one.
     */
    @Test
    public void testGetServerType() {
        final File validServerTypeFile = new File("src/test/java/test_case/installed_server_type");
        final String testServerType = EELteefaDetectorUnderTest.getServerType(validServerTypeFile);
        assertEquals("eniq_coordinator", testServerType);

    }

    /**
     * Test isValidServerType to check if file returns expected output, then the test method return true.
     */
    @Test
    public void testIsValidServerType() {
        final File validServerTypeFile = new File("src/test/java/test_case/installed_server_type");
        final String testServerType = EELteefaDetectorUnderTest.getServerType(validServerTypeFile);
        final Boolean testResult = EELteefaDetectorUnderTest.isValidServerType(testServerType);
        assertTrue(testResult);
    }

    /**
     * Test isValidServerType to check if file returns unexpected output, then the test method return false.
     */
    @Test
    public void testIsValidServerTypeFalse() {
        final File invalidServerTypeFile = new File("src/test/java/test_case/unwanted_installed_server_type");
        final String testServerType = EELteefaDetectorUnderTest.getServerType(invalidServerTypeFile);
        final Boolean testResult = EELteefaDetectorUnderTest.isValidServerType(testServerType);
        assertFalse(testResult);
    }

    /**
     * Test islteefaFeatureInstalled to check it returns true if feature directory exist.
     */
    @Test
    public void testIslteefaFeatureInstalled() {
        final File featDir = Mockito.mock(File.class);
        doReturn(new Boolean(true)).when(featDir).isDirectory();
        final Boolean testResult = EELteefaDetectorUnderTest.islteefaFeatureInstalled(featDir);
        assertTrue(testResult);
    }

    /**
     * Test islteefaFeatureInstalled to check it returns false if feature directory does not exist.
     */
    @Test
    public void testIslteefaFeatureInstalledFalse() {
        final File featDir = Mockito.mock(File.class);
        doReturn(new Boolean(false)).when(featDir).isDirectory();
        final Boolean testResult = EELteefaDetectorUnderTest.islteefaFeatureInstalled(featDir);
        assertFalse(testResult);
    }

    /**
     * Test isMetricScriptPresent to check it returns true if metric collection script exist.
     */
    @Test
    public void testIsMetricScriptPresent() {
        final File mockScript = Mockito.mock(File.class);
        doReturn(new Boolean(true)).when(mockScript).exists();
        final Boolean testResult = EELteefaDetectorUnderTest.isMetricScriptPresent(mockScript);
        assertTrue(testResult);
    }

    /**
     * Test isMetricScriptPresent to check it returns false if metric collection script does not exist.
     */
    @Test
    public void testIsMetricScriptPresentFalse() {
        final File mockScript = Mockito.mock(File.class);
        doReturn(new Boolean(false)).when(mockScript).exists();
        final Boolean testResult = EELteefaDetectorUnderTest.isMetricScriptPresent(mockScript);
        assertFalse(testResult);
    }

    /**
     * Test a server resource is created if all the conditions are met.
     */
    @Test
    public void testGetServerResource() throws PluginException {
        final EELteefaDetector eelteefaDetectorMock = Mockito.spy(new EELteefaDetector());
        final String validServerType = "eniq_coordinator";
        doReturn(validServerType).when(eelteefaDetectorMock).getServerType(any(File.class));
        doReturn(new Boolean(true)).when(eelteefaDetectorMock).isMetricScriptPresent(any(File.class));
        doReturn(new Boolean(true)).when(eelteefaDetectorMock).isValidServerType(any(String.class));
        doReturn(new Boolean(true)).when(eelteefaDetectorMock).islteefaFeatureInstalled(any(File.class));

        doReturn(serverResourceMock).when(eelteefaDetectorMock).createServerResource(any(String.class));
        doNothing().when(Mockito.mock(ServerResource.class)).setDescription(any(String.class));
        doNothing().when(eelteefaDetectorMock).setMeasurementConfig(any(ServerResource.class), any(ConfigResponse.class));
        doNothing().when(eelteefaDetectorMock).setProductConfig(any(ServerResource.class), any(ConfigResponse.class));
        doNothing().when(eelteefaDetectorMock).setCustomProperties(any(ServerResource.class), any(ConfigResponse.class));

        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServerResource> servers = eelteefaDetectorMock.getServerResources(platformConfig);
        assertNotNull(servers);
        assertEquals(1, servers.size());
    }

    /**
     * Test a server resource is not created if any one of the condition is not met.
     */
    @Test
    public void testGetServerResourceNegative() throws PluginException {
        final EELteefaDetector eelteefaDetectorMock = Mockito.spy(new EELteefaDetector());
        final String inValidServerType = "eniq_mz";
        doReturn(inValidServerType).when(eelteefaDetectorMock).getServerType(any(File.class));
        doReturn(new Boolean(false)).when(eelteefaDetectorMock).isMetricScriptPresent(any(File.class));
        doReturn(new Boolean(true)).when(eelteefaDetectorMock).isValidServerType(any(String.class));
        doReturn(new Boolean(true)).when(eelteefaDetectorMock).islteefaFeatureInstalled(any(File.class));
        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServerResource> servers = eelteefaDetectorMock.getServerResources(platformConfig);
        assertNull(servers);
    }

}