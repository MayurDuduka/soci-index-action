# SOCI Index Action

Create a **Seekable OCI (SOCI)** index for an existing container image so your workloads can **lazy‑load** layers and start faster. This action is designed for **Amazon ECR** registries and pairs well with AWS services that support SOCI (e.g., EKS/Karpenter with lazy image pulling).

> **What's SOCI?** Seekable OCI produces a separate *index artifact* that allows container runtimes to fetch only the blocks they need from large layers, improving cold‑start times.

---

## ✨ Features

* Generates a SOCI index for a given `repo:tag`
* Works with private images in **Amazon ECR**
* No local image pull required
* Simple, secure auth using official AWS login actions

---

## 🚀 Quick Start

Copy this minimal workflow to `.github/workflows/soci-index.yml`:

```yaml
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
          # role-to-assume:  ${{ secrets.AWS_ROLE_ARN }}
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

      - run: echo "__AWS_REGION__=$(echo "${{ secrets.AWS_REGION }}" | tr '-' '_')" >> $GITHUB_ENV

      - name: Create SOCI INDEX
        uses: MayurDuduka/soci-index-action@v1.0
        with:
          registry: ${{ steps.login-ecr.outputs.registry }}
          registry_user: ${{ steps.login-ecr.outputs[format('docker_username_{0}_dkr_ecr_{1}_amazonaws_com', steps.login-aws.outputs.aws-account-id, env.__AWS_REGION__)] }}
          registry_password: ${{ steps.login-ecr.outputs[format('docker_password_{0}_dkr_ecr_{1}_amazonaws_com', steps.login-aws.outputs.aws-account-id, env.__AWS_REGION__)] }}
          repo_name: 'ECR_Repository_NAME'
          tag_name: 'TAG_NAME'
```

> The job generates a SOCI index for `ECR_Repository_NAME:TAG_NAME` in the same registry account/region.

---

## ⚙️ Inputs

| Name                | Required | Description                                                                                                         |
| ------------------- | :------: | ------------------------------------------------------------------------------------------------------------------- |
| `registry`          |     ✅    | Registry domain (from `aws-actions/amazon-ecr-login` output), e.g., `123456789012.dkr.ecr.ap-south-1.amazonaws.com` |
| `registry_user`     |     ✅    | Username output from the ECR login step for the specific account/region                                             |
| `registry_password` |     ✅    | Password/token output from the ECR login step for the specific account/region                                       |
| `repo_name`         |     ✅    | ECR repository name containing the image to index                                                                   |
| `tag_name`          |     ✅    | Image tag to index (e.g., `latest`, `1.2.3`)                                                                        |

> **Tip:** The example uses output keys that depend on `AWS account ID` and `region` (with dashes replaced by underscores). Keep the `__AWS_REGION__` trick in place unless you hardcode those values.

---

## 📦 Outputs

Currently, this action does not emit formal outputs. A future version may expose the created SOCI **index digest**.

---

## 🔐 Permissions & Secrets

* **Workflow permissions**

  * `id-token: write` (for OIDC, if you use `role-to-assume`)
  * `contents: write` (if the action writes back files or PRs; safe to leave enabled)
* **Required secrets**

  * `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` **or** configure OIDC with `role-to-assume`

> Prefer **OIDC** with a role that grants ECR access (pull for the image, and push for the SOCI artifact).

---

## 🧠 How it Works (High Level)

1. Authenticates to ECR using AWS official actions
2. Locates the image `registry/repo_name:tag_name`
3. Generates a SOCI index artifact for the target image
4. Pushes the SOCI index to the same registry alongside your image

This keeps your image immutable while publishing a separate index artifact that enables lazy pulls on supported platforms.

---

## ✅ Requirements

* A working image already pushed to **Amazon ECR**
* GitHub-hosted runner (`ubuntu-latest`)
* Permissions to **read** the target image and **push** artifacts to the same repository/registry

---

## 🔍 Troubleshooting

* **`no basic auth credentials`** – Ensure you pass the exact `registry_user` & `registry_password` outputs for your account/region. The dynamic output keys require the region transformation (dashes → underscores).
* **`denied: User is not authorized to perform ecr:PutImage`** – Your role/credentials need ECR permissions to upload the SOCI artifact.
* **`repository not found`** – Verify `repo_name` and account/region; confirm the image exists with the specified `tag_name`.
* **Multi‑arch images** – Index is generated per image reference. If you publish per‑arch tags, run the action for each tag.

---

## 💡 Tips

* Pair with **Karpenter** and **EKS** to realize faster pod startup via lazy image pulls.
* Automate SOCI index creation **after** publishing a new image tag in your CI.
* Consider keeping a matrix over multiple tags/arches.

---

## 🧪 Example: Matrix over tags

```yaml
strategy:
  matrix:
    tag: ["1.0.0", "1.1.0", "latest"]

steps:
  # ...same auth steps
  - name: Create SOCI INDEX
    uses: MayurDuduka/soci-index-action@v1.0
    with:
      registry: ${{ steps.login-ecr.outputs.registry }}
      registry_user: ${{ steps.login-ecr.outputs[format('docker_username_{0}_dkr_ecr_{1}_amazonaws_com', steps.login-aws.outputs.aws-account-id, env.__AWS_REGION__)] }}
      registry_password: ${{ steps.login-ecr.outputs[format('docker_password_{0}_dkr_ecr_{1}_amazonaws_com', steps.login-aws.outputs.aws-account-id, env.__AWS_REGION__)] }}
      repo_name: my-service
      tag_name: ${{ matrix.tag }}
```

---

## 🧾 Marketplace Metadata (Summary)

* **Category:** Continuous Integration / Container
* **Inputs:** `registry`, `registry_user`, `registry_password`, `repo_name`, `tag_name`
* **Works with:** Amazon ECR
* **Use cases:** Publish SOCI indexes for faster cold starts on Kubernetes/EKS

---

## 🔒 Security

If you discover a security issue, please **do not** open a public issue. Instead, contact the maintainers privately (see repository security policy if available).

---

## 🧭 Roadmap

* Publish `index_digest` as an output
* Optional support for additional registries
* Tag auto‑detection from metadata (e.g., image digest input)

---

## 🤝 Contributing

Contributions are welcome! Please open an issue to discuss large changes first. Make sure CI passes and include tests where possible.

---

## 📜 License

Distributed under the terms of the project's license. See `LICENSE` in this repository.

---

## 🙌 Support

If you run into problems or have feature requests, please open an issue with logs and your workflow snippet (scrub secrets).

---

## 📚 References

* [AWS Fargate enables faster container startup using Seekable OCI](https://aws.amazon.com/blogs/aws/aws-fargate-enables-faster-container-startup-using-seekable-oci/)
* [AWS Fargate container startup with Seekable OCI](https://aws.amazon.com/about-aws/whats-new/2023/07/aws-fargate-container-startup-seekable-oci/)
* [Introducing Seekable OCI for lazy loading container images](https://aws.amazon.com/about-aws/whats-new/2022/09/introducing-seekable-oci-lazy-loading-container-images/)
