FROM node:20 AS frontend-build
WORKDIR /app
COPY OSV/package.json .
COPY OSV/package-lock.json .
RUN npm install
COPY OSV/tailwind.config.js .
COPY OSV/postcss.config.js .
COPY OSV/wwwroot/css/input.css ./wwwroot/css/input.css
RUN npm run css:build # This runs the script from your package.json


FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src


COPY OSV/OSV.sln OSV/
COPY OSV/OSV.csproj OSV/
COPY Data.Business/Data.Business.csproj Data.Business/
COPY Data.Access/Data.Access.csproj Data.Access/


RUN dotnet restore "OSV/OSV.sln"



COPY . .


COPY --from=frontend-build /app/wwwroot/css/site.css ./OSV/wwwroot/css/site.css


WORKDIR "/src/OSV"
RUN dotnet build "OSV.csproj" -c Release -o /app/build


FROM build AS publish
RUN dotnet publish "OSV.csproj" -c Release -o /app/publish /p:UseAppHost=false


FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "OSV.dll"]
