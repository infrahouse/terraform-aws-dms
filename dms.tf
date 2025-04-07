### Migration
data "aws_secretsmanager_secret" "source_admin" {
  arn = data.aws_db_instance.source.master_user_secret[0]["secret_arn"]
}

data "aws_secretsmanager_secret_version" "source_admin" {
  secret_id = data.aws_secretsmanager_secret.source_admin.id
}

data "aws_secretsmanager_secret" "target_admin" {
  arn = data.aws_db_instance.target.master_user_secret[0]["secret_arn"]
}

data "aws_secretsmanager_secret_version" "target_admin" {
  secret_id = data.aws_secretsmanager_secret.target_admin.id
}

resource "aws_dms_endpoint" "source" {
  endpoint_id   = "source"
  endpoint_type = "source"
  engine_name   = data.aws_db_instance.source.engine
  username      = jsondecode(data.aws_secretsmanager_secret_version.source_admin.secret_string)["username"]
  password      = jsondecode(data.aws_secretsmanager_secret_version.source_admin.secret_string)["password"]
  server_name   = data.aws_db_instance.source.address
  port          = data.aws_db_instance.source.port
  database_name = data.aws_db_instance.source.db_name
}


resource "aws_dms_endpoint" "target" {
  endpoint_id                 = "targeted"
  endpoint_type               = "target"
  engine_name                 = data.aws_db_instance.target.engine
  username                    = jsondecode(data.aws_secretsmanager_secret_version.target_admin.secret_string)["username"]
  password                    = jsondecode(data.aws_secretsmanager_secret_version.target_admin.secret_string)["password"]
  server_name                 = data.aws_db_instance.target.address
  port                        = data.aws_db_instance.target.port
  extra_connection_attributes = "Initstmt=SET FOREIGN_KEY_CHECKS=0;"

}

resource "aws_dms_replication_subnet_group" "dms" {
  replication_subnet_group_description = "migration"
  replication_subnet_group_id          = "migration"
  subnet_ids                           = data.aws_db_subnet_group.source.subnet_ids
}

locals {
  dms_instance_id = "dms"
}

resource "aws_dms_replication_instance" "dms" {
  replication_instance_class  = "dms.c5.4xlarge"
  replication_instance_id     = local.dms_instance_id
  vpc_security_group_ids      = data.aws_db_instance.source.vpc_security_groups
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms.id
  depends_on = [
    aws_iam_role_policy_attachment.dms-access-for-endpoint-AmazonDMSRedshiftS3Role,
    aws_iam_role_policy_attachment.dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole,
    aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole,
    aws_cloudwatch_log_group.dms-tasks
  ]
}

resource "aws_dms_replication_task" "dms" {
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.dms.replication_instance_arn
  replication_task_id      = "migration"
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  start_replication_task   = true
  table_mappings = jsonencode(
    {
      rules : [
        {
          rule-type : "selection",
          rule-id : 1,
          rule-name : "1",
          object-locator : {
            schema-name : data.aws_db_instance.source.engine == "postgres" ? "public" : data.aws_db_instance.source.db_name,
            table-name : "%"
          },
          rule-action : "include"
        }
      ]
    }
  )
  # default + logging
  replication_task_settings = jsonencode(
    {
      "Logging" : {
        "EnableLogging" : true,
        "EnableLogContext" : true,
        "LogComponents" : [
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "DATA_STRUCTURE"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "COMMUNICATION"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "IO"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "COMMON"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "FILE_FACTORY"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "FILE_TRANSFER"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "REST_SERVER"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "ADDONS"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "TARGET_LOAD"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "TARGET_APPLY"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "SOURCE_UNLOAD"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "SOURCE_CAPTURE"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "TRANSFORMATION"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "SORTER"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "TASK_MANAGER"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "TABLES_MANAGER"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "METADATA_MANAGER"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "PERFORMANCE"
          },
          {
            "Severity" : "LOGGER_SEVERITY_DEFAULT",
            "Id" : "VALIDATOR_EXT"
          }
        ]
      },
      "StreamBufferSettings" : {
        "StreamBufferCount" : 3,
        "CtrlStreamBufferSizeInMB" : 5,
        "StreamBufferSizeInMB" : 8
      },
      "ErrorBehavior" : {
        "FailOnNoTablesCaptured" : true,
        "ApplyErrorUpdatePolicy" : "LOG_ERROR",
        "FailOnTransactionConsistencyBreached" : true, # default - false
        "RecoverableErrorThrottlingMax" : 1800,
        "DataErrorEscalationPolicy" : "SUSPEND_TABLE",
        "ApplyErrorEscalationCount" : 0,
        "RecoverableErrorStopRetryAfterThrottlingMax" : true,
        "RecoverableErrorThrottling" : true,
        "ApplyErrorFailOnTruncationDdl" : true, # default - false
        "DataMaskingErrorPolicy" : "STOP_TASK",
        "DataTruncationErrorPolicy" : "LOG_ERROR",
        "ApplyErrorInsertPolicy" : "LOG_ERROR",
        "EventErrorPolicy" : "IGNORE",
        "ApplyErrorEscalationPolicy" : "LOG_ERROR",
        "RecoverableErrorCount" : -1,
        "DataErrorEscalationCount" : 0,
        "TableErrorEscalationPolicy" : "STOP_TASK",
        "RecoverableErrorInterval" : 5,
        "ApplyErrorDeletePolicy" : "IGNORE_RECORD",
        "TableErrorEscalationCount" : 0,
        "FullLoadIgnoreConflicts" : false, # default - true
        "DataErrorPolicy" : "LOG_ERROR",
        "TableErrorPolicy" : "SUSPEND_TABLE"
      },
      "TTSettings" : {
        "TTS3Settings" : null,
        "TTRecordSettings" : null,
        "EnableTT" : false
      },
      "FullLoadSettings" : {
        "CommitRate" : 10000,
        "StopTaskCachedChangesApplied" : false,
        "StopTaskCachedChangesNotApplied" : false,
        "MaxFullLoadSubTasks" : 8,
        "TransactionConsistencyTimeout" : 600,
        "CreatePkAfterFullLoad" : false,
        "TargetTablePrepMode" : "TRUNCATE_BEFORE_LOAD" # TRUNCATE_BEFORE_LOAD
      },
      "TargetMetadata" : {
        "ParallelApplyBufferSize" : 0,
        "ParallelApplyQueuesPerThread" : 0,
        "ParallelApplyThreads" : 0,
        "TargetSchema" : "",
        "InlineLobMaxSize" : 64, # default - 0
        "ParallelLoadQueuesPerThread" : 0,
        "SupportLobs" : true,
        "TaskRecoveryTableEnabled" : false,
        "ParallelLoadThreads" : 0,
        "LobMaxSize" : 32,
        "BatchApplyEnabled" : false,
        "FullLobMode" : true,         # default - false
        "LobChunkSize" : 20000,       # default - 64
        "LimitedSizeLobMode" : false, # LimitedSizeLobMode: true → This should be false when FullLobMode is enabled.
        "LoadMaxFileSize" : 0,
        "ParallelLoadBufferSize" : 0
      },
      "BeforeImageSettings" : null,
      "ControlTablesSettings" : {
        "historyTimeslotInMinutes" : 5,
        "HistoryTimeslotInMinutes" : 5,
        "StatusTableEnabled" : false,
        "SuspendedTablesTableEnabled" : false,
        "HistoryTableEnabled" : false,
        "ControlSchema" : "",
        "FullLoadExceptionTableEnabled" : false
      },
      "LoopbackPreventionSettings" : null,
      "CharacterSetSettings" : null,
      "FailTaskWhenCleanTaskResourceFailed" : false,
      "ChangeProcessingTuning" : {
        "StatementCacheSize" : 50,
        "CommitTimeout" : 1,
        "RecoveryTimeout" : -1,
        "BatchApplyPreserveTransaction" : true,
        "BatchApplyTimeoutMin" : 1,
        "BatchSplitSize" : 0,
        "BatchApplyTimeoutMax" : 30,
        "MinTransactionSize" : 1000,
        "MemoryKeepTime" : 60,
        "BatchApplyMemoryLimit" : 500,
        "MemoryLimitTotal" : 1024
      },
      "ChangeProcessingDdlHandlingPolicy" : {
        "HandleSourceTableDropped" : true,
        "HandleSourceTableTruncated" : true,
        "HandleSourceTableAltered" : true
      },
      "ValidationSettings" : {
        "EnableValidation" : true
      },
      "PostProcessingRules" : null
    }
  )
  depends_on = [
    aws_cloudwatch_log_group.dms-tasks
  ]
}

resource "aws_cloudwatch_log_group" "dms-tasks" {
  name = "dms-tasks-${local.dms_instance_id}"
}
