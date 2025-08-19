# MineAdmin Kubernetes 部署指南

## 概述

本项目提供了完整的 Kubernetes 部署方案，支持单节点和多节点集群部署。

## 功能特性

### 🚀 部署模式
- **单机模式**: 主控和节点都在一台服务器
- **集群模式**: 主控和节点分布在不同服务器

### 📦 支持的服务
- **MineAdmin 后端服务** (Hyperf + Swoole)
- **MineAdmin 前端服务** (Vue3 + Vite)
- **MySQL 数据库** (8.0)
- **Redis 缓存** (7-alpine)
- **网络插件** (Calico)

### 🔧 管理功能
- 集群状态监控
- 组件日志查看
- 配置文件生成
- 备份和恢复
- 集群升级

## 快速开始

### 1. 系统要求

- **操作系统**: Ubuntu 24.04 LTS (推荐) 或 22.04 LTS
- **架构**: x86_64 或 ARM64
- **内存**: 至少 4GB (推荐 8GB+)
- **磁盘**: 至少 20GB 可用空间
- **网络**: 稳定的网络连接

### 2. 部署命令

#### 进入 K8s 管理菜单
```bash
./docker/mineadmin.sh k8s
```

#### 直接部署 K8s 集群
```bash
./docker/mineadmin.sh k8s-deploy
```

#### 查看集群状态
```bash
./docker/mineadmin.sh k8s-status
```

#### 查看组件日志
```bash
./docker/mineadmin.sh k8s-logs
```

#### 生成配置文件
```bash
./docker/mineadmin.sh k8s-config
```

## 部署流程

### 单机模式部署

1. **系统兼容性检测**
   - 检查操作系统版本
   - 验证系统架构
   - 检测内存和磁盘空间
   - 测试网络连接

2. **安装基础组件**
   - Docker 和 containerd
   - Kubernetes 组件 (kubeadm, kubelet, kubectl)

3. **初始化集群**
   - 初始化单节点集群
   - 配置网络插件 (Calico)
   - 部署 MineAdmin 服务

4. **验证部署**
   - 检查节点状态
   - 验证 Pod 运行状态
   - 测试服务访问

### 集群模式部署

#### 主控节点部署

1. **系统准备**
   - 执行系统兼容性检测
   - 安装基础组件

2. **初始化主控节点**
   - 初始化 Kubernetes 控制平面
   - 配置网络插件
   - 部署 MineAdmin 服务

3. **生成加入信息**
   - 生成工作节点加入命令
   - 保存配置信息

#### 工作节点部署

1. **系统准备**
   - 执行系统兼容性检测
   - 安装基础组件

2. **加入集群**
   - 输入主控节点信息
   - 执行加入命令
   - 验证节点状态

## 文件结构

```
docker/k8s/
├── manifests/           # K8s 资源文件
│   ├── mysql.yaml      # MySQL 部署配置
│   ├── redis.yaml      # Redis 部署配置
│   ├── server-app.yaml # 后端服务配置
│   └── web.yaml        # 前端服务配置
├── scripts/            # 部署脚本
│   └── deploy-mineadmin.sh
├── configs/            # 配置文件模板
└── tools/              # 辅助工具
```

## 访问信息

### 本地访问
```bash
# 前端访问
kubectl port-forward -n mineadmin svc/mineadmin-web-service 8080:80
# 访问: http://localhost:8080

# 后端 API 访问
kubectl port-forward -n mineadmin svc/mineadmin-server-service 8081:80
# 访问: http://localhost:8081
```

### 集群内访问
- **前端**: `http://mineadmin-web-service.mineadmin.svc.cluster.local`
- **后端**: `http://mineadmin-server-service.mineadmin.svc.cluster.local`
- **MySQL**: `mysql-service.mineadmin.svc.cluster.local:3306`
- **Redis**: `redis-service.mineadmin.svc.cluster.local:6379`

## 常用命令

### 查看集群状态
```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
```

### 查看服务日志
```bash
# 查看后端服务日志
kubectl logs -n mineadmin -l app=mineadmin-server

# 查看前端服务日志
kubectl logs -n mineadmin -l app=mineadmin-web

# 查看 MySQL 日志
kubectl logs -n mineadmin -l app=mysql

# 查看 Redis 日志
kubectl logs -n mineadmin -l app=redis
```

### 扩缩容
```bash
# 扩展后端服务副本数
kubectl scale deployment mineadmin-server -n mineadmin --replicas=3

# 扩展前端服务副本数
kubectl scale deployment mineadmin-web -n mineadmin --replicas=3
```

## 故障排除

### 常见问题

1. **Pod 启动失败**
   ```bash
   kubectl describe pod <pod-name> -n mineadmin
   kubectl logs <pod-name> -n mineadmin
   ```

2. **服务无法访问**
   ```bash
   kubectl get endpoints -n mineadmin
   kubectl describe service <service-name> -n mineadmin
   ```

3. **存储问题**
   ```bash
   kubectl get pvc -n mineadmin
   kubectl describe pvc <pvc-name> -n mineadmin
   ```

### 日志查看
```bash
# 查看 kubelet 日志
sudo journalctl -u kubelet -f

# 查看 containerd 日志
sudo journalctl -u containerd -f
```

## 备份和恢复

### 备份集群配置
```bash
./docker/mineadmin.sh k8s
# 选择 "备份集群配置"
```

### 恢复集群配置
```bash
./docker/mineadmin.sh k8s
# 选择 "恢复集群配置"
```

## 升级指南

### 升级 Kubernetes 版本
```bash
./docker/mineadmin.sh k8s
# 选择 "升级集群版本"
```

## 安全建议

1. **网络策略**: 配置适当的网络策略限制 Pod 间通信
2. **RBAC**: 启用基于角色的访问控制
3. **密钥管理**: 使用 Kubernetes Secrets 管理敏感信息
4. **镜像安全**: 定期更新容器镜像，扫描安全漏洞

## 性能优化

1. **资源限制**: 为 Pod 设置适当的资源请求和限制
2. **节点亲和性**: 配置 Pod 调度策略
3. **存储优化**: 使用高性能存储类
4. **网络优化**: 配置合适的网络插件参数

## 监控和告警

建议集成以下监控工具：
- **Prometheus**: 指标收集
- **Grafana**: 可视化面板
- **AlertManager**: 告警管理

## 支持

如有问题，请参考：
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [MineAdmin 项目文档](https://mineadmin.com/)
- [项目 Issues](https://github.com/mineadmin/MineAdmin/issues)
