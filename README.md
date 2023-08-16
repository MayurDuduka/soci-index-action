# soci-index-action
soci-index-action

## **USE Example**

```
jobs:
  issue_parser:
    runs-on: ubuntu-latest
    name: Terraform destroy
    steps:
    - name: Checkout repo
        uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2 # More information on this action can be found below in the 'AWS Credentials' section
      with:
        role-to-assume: arn:aws:iam::123456789012:role/my-github-actions-role
        aws-region: aws-region-1

    - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
        with:
          mask-password: 'true'
          
    - name: Build, tag, and push docker image to Amazon ECR
      env:
        REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        REPOSITORY: my-ecr-repo
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $REGISTRY/$REPOSITORY:$IMAGE_TAG .
        docker push $REGISTRY/$REPOSITORY:$IMAGE_TAG

    - uses: MayurDuduka/soci-index-action@v1.0
      with:
        registry: ${{ steps.login-ecr.outputs.registry }}
        repo_name: 'clamav:anti-v2'
        tag_name: ${{ github.sha }}
```