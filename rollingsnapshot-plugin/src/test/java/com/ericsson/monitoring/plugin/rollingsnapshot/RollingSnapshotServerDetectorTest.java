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

import static org.junit.Assert.*;
import static org.mockito.Matchers.*;
import static org.mockito.Mockito.*;

import java.io.File;
import java.util.List;

import org.hyperic.hq.product.*;
import org.hyperic.util.config.ConfigResponse;
import org.hyperic.hq.product.ServerDetector;
import org.hyperic.hq.product.ServerResource;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.*;
import org.mockito.runners.MockitoJUnitRunner;

@RunWith(MockitoJUnitRunner.class)
public class RollingSnapshotServerDetectorTest {

    @Mock
    ConfigResponse platformConfigMock;
    @Mock
    ServerResource server;
    @Mock
    ServerResource serverResourceMock;
    @Mock
    ServerDetector serverDetectorMock;
    @InjectMocks
    RollingSnapshotServerDetector RollingSnapshotDetectorUnderTest;

    @Before
    public void setUp() throws Exception {
        MockitoAnnotations.initMocks(this);
    }

    /**
     * Test isMetricScriptPresent to check it returns false if metric collection script does not exist.
     * 
     */
    @Test
    public void testIsMetricScriptPresent() {
        final File mockScript = Mockito.mock(File.class);
        doReturn(new Boolean(true)).when(mockScript).isFile();
        final Boolean testResult = RollingSnapshotDetectorUnderTest.isMetricScriptPresent(mockScript);
        assertTrue(testResult);
    }

    /**
     * Test isMetricScriptPresent to check it returns false if metric collection script does not exist.
     * 
     */
    @Test
    public void testIsMetricScriptFalse() {
        final File mockScript = Mockito.mock(File.class);
        doReturn(new Boolean(true)).when(mockScript).isFile();
        final Boolean testResult = RollingSnapshotDetectorUnderTest.isMetricScriptPresent(mockScript);
        assertTrue(testResult);
    }

    /**
     * Test isLogFilePresent to check it returns true if snapshot log file is present.
     * 
     */
    @Test
    public void testIsLogFilePresent() {
        final File mockLogFile = Mockito.mock(File.class);
        doReturn(new Boolean(false)).when(mockLogFile).isFile();
        final Boolean testResult = RollingSnapshotDetectorUnderTest.isLogFilePresent(mockLogFile);
        assertFalse(testResult);
    }

    /**
     * Test testIsLogFileFalse to check it returns false if snapshot log file does not exist.
     * 
     */
    @Test
    public void testIsLogFileFalse() {
        final File mockLogFile = Mockito.mock(File.class);
        doReturn(new Boolean(false)).when(mockLogFile).isFile();
        final Boolean testResult = RollingSnapshotDetectorUnderTest.isLogFilePresent(mockLogFile);
        assertFalse(testResult);
    }

    /**
     * Test testGetServerResourceNegative to check servers are not detected if any of the condition is not met.
     * 
     */
    @Test
    public void testGetServerResourceNegative() throws PluginException {
        final RollingSnapshotServerDetector snapshotDetectorMock = Mockito.spy(new RollingSnapshotServerDetector());
        doReturn(new Boolean(false)).when(snapshotDetectorMock).isMetricScriptPresent(any(File.class));
        doReturn(new Boolean(true)).when(snapshotDetectorMock).isLogFilePresent(any(File.class));
        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServerResource> servers = snapshotDetectorMock.getServerResources(platformConfig);
        assertNull(servers);
    }

}
