import { uniqueId } from 'lodash';
import { slugify } from '~/lib/utils/text_utility';

const DEFAULT_EVENT = {
  action: 'Signed in with STANDARD authentication',
  date: '2020-03-18 12:04:23',
  ip_address: '127.0.0.1',
};

const populateEvent = (user, hasAuthorUrl = true, hasObjectUrl = true) => {
  const author = { name: user, url: null };
  const object = { name: user, url: null };
  const userSlug = slugify(user);

  if (hasAuthorUrl) {
    author.url = `/${userSlug}`;
  }

  if (hasObjectUrl) {
    object.url = `http://127.0.0.1:3000/${userSlug}`;
  }

  return {
    ...DEFAULT_EVENT,
    author,
    object,
    target: user,
  };
};

const verification = [
  'id5hzCbERzSkQ82tAs16tH5Y',
  'JsSQtg86au6buRtX9j98sYa8',
  'Cr28SHnrJtgpSXUEGfictGMS',
];

export default () => [
  populateEvent('User'),
  populateEvent('User 2', false),
  populateEvent('User 3', true, false),
  populateEvent('User 4', false, false),
];

export const mockHttpType = 'http';
export const mockGcpLoggingType = 'gcpLogging';

export const mockExternalDestinationUrl = 'https://api.gitlab.com';
export const mockExternalDestinationName = 'Name';
export const mockExternalDestinationNameChange = 'Name change';
export const mockExternalDestinationHeader = () => ({
  id: uniqueId('gid://gitlab/AuditEvents::Streaming::Header/'),
  key: uniqueId('header-key-'),
  value: uniqueId('header-value-'),
  active: false,
});

const makeHeader = () => ({
  __typename: 'AuditEventStreamingHeader',
  id: `header-id-${uniqueId()}`,
  key: `header-key-${uniqueId()}`,
  value: 'header-value',
  active: false,
});

export const mockInstanceExternalDestinationHeader = () => ({
  id: uniqueId('gid://gitlab/AuditEvents::Streaming::Header/'),
  key: uniqueId('header-key-'),
  value: uniqueId('header-value-'),
  active: false,
});

const makeInstanceHeader = () => ({
  __typename: 'AuditEventsStreamingInstanceHeader',
  id: `header-id-${uniqueId()}`,
  key: `header-key-${uniqueId()}`,
  value: 'header-value',
  active: false,
});

export const mockExternalDestinations = [
  {
    __typename: 'ExternalAuditEventDestination',
    id: 'test_id1',
    name: mockExternalDestinationName,
    destinationUrl: mockExternalDestinationUrl,
    verificationToken: verification[0],
    headers: {
      nodes: [],
    },
    eventTypeFilters: [],
  },
  {
    __typename: 'ExternalAuditEventDestination',
    id: 'test_id2',
    name: mockExternalDestinationName,
    destinationUrl: 'https://apiv2.gitlab.com',
    verificationToken: verification[1],
    eventTypeFilters: ['add_gpg_key', 'user_created'],
    headers: {
      nodes: [makeHeader(), makeHeader()],
    },
  },
];

export const mockInstanceExternalDestinations = [
  {
    __typename: 'InstanceExternalAuditEventDestination',
    id: 'test_id1',
    name: mockExternalDestinationName,
    destinationUrl: mockExternalDestinationUrl,
    verificationToken: verification[0],
    headers: {
      nodes: [],
    },
    eventTypeFilters: [],
  },
  {
    __typename: 'InstanceExternalAuditEventDestination',
    id: 'test_id2',
    name: mockExternalDestinationName,
    destinationUrl: 'https://apiv2.gitlab.com',
    verificationToken: verification[1],
    headers: {
      nodes: [makeInstanceHeader(), makeInstanceHeader()],
    },
    eventTypeFilters: ['add_gpg_key', 'user_created'],
  },
];

export const mockGcpLoggingDestinations = [
  {
    __typename: 'GoogleCloudLoggingConfigurationType',
    id: 'gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1',
    name: 'Destination 1',
    clientEmail: 'my-email@my-google-project.iam.gservice.account.com',
    googleProjectIdName: 'my-google-project-1',
    logIdName: 'audit-events',
    privateKey: 'PRIVATE_KEY',
  },
  {
    __typename: 'GoogleCloudLoggingConfigurationType',
    id: 'gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/2',
    name: 'Destination 2',
    clientEmail: 'new-email@my-google-project.iam.gservice.account.com',
    googleProjectIdName: 'new-google-project-2',
    logIdName: 'audit-events',
    privateKey: 'PRIVATE_KEY',
  },
];

export const mockInstanceGcpLoggingDestinations = [
  {
    __typename: 'InstanceGoogleCloudLoggingConfigurationType',
    id: 'gid://gitlab/AuditEvents::InstanceGoogleCloudLoggingConfiguration/1',
    name: 'Destination 1',
    clientEmail: 'my-email@my-google-project.iam.gservice.account.com',
    googleProjectIdName: 'my-google-project-1',
    logIdName: 'audit-events',
    privateKey: 'PRIVATE_KEY',
  },
  {
    __typename: 'InstanceGoogleCloudLoggingConfigurationType',
    id: 'gid://gitlab/AuditEvents::InstanceGoogleCloudLoggingConfiguration/2',
    name: 'Destination 2',
    clientEmail: 'new-email@my-google-project.iam.gservice.account.com',
    googleProjectIdName: 'new-google-project-2',
    logIdName: 'audit-events',
    privateKey: 'PRIVATE_KEY',
  },
];

export const groupPath = 'test-group';

export const instanceGroupPath = 'instance';

export const testGroupId = 'test-group-id';

export const destinationDataPopulator = (nodes) => ({
  data: {
    group: { id: testGroupId, externalAuditEventDestinations: { nodes } },
  },
});

export const instanceDestinationDataPopulator = (nodes) => ({
  data: {
    instanceExternalAuditEventDestinations: { nodes },
  },
});

export const gcpLoggingDataPopulator = (nodes) => ({
  data: {
    group: {
      id: testGroupId,
      googleCloudLoggingConfigurations: { nodes },
    },
  },
});

export const instanceGcpLoggingDataPopulator = (nodes) => ({
  data: {
    instanceGoogleCloudLoggingConfigurations: { nodes },
  },
});

export const destinationCreateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    externalAuditEventDestination: {
      __typename: 'ExternalAuditEventDestination',
      id: 'test-create-id',
      name: mockExternalDestinationName,
      destinationUrl: mockExternalDestinationUrl,
      verificationToken: verification[2],
      group: {
        name: groupPath,
        id: testGroupId,
      },
      eventTypeFilters: null,
      headers: {
        nodes: [],
      },
    },
  };

  const errorData = {
    errors,
    googleCloudLoggingConfiguration: null,
  };

  return {
    data: {
      externalAuditEventDestinationCreate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const destinationUpdateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    externalAuditEventDestination: {
      __typename: 'ExternalAuditEventDestination',
      id: 'test-create-id',
      name: mockExternalDestinationName,
      destinationUrl: mockExternalDestinationUrl,
      verificationToken: verification[2],
      group: {
        name: groupPath,
        id: testGroupId,
      },
      eventTypeFilters: null,
      headers: {
        nodes: [],
      },
    },
  };

  const errorData = {
    errors,
    googleCloudLoggingConfiguration: null,
  };

  return {
    data: {
      externalAuditEventDestinationUpdate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const gcpLoggingDestinationCreateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    googleCloudLoggingConfiguration: {
      __typename: 'GoogleCloudLoggingConfigurationType',
      id: 'gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1',
      name: 'Destination 1',
      clientEmail: 'my-email@my-google-project.iam.gservice.account.com',
      googleProjectIdName: 'my-google-project',
      logIdName: 'audit-events',
    },
  };

  const errorData = {
    errors,
    googleCloudLoggingConfiguration: null,
  };

  return {
    data: {
      googleCloudLoggingConfigurationCreate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const instanceGcpLoggingDestinationCreateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    instanceGoogleCloudLoggingConfiguration: {
      __typename: 'InstanceGoogleCloudLoggingConfigurationType',
      id: 'gid://gitlab/AuditEvents::InstanceGoogleCloudLoggingConfiguration/1',
      name: 'Destination 1',
      clientEmail: 'my-email@my-google-project.iam.gservice.account.com',
      googleProjectIdName: 'my-google-project',
      logIdName: 'audit-events',
    },
  };

  const errorData = {
    errors,
    instanceGoogleCloudLoggingConfiguration: null,
  };

  return {
    data: {
      instanceGoogleCloudLoggingConfigurationCreate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const gcpLoggingDestinationUpdateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    googleCloudLoggingConfiguration: {
      __typename: 'GoogleCloudLoggingConfigurationType',
      id: 'gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1',
      name: 'Destination 1',
      clientEmail: 'my-email@my-google-project.iam.gservice.account.com',
      googleProjectIdName: 'my-google-project-1',
      logIdName: 'audit-events',
    },
  };

  const errorData = {
    errors,
    googleCloudLoggingConfiguration: null,
  };

  return {
    data: {
      googleCloudLoggingConfigurationUpdate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const instanceGcpLoggingDestinationUpdateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    instanceGoogleCloudLoggingConfiguration: {
      __typename: 'InstanceGoogleCloudLoggingConfigurationType',
      id: 'gid://gitlab/AuditEvents::InstanceGoogleCloudLoggingConfiguration/1',
      name: 'Destination 1',
      clientEmail: 'my-email@my-google-project.iam.gservice.account.com',
      googleProjectIdName: 'my-google-project-1',
      logIdName: 'audit-events',
    },
  };

  const errorData = {
    errors,
    instanceGoogleCloudLoggingConfiguration: null,
  };

  return {
    data: {
      instanceGoogleCloudLoggingConfigurationUpdate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const destinationDeleteMutationPopulator = (errors = []) => ({
  data: {
    externalAuditEventDestinationDestroy: {
      errors,
    },
  },
});

export const destinationHeaderCreateMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingHeadersCreate: {
      errors,
      clientMutationId: uniqueId(),
      header: makeHeader(),
    },
  },
});

export const destinationHeaderUpdateMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingHeadersUpdate: {
      errors,
      clientMutationId: uniqueId(),
      header: makeHeader(),
    },
  },
});

export const destinationHeaderDeleteMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingHeadersDestroy: {
      errors,
      clientMutationId: uniqueId(),
    },
  },
});

export const destinationInstanceHeaderCreateMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingInstanceHeadersCreate: {
      errors,
      clientMutationId: uniqueId(),
      header: makeInstanceHeader(),
    },
  },
});

export const destinationInstanceHeaderUpdateMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingInstanceHeadersUpdate: {
      errors,
      clientMutationId: uniqueId(),
      header: makeInstanceHeader(),
    },
  },
});

export const destinationInstanceHeaderDeleteMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingInstanceHeadersDestroy: {
      errors,
      clientMutationId: uniqueId(),
    },
  },
});

export const mockSvgPath = 'mock/path';

export const mockAuditEventDefinitions = [
  {
    event_name: 'add_gpg_key',
    feature_category: 'compliance_management',
  },
  {
    event_name: 'user_created',
    feature_category: 'user_management',
  },
  {
    event_name: 'user_blocked',
    feature_category: 'user_management',
  },
  {
    event_name: 'project_unarchived',
    feature_category: 'compliance_management',
  },
];
export const mockRemoveFilterSelect = ['add_gpg_key'];
export const mockRemoveFilterRemaining = ['user_created'];
export const mockAddFilterSelect = ['add_gpg_key', 'user_created', 'user_blocked'];
export const mockAddFilterRemaining = ['user_blocked'];

export const destinationFilterRemoveMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingDestinationEventsRemove: {
      errors,
    },
  },
});

export const destinationFilterUpdateMutationPopulator = (errors = [], eventTypeFilters = []) => ({
  data: {
    auditEventsStreamingDestinationEventsAdd: {
      errors,
      eventTypeFilters,
    },
  },
});

export const destinationInstanceCreateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    instanceExternalAuditEventDestination: {
      __typename: 'InstanceExternalAuditEventDestination',
      id: 'test-create-id',
      name: mockExternalDestinationName,
      destinationUrl: mockExternalDestinationUrl,
      verificationToken: verification[2],
      group: {
        name: groupPath,
        id: testGroupId,
      },
      eventTypeFilters: null,
      headers: {
        nodes: [],
      },
    },
  };

  const errorData = {
    errors,
    instanceExternalAuditEventDestination: null,
  };

  return {
    data: {
      instanceExternalAuditEventDestinationCreate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const destinationInstanceUpdateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    instanceExternalAuditEventDestination: {
      __typename: 'InstanceExternalAuditEventDestination',
      id: 'test-create-id',
      name: mockExternalDestinationName,
      destinationUrl: mockExternalDestinationUrl,
      verificationToken: verification[2],
      group: {
        name: groupPath,
        id: testGroupId,
      },
      eventTypeFilters: null,
      headers: {
        nodes: [],
      },
    },
  };

  const errorData = {
    errors,
    instanceExternalAuditEventDestination: null,
  };

  return {
    data: {
      instanceExternalAuditEventDestinationUpdate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const destinationInstanceDeleteMutationPopulator = (errors = []) => ({
  data: {
    instanceExternalAuditEventDestinationDestroy: {
      errors,
    },
  },
});

export const destinationGcpLoggingDeleteMutationPopulator = (errors = []) => ({
  data: {
    googleCloudLoggingConfigurationDestroy: {
      errors,
    },
  },
});

export const destinationInstanceGcpLoggingDeleteMutationPopulator = (errors = []) => ({
  data: {
    instanceGoogleCloudLoggingConfigurationDestroy: {
      errors,
    },
  },
});

export const destinationInstanceFilterRemoveMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingDestinationInstanceEventsRemove: {
      errors,
    },
  },
});

export const destinationInstanceFilterUpdateMutationPopulator = (
  errors = [],
  eventTypeFilters = [],
) => ({
  data: {
    auditEventsStreamingDestinationInstanceEventsAdd: {
      errors,
      eventTypeFilters,
    },
  },
});
