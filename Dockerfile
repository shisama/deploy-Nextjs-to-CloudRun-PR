# Build the source code
FROM node:18-alpine AS installer
LABEL build-stage=installer
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json ./
COPY package-lock.json ./
ENV SKIP_PREPARE 'true'
RUN npm ci --production


# Production image, copy all the files and run next
FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV production
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
COPY --from=installer --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=installer --chown=nextjs:nodejs /app/package.json ./package.json
# Copy files from the host to perform next build caching on the host
COPY --chown=nextjs:nodejs ./.next ./.next
COPY --chown=nextjs:nodejs ./next.config.js ./

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV NO_NEXT_TRANSPILE 'true'

CMD ["npm", "start"]