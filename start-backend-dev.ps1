# 清理旧进程
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# 启动后端
Start-Process -FilePath "cmd.exe" -ArgumentList "/k cd /d `"D:\kaifa\CRM - 1.8.0\backend`" && npm run dev" -WindowStyle Normal
Write-Host "后端正在启动，请等待30秒..."

# 启动前端
Start-Process -FilePath "cmd.exe" -ArgumentList "/k cd /d `"D:\kaifa\CRM - 1.8.0`" && npm run dev" -WindowStyle Normal
Write-Host "前端正在启动..."

# 轮询检查
$timeout = 90
$elapsed = 0
while ($elapsed -lt $timeout) {
    Start-Sleep -Seconds 5
    $elapsed += 5
    $result = netstat -ano | findstr ":3000 " | findstr "LISTENING"
    if ($result) {
        Write-Host "`n✅ 后端已启动 (${elapsed}秒)`n$result"
        break
    }
    Write-Host "等待后端启动... ${elapsed}s"
}
if ($elapsed -ge $timeout) {
    Write-Host "❌ 后端启动超时，请检查cmd窗口中的错误信息"
}

# 检查前端
Start-Sleep -Seconds 5
$fe = netstat -ano | findstr ":5173 " | findstr "LISTENING"
if ($fe) { Write-Host "✅ 前端已启动`n$fe" } else { Write-Host "⏳ 前端可能还在编译中..." }

