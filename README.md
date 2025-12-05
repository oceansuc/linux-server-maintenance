# linux-server-maintenance
# 🚀 Safe & Optimized Linux 服务器磁盘清理脚本

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash Shell](https://img.shields.io/badge/Shell-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![GitHub Repo stars](https://img.shields.io/github/stars/oceansuc/linux-server-maintenance?style=social)](https://github.com/oceansuc/linux-server-maintenance)

## 简介

`clean_disk_optimized.sh` 是一个专为 Linux 服务器设计的，**安全、全面且跨发行版**的磁盘空间清理脚本。

它旨在通过清理冗余的缓存、日志和临时文件来恢复磁盘空间，同时避免删除正在使用的关键文件，并在最后提供一份需要**人工确认**的大文件列表，是服务器日常维护的理想工具。

### ✨ 核心特性

* **跨发行版兼容：** 自动检测并支持 `apt` (Debian/Ubuntu)、`yum` (CentOS/RHEL) 和 `dnf` (Fedora/CentOS 8+)。
* **安全日志处理：** 使用 `journalctl --vacuum` 和 `truncate -s 0` 清理日志，确保进程文件句柄（File Handlers）不会导致空间不释放。
* **Docker 深度清理：** 自动清理未使用的 Docker 镜像、网络、构建缓存等资源。
* **多路径清理：** 清理包管理器缓存、系统日志、Web 服务器日志（Nginx/Apache）以及 Root/用户缓存。
* **人工保障：** 脚本将最危险的步骤（删除最大的 15 个文件）留给用户进行人工审查和决策。

---

## 🛠️ 如何使用

### 1. 克隆仓库

请使用以下命令克隆本项目到您的 Linux 服务器上：

```bash
git clone [https://github.com/oceansuc/linux-server-maintenance.git](https://github.com/oceansuc/linux-server-maintenance.git)
cd linux-server-maintenance
2. 赋予权限并运行注意： 脚本必须以 root 权限运行，因为它需要访问系统缓存和日志目录。Bash# 赋予执行权限
chmod +x clean_disk_optimized.sh

# 运行脚本
sudo ./clean_disk_optimized.sh
3. 完成人工确认 (Step 8)脚本执行到最后时，会列出全盘最大的 15 个文件（以 MB 为单位）。这是最有可能释放大量空间的地方。请根据您的服务器情况，手动确认并删除这些列表中不需要的文件。🧼 清理步骤详情脚本执行以下 8 个主要步骤来释放空间：Step清理目标描述1软件包缓存清理 APT/YUM/DNF 的下载缓存和不再需要的依赖包。2Systemd 日志限制 journalctl 日志大小（保留最近 100M 或 1 天）。3旧系统日志删除 /var/log 下的归档日志（.gz, .1）并安全截断大型 .log 文件。4Web 服务器日志清理 Nginx/Apache 的旧访问日志和错误日志。5Docker 垃圾使用 docker system prune -af 清理所有未使用的 Docker 资源。6临时文件删除 /tmp (7天) 和 /var/tmp (30天) 下的旧文件和目录。7用户应用缓存清理 Root 用户的缓存和 /home 目录下的用户缩略图缓存。8人工确认扫描并列出最大的 15 个文件供用户手动删除。📄 许可证本项目采用 MIT 许可证 开源。详情请参见 LICENSE 文件。
