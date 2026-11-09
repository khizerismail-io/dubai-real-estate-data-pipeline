# Dubai Real Estate Data Pipeline: Snowflake to AWS S3 Serverless Lake

An end-to-end modern data engineering pipeline that models Dubai Land Department property transactions using **dbt** in **Snowflake**, and autonomously extracts Gold-layer business aggregates into an **Amazon S3** data lake using **AWS Lambda** and **Amazon EventBridge**.

---

## Architecture Overview

```text
+-----------------------+      dbt Core       +-----------------------------+
| Raw Land Transactions |  ================>  | Snowflake Data Cloud        |
| (Dubai Land Dept)     |   (Bronze->Silver)  |  - DB: DUBAI_REAL_ESTATE    |
+-----------------------+                     |  - Schema: GOLD             |
                                              |  - Table: fct_property_sales|
                                              +--------------+--------------+
                                                             |
                                                             | (Query Execution)
                                                             v
+-----------------------+    Weekly Cron      +-----------------------------+
| Amazon EventBridge    |  ---------------->  | AWS Lambda                  |
| (Scheduler)           |    (Rule Trigger)   |  - Python 3.11 (x86_64)     |
+-----------------------+                     |  - Snowflake Connector Layer|
                                              +--------------+--------------+
                                                             |
                                                             | (boto3 JSON PutObject)
                                                             v
                                              +-----------------------------+
                                              | Amazon S3 (Data Lake)       |
                                              |  - Bucket: Gold Summary     |
                                              |  - Partition: weekly_summary|
                                              +-----------------------------+
