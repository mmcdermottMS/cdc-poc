﻿using Azure.Identity;
using CDC.Domain.Interfaces;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;
using System;

[assembly: FunctionsStartup(typeof(CDC.SbConsumer.Startup))]
namespace CDC.SbConsumer
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddSingleton<ICosmosDbService>(new CosmosDbService(new CosmosClient(Environment.GetEnvironmentVariable("CosmosHost"), new DefaultAzureCredential())));
            builder.Services.AddSingleton<ITelemetryInitializer, CloudRoleNameTelemetryInitializer>();
        }
    }
}
