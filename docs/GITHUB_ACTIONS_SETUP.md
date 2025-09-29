# 🔧 Configuração do GitHub Actions

Este guia explica como configurar os secrets necessários para o GitHub Actions funcionar corretamente.

## 📋 Secrets Necessários

### 1. AWS Credentials

Configure os seguintes secrets no repositório GitHub:

#### AWS_ACCESS_KEY_ID

- **Descrição**: Chave de acesso AWS
- **Como obter**: AWS Console → IAM → Users → Security credentials → Create access key
- **Permissões necessárias**:
  - `eks:DescribeCluster`
  - `eks:ListClusters`
  - `eks:UpdateKubeconfig`
  - `kubectl` permissions (se usando IAM roles)

#### AWS_SECRET_ACCESS_KEY

- **Descrição**: Chave secreta AWS
- **Como obter**: Gerada junto com a AWS_ACCESS_KEY_ID
- **⚠️ Importante**: Mantenha segura e não compartilhe

#### AWS_SESSION_TOKEN

- **Descrição**: Token de sessão AWS (necessário para credenciais temporárias)
- **Como obter**: Gerado junto com as credenciais temporárias
- **⚠️ Importante**: Necessário quando usando credenciais temporárias (STS)

#### AWS_REGION

- **Descrição**: Região AWS onde está o cluster EKS
- **Exemplo**: `us-east-1`

#### CLUSTER_NAME

- **Descrição**: Nome do cluster EKS (fixo como "hacka_cluster")
- **Valor**: `hacka_cluster`
- **Status**: Não é mais necessário como secret

## 🔐 Como Configurar os Secrets

### 1. Acesse as Configurações do Repositório

1. Vá para o repositório no GitHub
2. Clique em **Settings**
3. No menu lateral, clique em **Secrets and variables**
4. Clique em **Actions**

### 2. Adicione os Secrets

Para cada secret:

1. Clique em **New repository secret**
2. Digite o **Name** (ex: `AWS_ACCESS_KEY_ID`)
3. Digite o **Value** (ex: `AKIA...`)
4. Clique em **Add secret**

### 3. Secrets Obrigatórios

Secrets obrigatórios:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

Configurações fixas (não são secrets):

- `AWS_REGION`: `us-east-1`
- `CLUSTER_NAME`: `hacka_cluster`

## 🚀 Workflows Disponíveis

### 1. Deploy (deploy.yml)

**Triggers:**

- Push para branches `main` ou `develop`
- Mudanças em arquivos `terraform/**`, `grafana/**`, ou `.github/workflows/deploy.yml`
- Execução manual via `workflow_dispatch`

**Funcionalidades:**

- Deploy automático da stack de observabilidade
- Verificação pós-deploy
- Suporte a múltiplos ambientes (dev, staging, prod)

### 2. Destroy (destroy.yml)

**Triggers:**

- Execução manual via `workflow_dispatch`
- Requer confirmação digitando "DESTROY"

**Funcionalidades:**

- Destrói toda a infraestrutura de observabilidade
- Verificação de destruição

### 3. Validate (validate.yml)

**Triggers:**

- Pull requests para `main` ou `develop`
- Push para `main` ou `develop`
- Mudanças em arquivos `terraform/**` ou `grafana/**`

**Funcionalidades:**

- Validação de formato do Terraform
- Validação de sintaxe
- Plan para verificar mudanças

## 🔧 Configuração Simplificada

### Ambiente Único

O projeto usa apenas um ambiente: **prod**

- Todas as configurações vêm dos secrets do GitHub
- Não há necessidade de configurar environments separados
- Deploy direto para produção

## 📊 Monitoramento dos Workflows

### 1. Verificar Status

- Vá para a aba **Actions** no repositório
- Veja o status dos workflows em execução
- Clique em um workflow para ver detalhes

### 2. Logs e Debugging

- Clique em um job para ver os logs
- Use os logs para identificar problemas
- Verifique se os secrets estão configurados corretamente

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. "AWS credentials not found"

```
Error: No AWS credentials found
```

**Solução**: Verifique se `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` estão configurados

#### 2. "Cluster not found"

```
Error: cluster "hacka_cluster" not found
```

**Solução**: Verifique se `CLUSTER_NAME` está correto ou se o cluster existe

#### 3. "Permission denied"

```
Error: User is not authorized to perform: eks:DescribeCluster
```

**Solução**: Verifique as permissões IAM do usuário AWS

#### 4. "Terraform init failed"

```
Error: Failed to initialize Terraform
```

**Solução**: Verifique se o cluster EKS está acessível e as credenciais estão corretas

### Comandos de Debug

```bash
# Verificar secrets (apenas para debugging local)
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
echo $AWS_SESSION_TOKEN

# Testar conectividade AWS
aws sts get-caller-identity

# Testar conectividade EKS
aws eks describe-cluster --name hacka_cluster --region us-east-1
```

## 🔒 Segurança

### Boas Práticas

1. **Use IAM Roles** quando possível em vez de access keys
2. **Rotacione as chaves** regularmente
3. **Use environments** para separar dev/staging/prod
4. **Configure protection rules** para ambientes de produção
5. **Monitore o uso** das credenciais

### IAM Policy Mínima

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:UpdateKubeconfig"
      ],
      "Resource": "*"
    }
  ]
}
```

## 📚 Links Úteis

- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
