param(
 [Parameter(Mandatory=$false)]
 [string]$Command
)
$ErrorActionPreference = "Stop"
Get-Content docker.env | Where-Object { $_ -match '^([^#][^=]+)=(.+)$' } | ForEach-Object {
    if ($matches[2] -match '\$\((.*)\)') {
        $cmdOutput = Invoke-Expression $matches[1]
        Set-Variable -Name $matches[1].Trim() -Value $cmdOutput -Scope Script
    } else {
        Set-Variable -Name $matches[1].Trim() -Value $matches[2].Trim() -Scope Script
    }
}
$ARCH = "x86_64"  # Explicitly set the architecture

function Next-Version {
    return (git show -s --format=%h)
}

function Get-FullVersion {
    $version = Next-Version
    return "${IMAGE_NAME}:g${version}"
}

function Print-NextVersion {
    Write-Output (Get-FullVersion)
}

function Print-Registry {
    Write-Output $REGISTRY
}

function Print-ImageName {
    Write-Output $IMAGE_NAME
}

function Build-Tag {
    return "$(Get-FullVersion)_$ARCH"
}

function Check-ExitCode {
    param (
        [int]$ExitCode,
        [string]$Message
    )
    
    if ($ExitCode -ne 0) {
        Write-Error $Message
        exit $ExitCode
    }
}

function Build-Container {
    # Check if running in Linux or Windows container mode
    $containerInfo = docker version --format '{{.Server.Os}}'
    $dockerfile = if ($containerInfo -eq "linux") {
        "Dockerfile"
    } else {
        "Dockerfile.windows.x86_64"
    }
    
    # Build the container and check for failures
    $tag = Build-Tag
    Write-Host "Building using $dockerfile in $containerInfo container mode..."
    
    docker build -t $tag `
        --build-arg GIT_BRANCH=$GIT_BRANCH `
        --build-arg GIT_COMMIT=$GIT_COMMIT `
        --build-arg RUST_TOOLCHAIN=$RUST_TOOLCHAIN `
        -f $dockerfile .
    Check-ExitCode $LASTEXITCODE "Build failed with exit code $LASTEXITCODE"
    Write-Host "Build completed for $tag"
}

function Publish-Container {
    $tag = Build-Tag
    Write-Host "Publishing $tag to dockerhub"
    
    # Check if image exists locally
    $imageExists = docker image inspect $tag 2>$null
    Check-ExitCode $LASTEXITCODE "Image $tag not found locally. Please run 'build' first."

    # Attempt to push
    docker push $tag
    Check-ExitCode $LASTEXITCODE "Failed to publish $tag"
    Write-Host "Successfully published $tag"
}

# Handle commands
switch ($Command) {
    "build" { Build-Container }
    "publish" { Publish-Container }
    "print-registry" { Print-Registry }
    "print-image-name" { Print-ImageName }
    "print-next-version" { Print-NextVersion }
    default { 
        Write-Host "Command $Command not supported. Try with 'publish', 'build', or 'print-next-version'." 
        exit 1
    }
}