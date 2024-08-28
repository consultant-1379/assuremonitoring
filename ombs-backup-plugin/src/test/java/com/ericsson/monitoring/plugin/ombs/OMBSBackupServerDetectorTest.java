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
public class OMBSBackupServerDetectorTest {

    @Mock
    ConfigResponse platformConfigMock;
    @Mock
    ServerResource server;
    @Mock
    ServerResource serverResourceMock;
    @Mock
    ServerDetector serverDetectorMock;
    @InjectMocks
    OMBSBackupServerDetector OMBSServerDetectorUnderTest;

    @Before
    public void setUp() throws Exception {
        MockitoAnnotations.initMocks(this);
    }

    /**
     * Test testGetServerResourceNegative to check servers are not detected if any of the condition is not met.
     */
    @Test
    public void testGetServerResourceNegative() throws PluginException {
        final OMBSBackupServerDetector snapshotDetectorMock = Mockito.spy(new OMBSBackupServerDetector());
        doReturn(new Boolean(false)).when(Mockito.mock(File.class)).isFile();
        doReturn(new Boolean(false)).when(Mockito.mock(File.class)).canRead();
        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServerResource> servers = snapshotDetectorMock.getServerResources(platformConfig);
        assertNull(servers);
    }

    /**
     * Test testGetServerResourcePositive to check servers are detected if all the conditions for server detection are met.
     */
    @Test
    public void testGetServerResourcePositive() throws PluginException {
        final OMBSBackupServerDetector snapshotDetectorMock = Mockito.spy(new OMBSBackupServerDetector());
        doReturn(new Boolean(true)).when(snapshotDetectorMock).checkOmbsfiles(any(File.class), any(File.class));
        doReturn(serverResourceMock).when(snapshotDetectorMock).createServerResource(any(String.class));
        doNothing().when(Mockito.mock(ServerResource.class)).setName(any(String.class));
        doNothing().when(Mockito.mock(ServerResource.class)).setDescription(any(String.class));
        doNothing().when(snapshotDetectorMock).setMeasurementConfig(any(ServerResource.class), any(ConfigResponse.class));
        doNothing().when(snapshotDetectorMock).setProductConfig(any(ServerResource.class), any(ConfigResponse.class));
        doNothing().when(snapshotDetectorMock).setCustomProperties(any(ServerResource.class), any(ConfigResponse.class));
        final ConfigResponse platformConfig = new ConfigResponse();
        final List<ServerResource> servers = snapshotDetectorMock.getServerResources(platformConfig);
        assertNotNull(servers);
        assertEquals(1, servers.size());
    }

}
