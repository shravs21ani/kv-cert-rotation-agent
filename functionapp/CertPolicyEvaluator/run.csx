#r "Newtonsoft.Json"
#r "System.Net.Http"
using System.Net;
using Newtonsoft.Json;
public static async Task<HttpResponseMessage> Run(HttpRequestMessage req, ILogger log)
{
    var cert = await req.Content.ReadAsAsync<dynamic>();
    var issuer = (string)cert?.issuer;
    var expires = DateTime.Parse((string)cert?.expires);
    var thumbprint = (string)cert?.thumbprint;

    var daysLeft = (expires - DateTime.UtcNow).TotalDays;
    var result = new {
        action = (issuer.Contains("DigiCert") && daysLeft < 30 && !thumbprint.StartsWith("ABC"))
                    ? "AutoRenew" : "Manual",
        reason = "Policy evaluated based on issuer, expiry and thumbprint."
    };

    return req.CreateResponse(HttpStatusCode.OK, result);
}