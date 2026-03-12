# ============================================
# 完整项目备份到新GitHub仓库脚本
# ============================================
# 用途: 将整个Monorepo项目备份到一个全新的独立GitHub仓库
# 作者: CRM Team
# 日期: 2026-03-10
# ============================================

param(
    [Parameter(Mandatory=$false)]
    [string]$NewRepoUrl = "https://github.com/shushuhao01/backups.git",
    
    [Parameter(Mandatory=$false)]
    [string]$Branch = "main"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  完整项目备份到新GitHub仓库" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否在Git仓库中
if (-not (Test-Path ".git")) {
    Write-Host "❌ 错误: 当前目录不是Git仓库" -ForegroundColor Red
    exit 1
}

# 如果没有提供新仓库URL，提示用户输入
if ([string]::IsNullOrEmpty($NewRepoUrl)) {
    Write-Host "请输入新的GitHub仓库URL (例如: https://github.com/username/crm-backup.git)" -ForegroundColor Yellow
    $NewRepoUrl = Read-Host "新仓库URL"
    
    if ([string]::IsNullOrEmpty($NewRepoUrl)) {
        Write-Host "❌ 错误: 必须提供仓库URL" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "📋 备份配置:" -ForegroundColor Green
Write-Host "  新仓库URL: $NewRepoUrl" -ForegroundColor White
Write-Host "  目标分支: $Branch" -ForegroundColor White
Write-Host ""

# 确认操作
$confirm = Read-Host "确认要将整个项目备份到新仓库吗? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "❌ 操作已取消" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🔄 开始备份流程..." -ForegroundColor Cyan
Write-Host ""

# 步骤1: 检查当前状态
Write-Host "📊 步骤 1/6: 检查当前Git状态..." -ForegroundColor Yellow
git status --short
Write-Host ""

# 步骤2: 提示用户是否需要提交未保存的更改
$hasChanges = git status --porcelain
if ($hasChanges) {
    Write-Host "⚠️  检测到未提交的更改" -ForegroundColor Yellow
    $commitChanges = Read-Host "是否先提交这些更改? (y/n)"
    
    if ($commitChanges -eq 'y' -or $commitChanges -eq 'Y') {
        $commitMessage = Read-Host "请输入提交信息"
        if ([string]::IsNullOrEmpty($commitMessage)) {
            $commitMessage = "备份前的自动提交 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }
        
        Write-Host "📝 提交更改..." -ForegroundColor Yellow
        git add .
        git commit -m "$commitMessage"
        Write-Host "✅ 更改已提交" -ForegroundColor Green
    }
}
Write-Host ""

# 步骤3: 添加新的远程仓库
Write-Host "🔗 步骤 2/6: 添加新的远程仓库..." -ForegroundColor Yellow
$remoteName = "backup"

# 检查remote是否已存在
$existingRemote = git remote get-url $remoteName 2>$null
if ($existingRemote) {
    Write-Host "  远程仓库 '$remoteName' 已存在，将更新URL" -ForegroundColor Yellow
    git remote set-url $remoteName $NewRepoUrl
} else {
    git remote add $remoteName $NewRepoUrl
}

Write-Host "✅ 远程仓库已配置: $remoteName -> $NewRepoUrl" -ForegroundColor Green
Write-Host ""

# 步骤4: 显示所有远程仓库
Write-Host "📋 步骤 3/6: 当前所有远程仓库:" -ForegroundColor Yellow
git remote -v
Write-Host ""

# 步骤5: 推送到新仓库
Write-Host "⬆️  步骤 4/6: 推送到新仓库..." -ForegroundColor Yellow
Write-Host "  这可能需要几分钟，取决于项目大小..." -ForegroundColor Gray

try {
    # 获取当前分支
    $currentBranch = git branch --show-current
    
    # 推送当前分支到新仓库
    Write-Host "  推送分支: $currentBranch -> $Branch" -ForegroundColor Cyan
    git push -u $remoteName ${currentBranch}:${Branch} --force
    
    Write-Host "✅ 主分支推送成功" -ForegroundColor Green
    Write-Host ""
    
    # 询问是否推送所有分支
    $pushAllBranches = Read-Host "是否推送所有本地分支? (y/n)"
    if ($pushAllBranches -eq 'y' -or $pushAllBranches -eq 'Y') {
        Write-Host "  推送所有分支..." -ForegroundColor Cyan
        git push $remoteName --all --force
        Write-Host "✅ 所有分支推送成功" -ForegroundColor Green
    }
    
    Write-Host ""
    
    # 询问是否推送标签
    $pushTags = Read-Host "是否推送所有标签? (y/n)"
    if ($pushTags -eq 'y' -or $pushTags -eq 'Y') {
        Write-Host "  推送所有标签..." -ForegroundColor Cyan
        git push $remoteName --tags --force
        Write-Host "✅ 所有标签推送成功" -ForegroundColor Green
    }
    
} catch {
    Write-Host "❌ 推送失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 可能的原因:" -ForegroundColor Yellow
    Write-Host "  1. 新仓库不存在或URL错误" -ForegroundColor White
    Write-Host "  2. 没有推送权限" -ForegroundColor White
    Write-Host "  3. 网络连接问题" -ForegroundColor White
    Write-Host ""
    Write-Host "请检查后重试" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 步骤6: 验证备份
Write-Host "✅ 步骤 5/6: 验证备份..." -ForegroundColor Yellow
Write-Host "  检查远程分支..." -ForegroundColor Cyan
git ls-remote $remoteName
Write-Host ""

# 步骤7: 完成
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ 备份完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 备份信息:" -ForegroundColor Cyan
Write-Host "  远程名称: $remoteName" -ForegroundColor White
Write-Host "  仓库URL: $NewRepoUrl" -ForegroundColor White
Write-Host "  主分支: $Branch" -ForegroundColor White
Write-Host ""
Write-Host "🔗 访问你的备份仓库:" -ForegroundColor Cyan
$webUrl = $NewRepoUrl -replace '\.git$', '' -replace 'git@github\.com:', 'https://github.com/'
Write-Host "  $webUrl" -ForegroundColor Blue
Write-Host ""
Write-Host "💡 后续操作:" -ForegroundColor Yellow
Write-Host "  1. 访问GitHub查看备份仓库" -ForegroundColor White
Write-Host "  2. 如需定期备份，可以再次运行此脚本" -ForegroundColor White
Write-Host "  3. 如需删除backup远程: git remote remove backup" -ForegroundColor White
Write-Host ""
Write-Host "✨ 备份流程全部完成!" -ForegroundColor Green
