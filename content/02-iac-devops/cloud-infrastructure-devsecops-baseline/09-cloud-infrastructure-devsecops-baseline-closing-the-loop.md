# 云基础设施 DevSecOps 基线方法论

现代云系统的规模与复杂性已经远超任何单一安全工具的能力边界。真正的安全从来不是“加几条扫描规则”“多装一个防火墙”这种被动补丁，而是一条**贯穿整个基础设施生命周期的隐形长线**：从 IaC 被写下的那一刻，到凭证被动态颁发、到运维访问被代理、到所有日志被自动采集……

**安全必须自然发生，而不是依赖人的记忆与习惯。**

这就是 DevSecOps 的本质：

> **让安全成为系统的默认行为，而不是人的主动动作。**

---

## DevSecOps 的最小安全闭环

将安全能力提炼为五项**跨云、可自建、可复现**的核心能力，它们共同构成完整的 DevSecOps 安全闭环：

IaC → 身份 → 凭证 → 运维入口 → 审计 → 持续验证


目标是构建一套：

- 不依赖任何云厂商特性
- 可迁移
- 可在 AWS、GCP、阿里云、VPS、IDC 中统一落地的安全体系。

---

## 🅐 IaC Security：安全从配置开始，而不是从事故开始

几乎所有云安全事故——
从外网暴露的 S3 存储桶、到错误的 CIDR、到宽松的安全组——  
本质上都是**配置意外**。

这说明：

> **IaC 安全不是检查，而是可推理性（Reasonability）。**

为此，三件事必须**强制化**：

### 1. 静态扫描（tflint / tfsec / checkov）

阻止配置文件“悄悄变坏”，提前识别：

- 加密缺失  
- 端口暴露  
- 资源未设限制  
- 高风险默认配置  

### 2. Terraform Plan 审计

Plan 是目标状态的**数学证明**。

只有以下流程才能保证基础设施透明演化：

Plan → 审核 → Apply


### 3. GitHub Environments + Branch Protection

- 禁止直推 `main`
- 所有环境需要审批
- Plan 必须可审阅

这样，“大事故”会从结构上变成**不可能事件**。

> **IaC 是整个安全链的起点，所有后续控制都无法弥补配置天然的错误。**

---

## 🅑 身份：安全体系的根必须属于企业，而不是云厂商

如果不同云使用不同身份系统，就永远无法实现：

- 跨云审计  
- 统一权限治理  

因此必须遵循一个原则：

> **企业 / 使用者自持 IdP，云厂商只能作为下游。**

### 身份下游映射关系

- AWS：IAM Identity Center  
- GCP：Cloud Identity  
- 阿里云：RAM  
- 自建 / VPS / IDC：直接使用企业 IdP  

### 推荐的企业 IdP

- Keycloak  
- Zitadel  
- Authentik  

这样才能保证：

> **“谁在访问系统”在多云环境中只有一个真相来源。**

---

## 🅒 凭证：所有权限都是临时的，密钥永不落地

长期 AccessKey 是云环境最大的毒瘤：

- 极易泄漏  
- 难以回收  
- 无法追溯  

**所有凭证都必须是短期、自动轮换、可撤销的。**

### 各环境的推荐实践

- AWS：STS AssumeRole  
- GCP：Workload Identity Federation  
- 阿里云：RAM + STS 扮演  
- 自建 / VPS / IDC：
  - Vault Dynamic Secrets  
  - SPIFFE / SPIRE  
  - JWT STS  

> **凭证短期化是安全走向工程化的关键一环。**

---

## 🅓 运维入口：零 SSH，让“人类退出生产环境”

SSH、22 端口、私钥同步，是现代系统**最大的安全盲区**。

真正的 DevSecOps 要求：

> **人访问主机必须通过受控代理，所有操作必须可审计。**

### 可落地方案

- AWS：SSM Session Manager  
- GCP：IAP + OS Login  
- 阿里云：云助手 / 堡垒机  
- 自建 / VPS / IDC：
  - Teleport  
  - WireGuard  
  - 审计 Bastion  

有了 Access Proxy：

> “人进入服务器”不再是黑箱，而是带身份、时间戳、上下文的事件记录。

---

## 🅔 审计：统一日志 + OTel，是多云安全的真正基石

每朵云的日志格式都不同，如果不做统一：

> **跨云事件将永远无法关联。**

CloudNeutral 使用 **OpenTelemetry（OTel）** 作为最小公共抽象层：

- AWS：CloudTrail → S3 → OTel Collector  
- GCP：Audit Logs → GCS → OTel Collector  
- 阿里云：ActionTrail → OSS → OTel Collector  
- 自建 / VPS / IDC：Vector / OTel → S3 / MinIO  

> 云的日志只是**信号源**，真正的审计系统必须属于企业。

---

## 🅕 持续验证：所有配置必须可扫描、可审计、可解释

IaC 安全能力完全由**开源工具链**决定：

- tflint  
- tfsec  
- checkov  
- OPA / Conftest  
- Terraform Plan 审计  

这意味着：

> **IaC 安全天然具备可迁移性。**

无论是 AWS、GCP 还是阿里云，底层依赖的都是同一类工具。

---

## 为什么这是“最小但完整”的 DevSecOps 模型

这五条能力同时满足：

1. **跨云可一致实现**
2. **在自建 IDC / VPS 环境中也能完全复现**

安全链路由此闭环：

IaC → 身份 → 凭证 → 运维入口 → 审计 → 持续验证

结果非常直接：

- 安全体系不被云厂商锁定  
- 迁云成为日常操作  
- VPS / IDC 不再是安全短板  
- 任一云宕掉都能无缝切换  
- DevSecOps 由结构保障，而非依赖人工记忆  

这正是 **云中立（Cloud-Neutral）** 的核心理念：

> **安全是一种可在任何环境中复现的能力，而不是某家云的专属功能。**

---

## 跨云 / 自建统一能力对照表

| 能力 | 能跨云吗 | 能在自建环境复现吗 | 为什么重要 |
|---|---|---|---|
| 统一 IdP | ✔ | ✔ | DevSecOps 权限体系的“根” |
| 临时凭证 | ✔ | ✔ | 密钥不落地，否则迟早泄漏 |
| 零 SSH | ✔ | ✔ | 消除最大的不透明入口 |
| 统一日志格式 | ✔ | ✔ | 跨云审计、取证、关联分析 |
| IaC 配置可扫描 / 审计 / 验证 | ✔ | ✔ | IaC 是最易出事故的起点 |

---

## 延伸主题（系列文章）

- 告别 AccessKey：GitHub Actions OIDC 构建无密钥 CI/CD
- DevSecOps 中的制品安全：为什么漏洞扫描必须前置到 CI
- 告别 AccessKey：EC2 / K3S 使用 kube2iam 构建无密钥运行时权限  
- 告别 AccessKey：EKS OIDC / IRSA 构建 Pod 级无密钥运行时权限  
- 当交付已经安全：DevSecOps 必须继续下沉  
- CloudNeutral 多云 IaC 实践：安全、合理地管理云资源
