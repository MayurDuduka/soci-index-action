# soci-index-action
soci-index-action

## **USE Example**

```
name: SOCI-INDEX
on:
  workflow_dispatch:
  push:

jobs:
  compile:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      id-token: write
    steps:
      - uses: actions/checkout@v3
      - name: Configure AWS Credentials
        id: login-aws
        uses: aws-actions/configure-aws-credentials@v2
        with:
        #   role-to-assume:  ${{ secrets.AWS_ROLE_ARN }}
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
        with:
          mask-password: 'true'
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      - name: Create SOCI INDEX
        uses: MayurDuduka/soci-index-action@v4.4
        with:
          registry: ${{ steps.login-ecr.outputs.registry }}
          registry_password: ${{ steps.login-ecr.outputs[format('docker_password_{0}_dkr_ecr_eu_central_1_amazonaws_com', steps.login-aws.outputs.aws-account-id)] }}
          repo_name: 'ECR_Repository_NAME'
          tag_name: 'TAG_NAME'
```

References:
- https://aws.amazon.com/blogs/aws/aws-fargate-enables-faster-container-startup-using-seekable-oci/
- https://aws.amazon.com/about-aws/whats-new/2023/07/aws-fargate-container-startup-seekable-oci/
- https://aws.amazon.com/about-aws/whats-new/2022/09/introducing-seekable-oci-lazy-loading-container-images/