from flask import Flask, render_template
import boto3
import os
import random

app = Flask(__name__)

bucket_name = os.getenv("S3_BUCKET")
image_folder = os.getenv("IMAGE_FOLDER", "")
aws_region = os.getenv("AWS_REGION", "eu-north-1")

# Create s3 client
s3 = boto3.client("s3", region_name=aws_region)

@app.route("/")
def home():
    # List all objects in the folder
    response = s3.list_objects_v2(Bucket=bucket_name, Prefix=image_folder)
    all_files = response.get("Contents", [])

    image_files = []

    # Loop to filter out the folder name itself
    for file in all_files:
        key = file["Key"]
        if key != image_folder:
            image_files.append(key)

    if not image_files:
        return "No images found in the S3 bucket."

    # Pick a random image to show with the hello commit
    selected_image = random.choice(image_files)

    # Generate a temporary signed URL
    # Since the bucket is private the users will be granted a url that is temporary for 1 hour
    image_url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket_name, "Key": selected_image},
        ExpiresIn=3600  # 1 hour
    )

    return render_template("index.html", image_url=image_url)

if __name__ == "__main__":
    app.run(host="0.0.0.0")
