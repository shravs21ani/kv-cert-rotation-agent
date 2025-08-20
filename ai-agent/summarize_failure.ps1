param (
    [string]$ErrorFile = "./errorlog.txt",
    [string]$PromptTemplate = "./ai-agent/summarize_failure.md",
    [string]$ConfigFile = "./ai-agent/config.json"
)

# Initialize logging
$logFile = "./ai-agent/agent.log"
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

try {
    # Validate input files
    if (!(Test-Path $ErrorFile)) {
        throw "Error file not found: $ErrorFile"
    }
    if (!(Test-Path $PromptTemplate)) {
        throw "Prompt template not found: $PromptTemplate"
    }

    # Check for API key
    if ([string]::IsNullOrEmpty($env:OPENAI_API_KEY)) {
        throw "OPENAI_API_KEY environment variable is not set"
    }

    Write-Log "Loading error log and prompt template..."
    $errorLog = Get-Content $ErrorFile -Raw -ErrorAction Stop
    $prompt = Get-Content $PromptTemplate -Raw -ErrorAction Stop
    
    if ([string]::IsNullOrWhiteSpace($errorLog)) {
        throw "Error log file is empty"
    }

    $finalPrompt = $prompt -replace "{{ErrorLog}}", $errorLog

    Write-Log "Calling OpenAI API..."
    $apiBody = @{
        model = "gpt-4"
        messages = @(
            @{
                role = "system"
                content = "You are an Azure DevSecOps assistant specializing in certificate management and error analysis."
            },
            @{
                role = "user"
                content = $finalPrompt
            }
        )
        temperature = 0.3
        max_tokens = 2000
    }

    $response = Invoke-RestMethod `
        -Uri "https://api.openai.com/v1/chat/completions" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $env:OPENAI_API_KEY"
            "Content-Type" = "application/json"
        } `
        -Body ($apiBody | ConvertTo-Json -Depth 4) `
        -ErrorAction Stop

    Write-Log "Successfully received API response"
    
    # Save the summary to a file
    $summaryFile = "./ai-agent/summary_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    $response.choices[0].message.content | Out-File $summaryFile -Encoding utf8
    
    Write-Log "Summary saved to: $summaryFile"
    return $response.choices[0].message.content

} catch {
    $errorMessage = "Error: $($_.Exception.Message)"
    Write-Log $errorMessage
    throw $errorMessage
}