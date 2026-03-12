# ============================================
# 完整项目备份到backups仓库脚本
# ============================================
# 用途: 将整个Monorepo项目备份到 https://github.com/shushuhao01/backups.git
# 日期: 2026-03-12
# ============================================

$NewRepoUrl = "https://github.com/shushuhao01/backups.git"
$Branch = "main"
$RemoteName = "backup"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Complete Project Backup to GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if in Git repository
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: Not a Git repository" -ForegroundColor Red
    exit 1
}

Write-Host "Backup Configuration:" -ForegroundColor Green
Write-Host "  Target Repository: $NewRepoUrl" -ForegroundColor White
Write-Host "  Target Branch: $Branch" -ForegroundColor White
Write-Host ""

# Confirm operation
$confirm = Read-Host "Confirm backup to new repository? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Operation cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Starting backup process..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Check current status
Write-Host "Step 1/5: Checking Git status..." -ForegroundColor Yellow
$hasChanges = git status --porcelain
if ($hasChanges) {
    Write-Host "WARNING: Uncommitted changes detected" -ForegroundColor Yellow
    git status --short
    Write-Host ""
    $commitChanges = Read-Host "Commit these changes first? (y/n)"
    
    if ($commitChanges -eq 'y' -or $commitChanges -eq 'Y') {
        $commitMessage = "Backup commit - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Host "Committing changes..." -ForegroundColor Yellow
        git add .
        git commit -m "$commitMessage"
        Write-Host "Changes committed" -ForegroundColor Green
    }
}
Write-Host ""

# Step 2: Configure remote repository
Write-Host "Step 2/5: Configuring remote repository..." -ForegroundColor Yellow
$existingRemote = git remote get-url $RemoteName 2>$null
if ($existingRemote) {
    Write-Host "  Remote '$RemoteName' exists, updating URL" -ForegroundColor Yellow
    git remote set-url $RemoteName $NewRepoUrl
} else {
    git remote add $RemoteName $NewRepoUrl
}

Write-Host "Remote configured: $RemoteName -> $NewRepoUrl" -ForegroundColor Green
Write-Host ""

# Step 3: Show all remotes
Write-Host "Step 3/5: Current remote repositories:" -ForegroundColor Yellow
git remote -v
Write-Host ""

# Step 4: Push to new repository
Write-Host "Step 4/5: Pushing to backup repository..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Gray
Write-Host ""

try {
    # Get current branch
    $currentBranch = git branch --show-current
    
    # Push current branch
    Write-Host "  Pushing branch: $currentBranch -> $Branch" -ForegroundColor Cyan
    git push -u $RemoteName ${currentBranch}:${Branch} --force
    
    Write-Host "Main branch pushed successfully" -ForegroundColor Green
    Write-Host ""
    
    # Ask about pushing all branches
    $pushAllBranches = Read-Host "Push all local branches? (y/n)"
    if ($pushAllBranches -eq 'y' -or $pushAllBranches -eq 'Y') {
        Write-Host "  Pushing all branches..." -ForegroundColor Cyan
        git push $RemoteName --all --force
        Write-Host "All branches pushed" -ForegroundColor Green
    }
    
    Write-Host ""
    
    # Ask about pushing tags
    $pushTags = Read-Host "Push all tags? (y/n)"
    if ($pushTags -eq 'y' -or $pushTags -eq 'Y') {
        Write-Host "  Pushing all tags..." -ForegroundColor Cyan
        git push $RemoteName --tags --force
        Write-Host "All tags pushed" -ForegroundColor Green
    }
    
} catch {
    Write-Host "ERROR: Push failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible reasons:" -ForegroundColor Yellow
    Write-Host "  1. Repository does not exist or URL is incorrect" -ForegroundColor White
    Write-Host "  2. No push permission" -ForegroundColor White
    Write-Host "  3. Network connection issue" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""

# Step 5: Verify backup
Write-Host "Step 5/5: Verifying backup..." -ForegroundColor Yellow
Write-Host "  Checking remote branches..." -ForegroundColor Cyan
git ls-remote $RemoteName
Write-Host ""

# Complete
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Backup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backup Information:" -ForegroundColor Cyan
Write-Host "  Remote Name: $RemoteName" -ForegroundColor White
Write-Host "  Repository URL: $NewRepoUrl" -ForegroundColor White
Write-Host "  Main Branch: $Branch" -ForegroundColor White
Write-Host ""
Write-Host "Visit your backup repository:" -ForegroundColor Cyan
Write-Host "  https://github.com/shushuhao01/backups" -ForegroundColor Blue
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Visit GitHub to view backup repository" -ForegroundColor White
Write-Host "  2. Run this script again for periodic backups" -ForegroundColor White
Write-Host "  3. To remove backup remote: git remote remove backup" -ForegroundColor White
Write-Host ""
Write-Host "Backup process completed!" -ForegroundColor Green
