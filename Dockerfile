#
# Build environment
# 
FROM node:13.12.0-alpine as build
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
COPY package.json ./
COPY package-lock.json ./
RUN npm ci --silent
RUN npm install react-scripts@3.4.1 -g --silent
COPY . ./
RUN npm run build

#
# Production environment
#
FROM nginxinc/nginx-unprivileged:latest

# Use root user to copy dist folder and modify user access to specific folder
USER root

# Copy application and custom NGINX configuration
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx config
COPY config/default.conf /etc/nginx/conf.d/default.conf 

# Setup unprivileged user 1001
RUN chown -R 1001 /usr/share/nginx/html

# Use user 1001
USER 1001

# Expose a port that is higher than 1024 due to unprivileged access
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]