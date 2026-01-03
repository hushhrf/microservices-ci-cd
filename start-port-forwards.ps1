# Start all port-forwards for microservices
Write-Host "=== Starting Port-Forwards ===" -ForegroundColor Green
Write-Host ""

# Start Eureka Server
Write-Host "Starting Eureka Server on port 8761..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Eureka Server - http://localhost:8761' -ForegroundColor Green; kubectl port-forward -n microservices svc/eureka-server 8761:8761"
Start-Sleep -Seconds 2

# Start Config Server
Write-Host "Starting Config Server on port 8888..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Config Server - http://localhost:8888' -ForegroundColor Green; kubectl port-forward -n microservices svc/config-server 8888:8888"
Start-Sleep -Seconds 2

# Start Gateway
Write-Host "Starting Gateway on port 8080..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Gateway - http://localhost:8080' -ForegroundColor Green; kubectl port-forward -n microservices svc/gateway 8080:8080"
Start-Sleep -Seconds 2

# Start Jenkins
Write-Host "Starting Jenkins on port 8080..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Jenkins - http://localhost:8080/jenkins' -ForegroundColor Green; kubectl port-forward -n jenkins svc/jenkins 8080:8080"
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "=== Port-Forwards Started! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Access services at:" -ForegroundColor Yellow
Write-Host "  📋 Eureka Server:  http://localhost:8761" -ForegroundColor White
Write-Host "  ⚙️  Config Server:  http://localhost:8888" -ForegroundColor White
Write-Host "  🚪 Gateway:         http://localhost:8080" -ForegroundColor White
Write-Host "  🔧 Jenkins:         http://localhost:8080/jenkins" -ForegroundColor White
Write-Host ""
Write-Host "Note: Keep the PowerShell windows open while using services." -ForegroundColor Gray
Write-Host "      Close them when done to stop port-forwarding." -ForegroundColor Gray

