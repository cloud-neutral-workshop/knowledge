# ID & Security-workshop : GitHub Actions OIDC 构建无密钥 CI/CD

## Task01: ID & Security-workshop : GitHub Actions OIDC 构建无密钥 CI/CD

> 文件：`knowledge/content/00-global/workshops/id-security/01-github-actions-oidc-passwordless-ci-cd.md`  
> 关联仓库：
> - https://github.com/Cloud-Neutral-Workshop/gitops.git
> - https://github.com/Cloud-Neutral-Workshop/playbooks.git
> - https://github.com/Cloud-Neutral-Workshop/iac_modules.git
> - https://github.com/Cloud-Neutral-Workshop/artifacts.git

---

## 目标

用 **GitHub Actions OIDC** 替代 **AccessKey/SecretKey**，构建一条真正“无密钥”的 CI/CD 链路，达到：

- CI **不保存任何长期云密钥**
- 云侧权限 **最小化**（Least Privilege）
- 身份 **强约束到 repo / branch / workflow**
- 凭证 **运行时生成**、任务结束后自动失效
- 具备“受控逃逸”（Break-glass AccessKey）思路，但不作为日常供电

本篇以 **AWS** 作为示例平台（OIDC 生态最成熟），但整体方法可迁移到其他云的 OIDC 能力。

---

## 前提

### GitHub
- 你有一个 GitHub 仓库用于放 CI（推荐：在 `Cloud-Neutral-Workshop` 组织内新建一个 workshop 仓库，例如 `workshop-oidc-ci`）
- 你可以创建/修改 `.github/workflows/*.yml`

### AWS（示例平台）
- 你有一个 AWS 账号，并具备创建 IAM Identity Provider、IAM Role、IAM Policy 的权限
- 你知道要把部署权限给到哪个 Role（例如 `gh-actions-deploy-role`）

### 本系列仓库如何用到（本篇会用到的部分）
- `iac_modules`: 用来承载/演示 IaC（Terraform）在 CI 中的执行（示例：`terraform plan/apply`）
- `artifacts`: 用来承载/演示 CI 生成的制品（可选：后续 Task 会用更完整的制品链路）
- `gitops` / `playbooks`: 本篇不强依赖，但会在“结果/下一步”说明如何衔接到 GitOps 与主机侧自动化

---

## Step by Step

### Step 0：新建/准备一个 CI 仓库（推荐做法）

> 你可以用一个独立仓库专门做这篇 workshop（例如 `workshop-oidc-ci`），避免在生产仓库里试错。

仓库目录建议结构：

.
├── iac/ # 放 Terraform 示例（可以从 iac_modules 拿一份模板）
└── .github/workflows/


---

### Step 1：AWS 创建 GitHub OIDC Provider（账号级，一次配置全局复用）

在 AWS IAM 控制台创建 **OpenID Connect provider**：

- Provider URL：`https://token.actions.githubusercontent.com`
- Audience：`sts.amazonaws.com`

验证点：
- IAM → Identity providers 里能看到 `token.actions.githubusercontent.com`
- Audience 包含 `sts.amazonaws.com`

---

### Step 2：AWS 创建 Deploy Role（只信任 GitHub OIDC，并强约束上下文）

创建 IAM Role，例如：`gh-actions-deploy-role`

#### 2.1 Trust Policy（信任策略：核心！）

把下面变量替换为你的实际信息：

- `<ACCOUNT_ID>`：AWS 账号
- `OWNER/REPO`：GitHub 仓库（例如 `Cloud-Neutral-Workshop/workshop-oidc-ci`）
- `refs/heads/main`：允许的分支（建议先仅 main）

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}


为什么要这样约束（只给结论不讲理论）：

aud 锁死到 AWS STS

sub 锁死到 指定 repo + 指定分支

这样即使别人拿到了你的 workflow 文件，也无法“随便找个仓库”来 assume 你的 role

验证点：

Role 创建成功

Trust Policy 中至少包含 aud 与 sub 的约束

2.2 Permission Policy（权限策略：先能跑通，再收敛）

先给一个“可运行但不夸张”的最小集合（你按实际 Terraform 资源调整）：

如果你 Terraform 只做基础 S3/DynamoDB state：只给 S3 + DynamoDB + KMS（如需）

如果要创建 VPC/EC2 等：增加对应服务权限

建议实践：

不要一上来就 AdministratorAccess

跑通后用 CloudTrail + Terraform plan 的资源清单逐步收敛

Step 3：GitHub Actions workflow 开启 OIDC 权限（必须显式声明）

在 workflow 顶部声明：

permissions:
  id-token: write
  contents: read


验证点：

没有 id-token: write 会直接拿不到 OIDC token，后续步骤会失败

Step 4：在 GitHub Actions 中通过 OIDC AssumeRole（无 AccessKey）

创建文件：.github/workflows/oidc-whoami.yml

先用 sts get-caller-identity 做“链路自检”，不要一上来就跑 terraform。

name: OIDC - No Key CI (WhoAmI)

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  whoami:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/gh-actions-deploy-role
          aws-region: ap-northeast-1

      - name: Verify identity
        run: aws sts get-caller-identity


验证点（最关键）：

Job 成功

输出身份是 AssumedRole，且 Role 名称正确

仓库 Settings → Secrets 里 没有任何 AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY

Step 5（可选）：把 IaC（Terraform）接到同一条无密钥链路

你可以从 iac_modules 中挑一个最小 Terraform 示例放到本仓库 iac/ 下（或直接把 iac_modules 作为 submodule 引用——看你团队习惯）。

下面是 workflow 的最小骨架：terraform plan（PR）+ terraform apply（main）

创建：.github/workflows/oidc-terraform.yml

name: OIDC - Terraform Pipeline

on:
  pull_request:
    branches: [ "main" ]
  push:
    branches: [ "main" ]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: iac
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/gh-actions-deploy-role
          aws-region: ap-northeast-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform fmt
        run: terraform fmt -check

      - name: Terraform init
        run: terraform init

      - name: Terraform validate
        run: terraform validate

      - name: Terraform plan
        if: github.event_name == 'pull_request'
        run: terraform plan

      - name: Terraform apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve


验证点：

PR 会产出 plan

合并到 main 后会 apply

全程无 AccessKey

Step 6（推荐）：受控逃逸（Break-glass AccessKey）只当保险丝

工程上你可以保留一套“应急 AccessKey”，但要满足：

默认不用

需要人工审批才能启用

权限更小、审计更强

最低成本实现（推荐做法）：

在 GitHub 开启 Environment：break-glass

设置 required reviewers（必须审批）

只在 workflow_dispatch 的 workflow 中引用该 environment 的 secrets

用完立刻轮换/禁用

注意：这一步是“治理设计”，不是日常路径。日常路径永远走 OIDC。

结果

完成本 Task 后，你将拥有：

一条可运行的 无密钥 CI（OIDC → AssumeRole）
云侧权限被严格收敛到：指定仓库 + 指定分支（可进一步到 workflow/environment）
CI 侧无需保存任何长期云凭证

后续可以自然衔接到本系列仓库的更大闭环：

下一步怎么连到这四个仓库（路线图）

iac_modules：把 Terraform 模块化，CI 直接复用标准模块与目录结构
artifacts：在 CI 里生成制品（镜像、Helm chart、SBOM、签名等）并发布到 artifacts（后续 Task 会做）
gitops：把部署从“CI 直接 apply”演进成“GitOps 控制面”（ArgoCD/Flux）
playbooks：把宿主机/集群底座自动化（K3S、observability、网络等）纳入可复现体系

常见失败点（快速排错清单）

OIDC Provider 没建 / URL 或 aud 不对 → AssumeRoleWithWebIdentity 失败
workflow 没写 permissions: id-token: write → 拿不到 token
Role trust policy 没锁 sub → 风险极大（可被别的 repo/分支利用）
Role 权限不够 → WhoAmI 能过，但 Terraform/部署会报 AccessDenied（按资源清单逐步补权限）
