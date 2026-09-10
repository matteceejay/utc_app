import os
import json
import boto3


def load_config(app):
    app_secret_arn = os.environ.get("APP_SECRET_ARN")
    db_secret_arn = os.environ.get("DB_SECRET_ARN")
    db_host = os.environ.get("DB_HOST")
    db_port = os.environ.get("DB_PORT", "5432")
    db_name = os.environ.get("DB_NAME")

    secret_key = None
    db_user = None
    db_password = None

    if app_secret_arn or db_secret_arn:
        client = boto3.client("secretsmanager")

        if app_secret_arn:
            app_secret = json.loads(client.get_secret_value(SecretId=app_secret_arn)["SecretString"])
            secret_key = app_secret.get("JWT_SIGNING_SECRET")

        if db_secret_arn:
            db_secret = json.loads(client.get_secret_value(SecretId=db_secret_arn)["SecretString"])
            db_user = db_secret.get("username")
            db_password = db_secret.get("password")

    app.config["SECRET_KEY"] = secret_key or "dev-only-insecure-key"

    if db_host and db_user and db_password and db_name:
        app.config["SQLALCHEMY_DATABASE_URI"] = (
            f"postgresql+psycopg2://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
        )
    else:
        # Local dev fallback - runs with no AWS access at all
        app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///local_dev.db"

    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False