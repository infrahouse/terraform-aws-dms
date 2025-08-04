import json
from os import path as osp
from textwrap import dedent

from pytest_infrahouse import terraform_apply

from tests.conftest import (
    LOG,
    TERRAFORM_ROOT_DIR,
)


def test_module(
    aurora_postgres_13,
    aurora_postgres_17,
    test_role_arn,
    keep_after,
    aws_region,
):
    terraform_module_dir = osp.join(TERRAFORM_ROOT_DIR, "dms")
    with open(osp.join(terraform_module_dir, "terraform.tfvars"), "w") as fp:
        fp.write(
            dedent(
                f"""
                    region              = "{aws_region}"
                    source_cluster_id = "{aurora_postgres_13['db_cluster_id']['value']}" 
                    target_cluster_id = "{aurora_postgres_17['db_cluster_id']['value']}"
                    
                    source_username = "{aurora_postgres_13['master_username']['value']}"
                    source_password = "{aurora_postgres_13['master_password']['value']}"
                    
                    target_username = "{aurora_postgres_17['master_username']['value']}"
                    target_password = "{aurora_postgres_17['master_password']['value']}"
                    """
            )
        )
        if test_role_arn:
            fp.write(
                dedent(
                    f"""
                    role_arn        = "{test_role_arn}"
                    """
                )
            )

    with terraform_apply(
        terraform_module_dir,
        destroy_after=not keep_after,
        json_output=True,
    ) as tf_output:
        LOG.info("%s", json.dumps(tf_output, indent=4))
