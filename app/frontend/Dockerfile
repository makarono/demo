# Stage 1: Build the React app
FROM node:14 AS build
ARG env=local
WORKDIR /app
COPY . .
RUN npm ci --silent
RUN npm run build:${env}

# Stage 2: Serve the static files
FROM nginx:1.24.0-alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]