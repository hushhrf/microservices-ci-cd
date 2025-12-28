$DOCKERHUB_USERNAME = "hushhrf"
$IMAGE_NAME = "$DOCKERHUB_USERNAME/jenkins-agent:latest"

Write-Host "Building Jenkins Agent Image: $IMAGE_NAME" -ForegroundColor Cyan

# Build
docker build -t $IMAGE_NAME .

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build Successful! Pushing to Docker Hub..." -ForegroundColor Green
    docker push $IMAGE_NAME
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully pushed $IMAGE_NAME" -ForegroundColor Green
    } else {
        Write-Host "Failed to push image. Please check your docker login." -ForegroundColor Red
    }
} else {
    Write-Host "Build Failed. Please try again." -ForegroundColor Red
}
