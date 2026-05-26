# AspenCloud2-EOP-AI
Seed Project to learn from David's team

```mermaid
flowchart TD

%% =========================
%% 1. LOCAL SETUP
%% =========================
A[Local Machine<br/>Azure CLI + Terraform + Kubelogin]
   --> B[az login / Select Subscription]

B --> C[Service Principal<br/>(aks_aad_sp_client_id + secret)]
C --> D[Azure Subscription<br/>Roles + Providers]

%% =========================
%% 2. TERRAFORM DEPLOYMENT
%% =========================
D --> E[Terraform Init + Apply]

E --> F[Infrastructure Created]

F --> F1[AKS Cluster]
F --> F2[Networking]
F --> F3[Key Vault]
F --> F4[Monitoring]
F --> F5[Application Gateway]

%% =========================
%% 3. IDENTITY SETUP
%% =========================
G[Entra ID] 

G --> G1[App Registration<br/>(oidc_idp_client_id)]
G --> G2[Client Secret<br/>(oidc_idp_client_secret)]
G --> G3[API Permission<br/>User.Read]
G --> G4[Groups Claim Enabled]

G --> G5[Entra Groups]
G5 --> G51[Cluster Admins]
G5 --> G52[KeyVault Admins]
G5 --> G53[Secret Readers]

%% =========================
%% 4. INTEGRATION
%% =========================
F1 --> H[AKS ↔ Entra ID Integration (OIDC)]

%% =========================
%% 5. RUNTIME FLOW
%% =========================
I[User Login (SSO)] --> J[Entra ID Authenticates]

J --> K[JWT Token Issued]

K --> K1[User Info (User.Read)]
K --> K2[Group IDs (Groups Claim)]

K --> L[AKS Receives Token]

L --> M[RBAC Mapping]

M --> M1[Cluster Admins → Full Access]
M --> M2[KV Admins → Secret Management]
M --> M3[Readers → Read-only Access]

M --> N[Platform Access ✅]

%% =========================
%% 6. GITOPS
%% =========================
O[GitHub Repo (GitOps)]
O --> P[Cluster Sync Loop]
P --> F1
```
