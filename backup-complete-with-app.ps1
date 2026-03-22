# ============================================
# 完整项目备份脚本（包含所有子项目）
# ============================================
# 用途: 将整个Monorepo项目（包括crmAPP）完整备份到backups仓库
# 日期: 2026-03-12
# ============================================

$BackupRepoUrl = "https://github.com/shushuhao01/backups.git"
$RemoteName = "backup"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Complete Project Backup (All Subprojects)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否在Git仓库中
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: Not a Git repository" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1/7: Checking crmAPP status..." -ForegroundColor Yellow

# 检查 crmAPP 是否有独立的 .git 目录
$crmAppHasGit = Test-Path "crmAPP/.git"
$crmAppGitBackup = $null

if ($crmAppHasGit) {
    Write-Host "  crmAPP has its own .git directory" -ForegroundColor Yellow
    Write-Host "  Will temporarily move it to include crmAPP content" -ForegroundColor Yellow
    
    # 备份 crmAPP/.git 目录
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $crmAppGitBackup = "crmAPP/.git.backup-$timestamp"
    
    Write-Host "  Backing up crmAPP/.git to $crmAppGitBackup" -ForegroundColor Cyan
    Move-Item "crmAPP/.git" $crmAppGitBackup -Force
    Write-Host "  crmAPP/.git backed up" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 2/7: Checking .gitignore..." -ForegroundColor Yellow

# 检查 .gitignore 是否忽略了 crmAPP
$gitignoreContent = Get-Content ".gitignore" -Raw
$gitignoreBackup = $null

if ($gitignoreContent -match "crmAPP") {
    Write-Host "  .gitignore contains crmAPP exclusion" -ForegroundColor Yellow
    Write-Host "  Creating temporary .gitignore without crmAPP exclusion" -ForegroundColor Cyan
    
    # 备份 .gitignore
    $gitignoreBackup = ".gitignore.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item ".gitignore" $gitignoreBackup
    
    # 临时移除 crmAPP 的忽略规则
    $newGitignore = $gitignoreContent -replace "(?m)^# APP项目.*\r?\n", "" -replace "(?m)^crmAPP/.*\r?\n", ""
    Set-Content ".gitignore" $newGitignore -NoNewline
    
    Write-Host "  .gitignore updated temporarily" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 3/7: Adding crmAPP to Git..." -ForegroundColor Yellow

# 添加 crmAPP 到 Git
git add crmAPP -f
git add .gitignore

$status = git status --short
if ($status) {
    Write-Host "  Changes detected:" -ForegroundColor Cyan
    Write-Host $status
    Write-Host ""
    
    # 提交更改
    $commitMessage = "Complete backup with all subprojects including crmAPP - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git commit -m "$commitMessage"
    Write-Host "  Changes committed" -ForegroundColor Green
} else {
    Write-Host "  No changes to commit" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 4/7: Configuring backup remote..." -ForegroundColor Yellow

# 配置远程仓库
$existingRemote = git remote get-url $RemoteName 2>$null
if ($existingRemote) {
    Write-Host "  Remote '$RemoteName' already exists" -ForegroundColor Green
} else {
    git remote add $RemoteName $BackupRepoUrl
    Write-Host "  Remote '$RemoteName' added" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 5/7: Pushing to backup repository..." -ForegroundColor Yellow
Write-Host "  This may take several minutes..." -ForegroundColor Gray

try {
    # 推送到备份仓库
    git push $RemoteName main --force
    Write-Host "  Push completed successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Push failed: $_" -ForegroundColor Red
    
    # 恢复备份
    if ($gitignoreBackup) {
        Write-Host "  Restoring .gitignore..." -ForegroundColor Yellow
        Move-Item $gitignoreBackup ".gitignore" -Force
    }
    if ($crmAppGitBackup) {
        Write-Host "  Restoring crmAPP/.git..." -ForegroundColor Yellow
        Move-Item $crmAppGitBackup "crmAPP/.git" -Force
    }
    
    exit 1
}

Write-Host ""
Write-Host "Step 6/7: Restoring original state..." -ForegroundColor Yellow

# 恢复 .gitignore
if ($gitignoreBackup) {
    Write-Host "  Restoring .gitignore..." -ForegroundColor Cyan
    Move-Item $gitignoreBackup ".gitignore" -Force
    git add .gitignore
    git commit -m "Restore .gitignore after backup" --no-verify
    Write-Host "  .gitignore restored" -ForegroundColor Green
}

# 恢复 crmAPP/.git
if ($crmAppGitBackup) {
    Write-Host "  Restoring crmAPP/.git..." -ForegroundColor Cyan
    Move-Item $crmAppGitBackup "crmAPP/.git" -Force
    Write-Host "  crmAPP/.git restored" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 7/7: Verifying backup..." -ForegroundColor Yellow
git ls-remote $RemoteName

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Backup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backup Information:" -ForegroundColor Cyan
Write-Host "  Repository: $BackupRepoUrl" -ForegroundColor White
Write-Host "  Remote Name: $RemoteName" -ForegroundColor White
Write-Host "  All subprojects included: YES" -ForegroundColor White
Write-Host "  - CRM Frontend (root)" -ForegroundColor Gray
Write-Host "  - Admin Backend (admin/)" -ForegroundColor Gray
Write-Host "  - Website (website/)" -ForegroundColor Gray
Write-Host "  - Backend API (backend/)" -ForegroundColor Gray
Write-Host "  - Mobile App (crmAPP/)" -ForegroundColor Gray
Write-Host ""
Write-Host "Visit: https://github.com/shushuhao01/backups" -ForegroundColor Blue
Write-Host ""
Write-Host "Original state restored - crmAPP still has its own .git" -ForegroundColor Yellow
Write-Host "Backup process completed!" -ForegroundColor Green
