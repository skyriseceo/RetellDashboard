# Stage 0: Frontend (Node) - build CSS
FROM node:20 AS frontend-build
WORKDIR /app
# copy package files from the OSV web project
COPY OSV/package.json OSV/package-lock.json ./
RUN npm ci --silent
COPY OSV/tailwind.config.js OSV/postcss.config.js ./ 
COPY OSV/wwwroot/css/input.css ./wwwroot/css/input.css
WORKDIR /app
RUN npm run css:build

# Stage 1: Build .NET apps
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and project files for layer-cached restore
COPY *.sln ./
COPY Data.Access/*.csproj ./Data.Access/
COPY Data.Business/*.csproj ./Data.Business/
COPY OSV/*.csproj ./OSV/

# restore
RUN dotnet restore

# copy everything
COPY . .

# build main project (adjust project name if different)
WORKDIR /src/OSV
RUN dotnet build "OSV.csproj" -c Release -o /app/build

# publish
FROM build AS publish
WORKDIR /src/OSV
RUN dotnet publish "OSV.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage final: runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
COPY --from=publish /app/publish .
# If frontend assets were generated into OSV/wwwroot, they are included in publish step.
ENTRYPOINT ["dotnet", "OSV.dll"]
