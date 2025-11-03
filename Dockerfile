# STAGE 1: Build Frontend Assets (Node.js/Tailwind)
FROM node:20 AS frontend-build
WORKDIR /app
COPY OSV/package.json .
COPY OSV/package-lock.json .
RUN npm install
COPY OSV/tailwind.config.js .
COPY OSV/postcss.config.js .
COPY OSV/wwwroot/css/input.css ./wwwroot/css/input.css
RUN npm run css:build # This runs the script from your package.json

# STAGE 2: Build Backend (.NET SDK)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy all .csproj files and restore (efficient layer caching)
COPY OSV/OSV.csproj OSV/
COPY Data.Business/Data.Business.csproj Data.Business/
COPY Data.Access/Data.Access.csproj Data.Access/

# Restore dependencies for the main project
RUN dotnet restore "OSV/OSV.csproj"

# Copy all source code
COPY . .

# Copy the built CSS from the frontend stage
COPY --from=frontend-build /app/wwwroot/css/site.css ./OSV/wwwroot/css/site.css

# Build the main project
WORKDIR "/src/OSV"
RUN dotnet build "OSV.csproj" -c Release -o /app/build

# STAGE 3: Publish
FROM build AS publish
RUN dotnet publish "OSV.csproj" -c Release -o /app/publish /p:UseAppHost=false

# STAGE 4: Final Production Image (ASP.NET Runtime)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "OSV.dll"]