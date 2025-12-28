# Comprehensive Test Script for Microservices
# Run this script to verify all services are working correctly

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Microservices Health Check Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check container status
function Test-Container {
    param($ContainerName, $ExpectedStatus = "Up")
    
    $container = docker ps -a --filter "name=$ContainerName" --format "{{.Status}}"
    if ($container -like "*$ExpectedStatus*") {
        Write-Host "✓ $ContainerName is $ExpectedStatus" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ $ContainerName is NOT $ExpectedStatus (Status: $container)" -ForegroundColor Red
        return $false
    }
}

# Function to check HTTP endpoint
function Test-HttpEndpoint {
    param($Url, $ServiceName)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ $ServiceName is responding (HTTP $($response.StatusCode))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ $ServiceName returned HTTP $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ $ServiceName is not responding: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check logs for errors
function Test-Logs {
    param($ContainerName, $ErrorPattern)
    
    $logs = docker logs $ContainerName 2>&1 | Select-String -Pattern $ErrorPattern
    if ($logs) {
        Write-Host "✗ $ContainerName has errors matching '$ErrorPattern'" -ForegroundColor Red
        Write-Host "  Last 3 matching lines:" -ForegroundColor Yellow
        $logs | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
        return $false
    } else {
        Write-Host "✓ $ContainerName logs look clean" -ForegroundColor Green
        return $true
    }
}

Write-Host "Step 1: Checking Container Status" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Yellow

$containers = @(
    "config-server",
    "eureka-server",
    "gateway",
    "auth-service",
    "user-service",
    "job-service",
    "notification-service",
    "file-storage",
    "postgres",
    "redis",
    "zookeeper",
    "kafka"
)

$allContainersUp = $true
foreach ($container in $containers) {
    if (-not (Test-Container $container)) {
        $allContainersUp = $false
    }
}

Write-Host ""
Write-Host "Step 2: Checking Infrastructure Services" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow

# Check PostgreSQL
Write-Host "Testing PostgreSQL connection..."
$pgTest = docker exec postgres pg_isready -U postgres 2>&1
if ($pgTest -like "*accepting connections*") {
    Write-Host "✓ PostgreSQL is ready" -ForegroundColor Green
} else {
    Write-Host "✗ PostgreSQL is not ready" -ForegroundColor Red
    Write-Host "  $pgTest" -ForegroundColor Yellow
}

# Check Redis
Write-Host "Testing Redis connection..."
$redisTest = docker exec redis redis-cli ping 2>&1
if ($redisTest -eq "PONG") {
    Write-Host "✓ Redis is responding" -ForegroundColor Green
} else {
    Write-Host "✗ Redis is not responding" -ForegroundColor Red
    Write-Host "  $redisTest" -ForegroundColor Yellow
}

# Check Zookeeper
Write-Host "Testing Zookeeper..."
$zkTest = docker exec zookeeper zkServer.sh status 2>&1
if ($zkTest -like "*Mode:*") {
    Write-Host "✓ Zookeeper is running" -ForegroundColor Green
} else {
    Write-Host "✗ Zookeeper may have issues" -ForegroundColor Red
    Write-Host "  $zkTest" -ForegroundColor Yellow
}

# Check Kafka
Write-Host "Testing Kafka..."
Start-Sleep -Seconds 2
$kafkaTest = docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Kafka is responding" -ForegroundColor Green
} else {
    Write-Host "✗ Kafka is not responding" -ForegroundColor Red
    Write-Host "  Checking logs..." -ForegroundColor Yellow
    docker logs kafka --tail 20
}

Write-Host ""
Write-Host "Step 3: Checking Application Services" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Yellow

# Wait a bit for services to start
Write-Host "Waiting 10 seconds for services to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Test Config Server
Test-HttpEndpoint "http://localhost:8888/actuator/health" "Config Server"

# Test Eureka Server
Test-HttpEndpoint "http://localhost:8761" "Eureka Server"

# Test Gateway
Test-HttpEndpoint "http://localhost:8080/actuator/health" "Gateway"

# Test Auth Service
Test-HttpEndpoint "http://localhost:8081/actuator/health" "Auth Service"

# Test User Service
Test-HttpEndpoint "http://localhost:8082/actuator/health" "User Service"

# Test Job Service
Test-HttpEndpoint "http://localhost:8083/actuator/health" "Job Service"

# Test Notification Service
Test-HttpEndpoint "http://localhost:8084/actuator/health" "Notification Service"

# Test File Storage
Test-HttpEndpoint "http://localhost:8085/actuator/health" "File Storage"

Write-Host ""
Write-Host "Step 4: Checking Eureka Service Registration" -ForegroundColor Yellow
Write-Host "---------------------------------------------" -ForegroundColor Yellow

try {
    $eurekaResponse = Invoke-RestMethod -Uri "http://localhost:8761/eureka/apps" -TimeoutSec 5
    $services = $eurekaResponse.applications.application | Where-Object { $_.name -ne "EUREKA-SERVER" }
    
    Write-Host "Registered Services in Eureka:" -ForegroundColor Cyan
    foreach ($service in $services) {
        $status = $service.instance.status
        $color = if ($status -eq "UP") { "Green" } else { "Red" }
        Write-Host "  $($service.name): $status" -ForegroundColor $color
    }
    
    $upServices = ($services | Where-Object { $_.instance.status -eq "UP" }).Count
    $totalServices = $services.Count
    Write-Host ""
    Write-Host "Services UP: $upServices/$totalServices" -ForegroundColor $(if ($upServices -eq $totalServices) { "Green" } else { "Yellow" })
} catch {
    Write-Host "✗ Could not check Eureka registrations: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 5: Checking Kafka Connectivity" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow

# Check notification-service logs for Kafka errors
Write-Host "Checking notification-service logs for Kafka errors..."
$kafkaErrors = docker logs notification-service 2>&1 | Select-String -Pattern "could not be established|Connection refused|Broker may not be available"
if ($kafkaErrors) {
    Write-Host "✗ Notification service has Kafka connection errors" -ForegroundColor Red
    Write-Host "  Recent errors:" -ForegroundColor Yellow
    $kafkaErrors | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
} else {
    Write-Host "✓ Notification service Kafka logs look clean" -ForegroundColor Green
}

# Check job-service logs for Kafka errors
Write-Host "Checking job-service logs for Kafka errors..."
$kafkaErrors = docker logs job-service 2>&1 | Select-String -Pattern "could not be established|Connection refused|Broker may not be available"
if ($kafkaErrors) {
    Write-Host "✗ Job service has Kafka connection errors" -ForegroundColor Red
    Write-Host "  Recent errors:" -ForegroundColor Yellow
    $kafkaErrors | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
} else {
    Write-Host "✓ Job service Kafka logs look clean" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 6: Testing Kafka Topics" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow

# List Kafka topics
Write-Host "Listing Kafka topics..."
$topics = docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>&1
if ($LASTEXITCODE -eq 0 -and $topics) {
    Write-Host "✓ Kafka topics found:" -ForegroundColor Green
    $topics | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
} else {
    Write-Host "⚠ No topics found or Kafka not ready yet" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view detailed logs:" -ForegroundColor Yellow
Write-Host "  docker logs <container-name> --tail 50" -ForegroundColor White
Write-Host ""
Write-Host "To restart a service:" -ForegroundColor Yellow
Write-Host "  docker restart <container-name>" -ForegroundColor White
Write-Host ""
Write-Host "To view all containers:" -ForegroundColor Yellow
Write-Host "  docker ps -a" -ForegroundColor White
Write-Host ""
Write-Host "To check Eureka dashboard:" -ForegroundColor Yellow
Write-Host "  Open browser: http://localhost:8761" -ForegroundColor White
Write-Host ""

