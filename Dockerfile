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
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html

RUN chgrp -R root /var/cache/nginx /var/run /var/log/nginx && \
  chmod -R 770 /var/cache/nginx /var/run /var/log/nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]