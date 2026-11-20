locals {
  schema_extension_categories = toset(["ApiManagement", "AzureStorageAccount"])
  azure_metadata_categories   = toset(["AzureStorageAccount", "CosmosDb", "CognitiveSearch"])
  # The ARM union is discriminated by authType, not category.
  credential_fields = {
    AAD                    = { required = [], optional = [] }
    AccessKey              = { required = ["accessKeyId", "secretAccessKey"], optional = [] }
    AccountKey             = { required = ["key"], optional = [] }
    ApiKey                 = { required = ["key"], optional = [] }
    CustomKeys             = { required = [], optional = [] }
    ManagedIdentity        = { required = [], optional = ["clientId", "resourceId"] }
    None                   = { required = [], optional = [] }
    OAuth2                 = { required = ["clientId", "clientSecret"], optional = ["authUrl", "developerToken", "password", "refreshToken", "tenantId", "username"] }
    PAT                    = { required = ["pat"], optional = [] }
    ProjectManagedIdentity = { required = [], optional = [] }
    SAS                    = { required = ["sas"], optional = [] }
    ServicePrincipal       = { required = ["clientId", "clientSecret", "tenantId"], optional = [] }
    UsernamePassword       = { required = ["username", "password"], optional = ["securityToken"] }
  }
  oauth2_category_fields = {
    Concur         = ["authUrl", "username", "password"]
    GoogleAdWords  = ["developerToken", "refreshToken"]
    GoogleBigQuery = ["refreshToken"]
    Hubspot        = ["refreshToken"]
    QuickBooks     = ["refreshToken", "tenantId"]
    Square         = ["refreshToken"]
    Xero           = ["refreshToken", "tenantId"]
    Zoho           = ["refreshToken"]
  }
  standard_categories = toset([
    "ADLSGen2", "AIServices", "AmazonMws", "AmazonRdsForOracle", "AmazonRdsForSqlServer",
    "AmazonRedshift", "AmazonS3Compatible", "ApiKey", "AzureBlob", "AzureDatabricksDeltaLake",
    "AzureDataExplorer", "AzureMariaDb", "AzureMySqlDb", "AzureOneLake", "AzureOpenAI",
    "AzurePostgresDb", "AzureSqlDb", "AzureSqlMi", "AzureSynapseAnalytics", "AzureTableStorage",
    "BingLLMSearch", "Cassandra", "CognitiveSearch", "CognitiveService", "Concur",
    "ContainerRegistry", "CosmosDb", "CosmosDbMongoDbApi", "Couchbase", "CustomKeys", "Db2",
    "Drill", "Dynamics", "DynamicsAx", "DynamicsCrm", "Elasticsearch", "Eloqua", "FileServer",
    "FtpServer", "GenericContainerRegistry", "GenericHttp", "GenericRest", "Git", "GoogleAdWords",
    "GoogleBigQuery", "GoogleCloudStorage", "Greenplum", "Hbase", "Hdfs", "Hive", "Hubspot",
    "Impala", "Informix", "Jira", "Magento", "ManagedOnlineEndpoint", "MariaDb", "Marketo",
    "MicrosoftAccess", "MongoDbAtlas", "MongoDbV2", "MySql", "Netezza", "ODataRest", "Odbc",
    "Office365", "OpenAI", "Oracle", "OracleCloudStorage", "OracleServiceCloud", "PayPal",
    "Phoenix", "Pinecone", "PostgreSql", "Presto", "PythonFeed", "QuickBooks", "Redis",
    "Responsys", "S3", "Salesforce", "SalesforceMarketingCloud", "SalesforceServiceCloud",
    "SapBw", "SapCloudForCustomer", "SapEcc", "SapHana", "SapOpenHub", "SapTable", "Serp",
    "Serverless", "ServiceNow", "Sftp", "SharePointOnlineList", "Shopify", "Snowflake", "Spark",
    "SqlServer", "Square", "Sybase", "Teradata", "Vertica", "WebTable", "Xero", "Zoho",
  ])
  category_properties = merge(
    { for category in local.standard_categories : category => {
      metadata = var.metadata
    } },
    { for category in local.azure_metadata_categories : category => {
      metadata = merge({ ApiType = "Azure" }, var.metadata)
    } },
    {
      ApiManagement = {
        audience      = var.audience
        isSharedToAll = false
        metadata = merge(var.metadata, {
          deploymentInPath = "false"
          models = jsonencode([
            for deployment_name, model in var.models : {
              name = deployment_name
              properties = {
                model = {
                  name    = model.model_name
                  version = model.model_version
                  format  = model.model_format
                }
              }
            }
          ])
        })
      }
    },
  )
  authentication_properties = merge(
    { for auth_type in keys(local.credential_fields) : auth_type => { authType = auth_type } },
    { ProjectManagedIdentity = { authType = "ProjectManagedIdentity", credentials = {} } },
  )
  connection_bodies = {
    for category, properties in local.category_properties : category => {
      properties = merge({
        category = category
        target   = var.target
        }, properties, local.authentication_properties[var.auth_type], var.is_shared_to_all == null ? {} : {
        isSharedToAll = var.is_shared_to_all
      })
    }
  }
  sensitive_bodies = merge(
    { for auth_type in keys(local.credential_fields) : auth_type => {
      properties = { credentials = var.credentials }
    } if !contains(["AAD", "None", "ProjectManagedIdentity", "CustomKeys"], auth_type) },
    {
      AAD                    = null
      None                   = null
      ProjectManagedIdentity = null
      CustomKeys             = { properties = { credentials = { keys = var.credentials } } }
    },
  )
}
