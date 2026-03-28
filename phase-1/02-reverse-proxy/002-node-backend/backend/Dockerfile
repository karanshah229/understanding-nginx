# Build stage
FROM node:24-alpine AS build

# Install pnpm for faster dependency management
RUN npm install -g pnpm

WORKDIR /app

# Copy package and lock files to install dependencies separately for caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies (only production if needed, but build might need devDeps if there were any)
RUN pnpm install --frozen-lockfile --prod

# Copy the rest of the application
COPY . .

# Final stage
FROM node:24-alpine

WORKDIR /app

# Copy only the necessary files from the build stage
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/index.js ./index.js

# Expose the application port
EXPOSE 3000

# Run in production mode
ENV NODE_ENV=production

# Command to start the application
CMD ["node", "index.js"]
