from flask import Flask, send_file, render_template
import boto3
import os
import io
import random

app = Flask(__name__)

bucket_name = os.getenv("S3_BUCKET", "stockpnl-data")
region_name = os.getenv("AWS_REGION", "eu-north-1")
s3 = boto3.client("s3", region_name=region_name)

@app.route("/")
def home():
    response = s3.list_objects_v2(Bucket=bucket_name)
    image_files = [obj["Key"] for obj in response.get("Contents", [])]

    if not image_files:
        return "No images found in the S3 bucket."

    selected_image = random.choice(image_files)

    image_url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket_name, "Key": selected_image},
        ExpiresIn=3600
    )

    return render_template("index.html", image_url=image_url)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
