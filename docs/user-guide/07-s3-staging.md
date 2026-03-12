# 07 — S3 Staging (Presigned URLs Only)

This lab uses an S3 bucket as a **staging server** for tools and lab payload artifacts.

Portfolio goal:
* Keep the bucket private-by-default and use **short-lived presigned URLs** for controlled downloads.

## Source of Truth

This repository includes:

* `docs/s3_inventory.txt` — a point-in-time inventory of objects in the bucket
* `docs/beacon_commands.txt` — download examples that intentionally use `<PRESIGNED_URL_...>` placeholders

## Why Presigned URLs

Presigned URLs help you:

* avoid public bucket/object exposure
* limit download windows (time-bound URLs)
* keep a clean separation between “what exists in staging” and “who can fetch it”

## Generate URL List (15 Minutes)

Prerequisites:

* AWS CLI configured on the operator machine
* IAM permission to `s3:GetObject` on the bucket

Workflow:

1) Determine the bucket name (this repo defaults to `redteam-lab-payloads`):
   * From Terraform (recommended): `terraform -chdir=RED-TEAM-Labs/CORE output -raw payloads_bucket_name`
   * Or use the default: `redteam-lab-payloads`
2) Generate a URL list from the inventory (15 minutes):
   * `scripts/presign_from_inventory.sh --bucket redteam-lab-payloads`
2) Use the resulting file:
   * `docs/presigned_urls.txt`
3) Copy the specific URL(s) you need into your lab workflow where placeholders appear.

Notes:
* URLs expire after 900 seconds by default.
* Regenerate whenever needed (that is the intended model).

Optional:
* Customize expiry (seconds), e.g. 1 hour (3600): `scripts/presign_from_inventory.sh --bucket redteam-lab-payloads --expires 3600`

## Recommended Bucket Posture (Portfolio-Grade)

In this repository, the Terraform configuration hardens the bucket (without destroying it):

* Block Public Access enabled
* Default server-side encryption enabled
* Versioning enabled

## Operational Hygiene (Lab-Only)

Recommended patterns:

* Keep “commodity tools” and “exercise artifacts” separated by prefixes (e.g. `tools/`, `p/`, `l/`, `w/`).
* Avoid staging sensitive client data in this bucket.
* If you need to show portfolio screenshots, redact bucket names and any sensitive object keys.
