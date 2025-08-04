import json
import logging
from os import path as osp
from pprint import pprint
from subprocess import run
from tempfile import NamedTemporaryFile
from textwrap import dedent
from time import sleep

import psycopg2
from psycopg2 import sql as psql
from psycopg2 import OperationalError
import pytest
from infrahouse_core.logging import setup_logging
from infrahouse_core.timeout import timeout
from pytest_infrahouse import terraform_apply
from requests import get

DEFAULT_PROGRESS_INTERVAL = 10
TERRAFORM_ROOT_DIR = "test_data"


LOG = logging.getLogger(__name__)


setup_logging(LOG, debug=True)


def load_data(host, user, password, dbname, port=5432):
    cmd = [
        "/opt/homebrew/opt/postgresql@13/bin/psql",
        "-v",
        "ON_ERROR_STOP=1",
        "-X",
        "-h",
        host,
        "-p",
        str(port),
        "-U",
        user,
        "-d",
        dbname,
    ]

    run(
        cmd,
        env={"PGPASSWORD": password},
        stdin=open("tests/files/00-drop-tables.sql"),
        check=True,
    )

    response = get(
        "https://github.com/infrahouse/terraform-aws-dms/releases/download/assets/omdb-orig.sql",
        timeout=300,
    )
    response.raise_for_status()
    run(
        cmd,
        env={"PGPASSWORD": password},
        input=response.text,
        check=True,
        text=True,
    )


@pytest.fixture()
def aurora_postgres_13(
    service_network, keep_after, test_role_arn, aws_region, boto3_session
):
    print(service_network)
    subnet_ids = json.dumps(service_network["subnet_public_ids"]["value"])
    terraform_module_dir = osp.join(TERRAFORM_ROOT_DIR, "aurora-postgres-13")
    # Create service network
    with open(osp.join(terraform_module_dir, "terraform.tfvars"), "w") as fp:
        fp.write(
            dedent(
                f"""
                role_arn     = "{test_role_arn}"
                region       = "{aws_region}"
                subnet_ids   = {subnet_ids} 
                """
            )
        )
    with terraform_apply(
        terraform_module_dir,
        destroy_after=not keep_after,
        json_output=True,
    ) as tf_output:
        client = boto3_session.client("rds", region_name=aws_region)
        db_cluster_engine_version = tf_output["db_cluster_engine_version"]["value"]
        LOG.info(
            "Waiting for Aurora Postgres %s cluster to be ready...",
            db_cluster_engine_version,
        )
        with timeout(3600):
            while True:
                response = client.describe_db_clusters(
                    DBClusterIdentifier=tf_output["db_cluster_id"]["value"]
                )
                status = response["DBClusters"][0]["Status"]
                if status == "available":
                    LOG.info(
                        "Aurora Postgres %s cluster is ready.",
                        db_cluster_engine_version,
                    )
                    break
                else:
                    LOG.info("The cluster is %s, waiting", status)
                    sleep(5)

        LOG.info(
            "Waiting for Aurora Postgres %s instances to be ready...",
            db_cluster_engine_version,
        )
        with timeout(3600):
            while True:
                response = client.describe_db_instances(
                    Filters=[
                        {
                            "Name": "db-cluster-id",
                            "Values": [
                                tf_output["db_cluster_id"]["value"],
                            ],
                        },
                    ],
                )
                db_instances = response["DBInstances"]
                statuses = set([i["DBInstanceStatus"] for i in db_instances])
                if db_instances and statuses == {"available"}:
                    LOG.info(
                        "The Aurora Postgres %s instances are ready.",
                        db_cluster_engine_version,
                    )
                    break
                else:
                    LOG.info("The instances are %s, waiting", statuses)
                    sleep(5)
        load_data(
            tf_output["db_cluster_endpoint"]["value"],
            tf_output["master_username"]["value"],
            tf_output["master_password"]["value"],
            tf_output["db_cluster_db_name"]["value"],
            tf_output["db_cluster_port"]["value"],
        )

        yield tf_output


@pytest.fixture()
def aurora_postgres_17(
    service_network, keep_after, test_role_arn, aws_region, boto3_session
):
    subnet_ids = json.dumps(service_network["subnet_public_ids"]["value"])
    terraform_module_dir = osp.join(TERRAFORM_ROOT_DIR, "aurora-postgres-17")
    # Create service network
    with open(osp.join(terraform_module_dir, "terraform.tfvars"), "w") as fp:
        fp.write(
            dedent(
                f"""
                role_arn     = "{test_role_arn}"
                region       = "{aws_region}"
                subnet_ids   = {subnet_ids} 
                """
            )
        )
    with terraform_apply(
        terraform_module_dir,
        destroy_after=not keep_after,
        json_output=True,
    ) as tf_output:
        client = boto3_session.client("rds", region_name=aws_region)
        db_cluster_engine_version = tf_output["db_cluster_engine_version"]["value"]
        LOG.info(
            "Waiting for Aurora Postgres %s cluster to be ready...",
            db_cluster_engine_version,
        )
        with timeout(3600):
            while True:
                response = client.describe_db_clusters(
                    DBClusterIdentifier=tf_output["db_cluster_id"]["value"]
                )
                status = response["DBClusters"][0]["Status"]
                if status == "available":
                    LOG.info(
                        "Aurora Postgres %s cluster is ready.",
                        db_cluster_engine_version,
                    )
                    break
                else:
                    LOG.info("The cluster is %s, waiting", status)
                    sleep(5)

        LOG.info(
            "Waiting for Aurora Postgres %s instances to be ready...",
            db_cluster_engine_version,
        )
        with timeout(3600):
            while True:
                response = client.describe_db_instances(
                    Filters=[
                        {
                            "Name": "db-cluster-id",
                            "Values": [
                                tf_output["db_cluster_id"]["value"],
                            ],
                        },
                    ],
                )
                db_instances = response["DBInstances"]
                statuses = set([i["DBInstanceStatus"] for i in db_instances])
                if db_instances and statuses == {"available"}:
                    LOG.info(
                        "The Aurora Postgres %s instances are ready.",
                        db_cluster_engine_version,
                    )
                    break
                else:
                    LOG.info("The instances are %s, waiting", statuses)
                    sleep(5)

        yield tf_output
