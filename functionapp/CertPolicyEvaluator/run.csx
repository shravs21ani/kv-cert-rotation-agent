#r "System.Runtime"
#r "System.IO"
#r "Newtonsoft.Json"
#r "Microsoft.Azure.WebJobs.Extensions.Http"
#r "System.Net.Http"
#r "Microsoft.AspNetCore.Http"
#r "System.Threading.Tasks"
#r "Microsoft.Extensions.Logging"

using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

public static async Task<IActionResult> Run(
    HttpRequest req,
    ILogger log)
{
    log.LogInformation("Processing certificate policy evaluation request");

    try
    {
        string requestBody;
        using (var reader = new StreamReader(req.Body))
        {
            requestBody = await reader.ReadToEndAsync();
        }

        if (string.IsNullOrEmpty(requestBody))
        {
            log.LogWarning("Empty request body received");
            return new BadRequestObjectResult("Request body is empty");
        }

        var cert = JsonConvert.DeserializeObject<CertificateInfo>(requestBody);

        if (cert == null || string.IsNullOrEmpty(cert.Issuer) ||
            string.IsNullOrEmpty(cert.Expires) || string.IsNullOrEmpty(cert.Thumbprint))
        {
            log.LogWarning("Invalid certificate information received");
            return new BadRequestObjectResult("Invalid certificate information");
        }

        if (!DateTime.TryParse(cert.Expires, out DateTime expiryDate))
        {
            log.LogWarning($"Invalid expiry date format: {cert.Expires}");
            return new BadRequestObjectResult("Invalid expiry date format");
        }

        var daysLeft = (expiryDate - DateTime.UtcNow).TotalDays;

        var result = new PolicyResult
        {
            Action = DetermineAction(cert.Issuer, daysLeft, cert.Thumbprint),
            Reason = $"Certificate expires in {Math.Round(daysLeft)} days. Policy evaluated based on issuer and thumbprint."
        };

        log.LogInformation($"Policy evaluation complete. Action: {result.Action}, Days until expiry: {Math.Round(daysLeft)}");
        return new OkObjectResult(result);
    }
    catch (JsonException ex)
    {
        log.LogError($"JSON parsing error: {ex.Message}");
        return new BadRequestObjectResult("Invalid JSON format in request body");
    }
    catch (Exception ex)
    {
        log.LogError($"Error processing request: {ex.Message}");
        return new StatusCodeResult(StatusCodes.Status500InternalServerError);
    }
}

private static string DetermineAction(string issuer, double daysLeft, string thumbprint)
{
    if (string.IsNullOrEmpty(issuer) || string.IsNullOrEmpty(thumbprint))
    {
        return "Manual";
    }
    
    return (issuer.Contains("DigiCert", StringComparison.OrdinalIgnoreCase) && 
            daysLeft < 30 && 
            !thumbprint.StartsWith("ABC", StringComparison.OrdinalIgnoreCase))
        ? "AutoRenew"
        : "Manual";
}

public class CertificateInfo
{
    public string Issuer { get; set; }
    public string Expires { get; set; }
    public string Thumbprint { get; set; }
}

public class PolicyResult
{
    public string Action { get; set; }
    public string Reason { get; set; }
}