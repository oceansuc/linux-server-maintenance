#!/bin/bash

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${YELLOW}======================================================${NC}"
echo -e "${CYAN}       Linux 服务器安全磁盘清理脚本 (Optimized)${NC}"
echo -e "${YELLOW}======================================================${NC}"

# 1. 检查 Root 权限
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[Error] 请使用 root 权限运行此脚本 (sudo bash $0)${NC}"
  exit 1
fi

# 显示当前磁盘使用情况
echo -e "${GREEN}[INFO] 🚀 清理前磁盘使用情况：${NC}"
df -h / | grep /

# --- 清理流程开始 ---

# 2. 清理包管理器缓存 (apt/yum/dnf)
echo -e "\n${YELLOW}--- [Step 1] 清理软件包缓存 ---${NC}"
if command -v apt-get &> /dev/null; then
    echo "检测到 Debian/Ubuntu 系统..."
    apt-get clean -y
    apt-get autoclean -y
    # 删除不再需要的依赖包
    apt-get autoremove -y
elif command -v yum &> /dev/null; then
    echo "检测到 CentOS/RHEL 系统..."
    yum clean all
    # 强制清理缓存目录，确保彻底
    rm -rf /var/cache/yum
elif command -v dnf &> /dev/null; then
    echo "检测到 Fedora/CentOS 8+ 系统..."
    dnf clean all
    # 强制清理缓存目录，确保彻底
    rm -rf /var/cache/dnf
fi
echo -e "${GREEN}✅ 软件包缓存清理完成。${NC}"

# 3. 清理 systemd 日志
echo -e "\n${YELLOW}--- [Step 2] 清理 systemd 日志 (保留最近 100M 或 1 天) ---${NC}"
if command -v journalctl &> /dev/null; then
    # 只保留 100MB 的日志，和/或保留最近 1 天的日志
    journalctl --vacuum-size=100M
    journalctl --vacuum-time=1d
else
    echo "未检测到 systemd journal，跳过。"
fi
echo -e "${GREEN}✅ Systemd 日志清理完成。${NC}"

# 4. 安全截断旧的大型日志文件 (/var/log)
echo -e "\n${YELLOW}--- [Step 3] 归档/截断 /var/log 下的旧日志 ---${NC}"
# 删除已经压缩归档的旧日志 (.gz, .xz, .zip)
find /var/log -type f -regex ".*\(gz\|xz\|zip\)$" -delete
# 删除旧的轮转日志
find /var/log -type f -name "*.1" -delete
# 查找 /var/log 下大于 50M 的 .log 文件并清空内容 (安全截断)
echo "正在清空 /var/log 下大于 50M 的 *.log 文件内容..."
find /var/log -type f -name "*.log" -size +50M -exec truncate -s 0 {} \;
echo -e "${GREEN}✅ /var/log 日志清理完成。${NC}"

# 5. 清理 Web 服务器旧日志 (Nginx/Apache) - 优化新增
echo -e "\n${YELLOW}--- [Step 4] 清理 Nginx/Apache 旧访问/错误日志 ---${NC}"
WEB_LOG_PATHS=("/var/log/nginx" "/var/log/httpd" "/usr/local/nginx/logs")

CLEANED=false
for log_path in "${WEB_LOG_PATHS[@]}"; do
    if [ -d "$log_path" ]; then
        echo "正在清理 ${log_path}..."
        # 查找 *.log.[0-9], *.log.old 或大于 100M 的日志并删除或截断
        find "$log_path" -type f \( -name "*.log.[0-9]" -o -name "*.log.old" \) -delete
        find "$log_path" -type f -name "*.log" -size +100M -exec truncate -s 0 {} \;
        CLEANED=true
    fi
done
if ! $CLEANED; then
    echo "未检测到常见的 Web 服务器日志路径，跳过。"
fi
echo -e "${GREEN}✅ Web 服务器日志清理完成。${NC}"

# 6. 清理 Docker 垃圾 (如果存在)
if command -v docker &> /dev/null; then
    echo -e "\n${YELLOW}--- [Step 5] 检测到 Docker，清理未使用的镜像和缓存 ---${NC}"
    # 清理所有悬空镜像 (Dangling images)、未使用的网络和构建缓存
    docker system prune -af
    echo -e "${GREEN}✅ Docker 垃圾清理完成。${NC}"
else
    echo -e "\n${YELLOW}--- [Step 5] 未检测到 Docker，跳过。${NC}"
fi

# 7. 清理 /tmp 和 /var/tmp
echo -e "\n${YELLOW}--- [Step 6] 清理 /tmp 和 /var/tmp 下超过 7 天的文件/目录 ---${NC}"
# 删除 /tmp 下超过 7 天的文件和空目录
find /tmp -mindepth 1 -atime +7 -delete 2>/dev/null
# 删除 /var/tmp 下超过 30 天的文件和空目录（/var/tmp 建议保留更久）
find /var/tmp -mindepth 1 -atime +30 -delete 2>/dev/null
echo -e "${GREEN}✅ 临时文件清理完成。${NC}"

# 8. 清理 Root 和用户的应用缓存 - 优化新增
echo -e "\n${YELLOW}--- [Step 7] 清理 Root 和部分用户的应用缓存 (~/.cache) ---${NC}"

# 清理 root 用户的缓存 (保留 30 天以上的文件)
if [ -d "/root/.cache" ]; then
    echo "清理 /root/.cache 下超过 30 天的文件..."
    find /root/.cache -type f -atime +30 -delete 2>/dev/null
fi

# 检查并清理 /home 下各个用户的缩略图缓存 (最常见且安全的清理项)
echo "正在清理 /home 下的用户缩略图缓存..."
find /home -maxdepth 4 -type d -name "thumbnails" -exec rm -rf {} \; 2>/dev/null
echo -e "${GREEN}✅ 用户缓存清理完成。${NC}"

# 9. 关键步骤：查找全盘大文件
echo -e "\n${YELLOW}--- [Step 8] 正在扫描全盘最大的 15 个文件 (请人工确认是否可删除) ---${NC}"
echo -e "${RED}🚨 注意：以下文件请手动确认后再删除！${NC}"
# 排除虚拟目录 (/proc, /sys, /run, /dev) 和系统引导目录 (/boot)
find / -type f -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" -not -path "/dev/*" -not -path "/boot/*" -printf "%s %p\n" 2>/dev/null | sort -nr | head -n 15 | awk '{print int($1/1048576) "MB\t" $2}'

echo -e "\n${YELLOW}======================================================${NC}"
echo -e "${GREEN}🎉 脚本执行结束。清理后磁盘使用情况：${NC}"
df -h / | grep /
echo -e "${YELLOW}如果空间依然不足，请根据 [Step 8] 的列表手动删除大文件。${NC}"
echo -e "${YELLOW}======================================================${NC}"
