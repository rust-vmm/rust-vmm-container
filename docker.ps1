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
    return "$IMAGE_NAME:g$(Next-Version)"
}

function Print-NextVersion {
    return "$IMAGE_NAME:g$(Next-Version)"
}

function Print-Registry {
    return $REGISTRY
}

function Print-ImageName {
    return $IMAGE_NAME
}

function Build-Tag {
    return "$(Get-FullVersion)_$ARCH"
}

function Build-Container {
    # Build the container and check for failures
    # Docker build returns 0 on success, non-zero on failure
    $tag = Build-Tag
    docker build -t $tag `
        --build-arg GIT_BRANCH=$GIT_BRANCH `
        --build-arg GIT_COMMIT=$GIT_COMMIT `
        -f Dockerfile.windows.x86_64 .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    Write-Host "Build completed for $tag"
}

function Publish-Container {
    $tag = Build-Tag
    Write-Host "Publishing $tag to dockerhub"
    docker push $tag
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