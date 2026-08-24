# Script to upload lesson images from mobile assets to backend
# This script will:
# 1. Delete existing assets for the specified lesson IDs
# 2. Upload new images from the mobile assets folder

# Configuration
$backendUrl = "http://10.250.50.221:8081"
$mobileAssetsPath = "C:\Users\Nicoj\OneDrive\Desktop\Vocaboo\mobile\assets\images"
$lesson1Id = "b1000000-0000-0000-0000-000000000001"  # School Objects
$lesson2Id = "b1000000-0000-0000-0000-000000000002"  # Family Members

# Admin credentials (you'll need to provide these)
$adminUsername = ""
$adminPassword = ""

Write-Host "=== Vocaboo Lesson Image Upload Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if admin credentials are provided
if ([string]::IsNullOrEmpty($adminUsername) -or [string]::IsNullOrEmpty($adminPassword)) {
    Write-Host "Please provide admin credentials:" -ForegroundColor Yellow
    $adminUsername = Read-Host "Admin Username"
    $adminPassword = Read-Host "Admin Password" -AsSecureString
    $adminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))
}

# Function to authenticate and get JWT token
function Get-AuthToken {
    param(
        [string]$username,
        [string]$password
    )
    
    $authUrl = "$backendUrl/api/admin/auth/login"
    $body = @{
        username = $username
        password = $password
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $body -ContentType "application/json"
        return $response.access_token
    } catch {
        Write-Host "Authentication failed: $_" -ForegroundColor Red
        exit 1
    }
}

# Function to delete existing assets for a lesson
function Remove-LessonAssets {
    param(
        [string]$lessonId,
        [string]$token
    )
    
    Write-Host "Removing existing assets for lesson: $lessonId" -ForegroundColor Yellow
    
    try {
        $deleteUrl = "$backendUrl/api/admin/assets/lesson/$lessonId"
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        
        Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers | Out-Null
        Write-Host "  All existing assets deleted successfully" -ForegroundColor Green
        
    } catch {
        Write-Host "  Error removing assets: $_" -ForegroundColor Red
    }
}

# Function to upload an image
function Upload-Image {
    param(
        [string]$imagePath,
        [string]$lessonId,
        [string]$token
    )
    
    $filename = Split-Path $imagePath -Leaf
    Write-Host "  Uploading: $filename" -ForegroundColor Cyan
    
    $uploadUrl = "$backendUrl/api/admin/assets/upload"
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    try {
        $form = @{
            file = Get-Item -Path $imagePath
            asset_type = "IMAGE"
            lesson_id = $lessonId
        }
        
        $response = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $headers -Form $form
        Write-Host "    Success: $($response.asset_url)" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "    Failed: $_" -ForegroundColor Red
        return $null
    }
}

# Main execution
Write-Host "Authenticating..." -ForegroundColor Cyan
$token = Get-AuthToken -username $adminUsername -password $adminPassword

if ([string]::IsNullOrEmpty($token)) {
    Write-Host "Failed to obtain authentication token" -ForegroundColor Red
    exit 1
}

Write-Host "Authentication successful!" -ForegroundColor Green
Write-Host ""

# Process LESSON 1
Write-Host "=== Processing LESSON 1 ===" -ForegroundColor Cyan
$lesson1Path = Join-Path $mobileAssetsPath "LESSON 1"

if (Test-Path $lesson1Path) {
    # Remove existing assets
    Remove-LessonAssets -lessonId $lesson1Id -token $token
    
    # Upload new images
    Write-Host "Uploading new images..." -ForegroundColor Cyan
    $images = Get-ChildItem -Path $lesson1Path -Filter "*.png"
    
    foreach ($image in $images) {
        Upload-Image -imagePath $image.FullName -lessonId $lesson1Id -token $token
    }
    
    Write-Host "LESSON 1 complete. Uploaded $($images.Count) images." -ForegroundColor Green
} else {
    Write-Host "LESSON 1 path not found: $lesson1Path" -ForegroundColor Red
}

Write-Host ""

# Process LESSON 2
Write-Host "=== Processing LESSON 2 ===" -ForegroundColor Cyan
$lesson2Path = Join-Path $mobileAssetsPath "LESSON 2"

if (Test-Path $lesson2Path) {
    # Remove existing assets
    Remove-LessonAssets -lessonId $lesson2Id -token $token
    
    # Upload new images
    Write-Host "Uploading new images..." -ForegroundColor Cyan
    $images = Get-ChildItem -Path $lesson2Path -Filter "*.png"
    
    foreach ($image in $images) {
        Upload-Image -imagePath $image.FullName -lessonId $lesson2Id -token $token
    }
    
    Write-Host "LESSON 2 complete. Uploaded $($images.Count) images." -ForegroundColor Green
} else {
    Write-Host "LESSON 2 path not found: $lesson2Path" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Upload Complete ===" -ForegroundColor Green
Write-Host "Images have been uploaded to the backend and associated with the respective lessons."