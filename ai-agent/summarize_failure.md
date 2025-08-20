# AI Agent Prompt: Certificate Renewal Failure Summary

You are an intelligent Azure DevSecOps assistant. Your task is to:

# summarize_failure.ps1

param (
    [string]$ErrorFile = "./errorlog.txt",
    [string]$PromptTemplate = "./ai-agent/summarize_failure.md"
)

# Load content
$errorLog = Get-Content $ErrorFile -Raw
$prompt = Get-Content $PromptTemplate -Raw
$finalPrompt = $prompt -replace "{{ErrorLog}}", $errorLog

# Call OpenAI API
$response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
    -Headers @{
        "Authorization" = "Bearer $env:OPENAI_API_KEY"
        "Content-Type"  = "application/json"
    } `
    -Method POST `
    -Body (@{
        model = "gpt-4"
        messages = @(@{
            role = "user"
            content = $finalPrompt
        })
        temperature = 0.3
    } | ConvertTo-Json -Depth 3)

# Output summary
$response.choices[0].message.content
