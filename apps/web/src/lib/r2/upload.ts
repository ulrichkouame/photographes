import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'

const R2_ACCOUNT_ID = process.env.CLOUDFLARE_R2_ACCOUNT_ID ?? ''
const R2_ACCESS_KEY = process.env.CLOUDFLARE_R2_ACCESS_KEY_ID ?? ''
const R2_SECRET_KEY = process.env.CLOUDFLARE_R2_SECRET_ACCESS_KEY ?? ''
const R2_BUCKET = process.env.CLOUDFLARE_R2_BUCKET_NAME ?? 'photographes-portfolio'
const R2_PUBLIC_URL = process.env.CLOUDFLARE_R2_PUBLIC_URL ?? ''

export const r2Client = new S3Client({
  region: 'auto',
  endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY,
    secretAccessKey: R2_SECRET_KEY,
  },
})

export async function generatePresignedUploadUrl(key: string, contentType: string) {
  const command = new PutObjectCommand({
    Bucket: R2_BUCKET,
    Key: key,
    ContentType: contentType,
  })
  const url = await getSignedUrl(r2Client, command, { expiresIn: 3600 })
  return { url, publicUrl: `${R2_PUBLIC_URL}/${key}` }
}

export async function deleteFromR2(key: string) {
  const command = new DeleteObjectCommand({ Bucket: R2_BUCKET, Key: key })
  await r2Client.send(command)
}

export function getPublicUrl(key: string) {
  return `${R2_PUBLIC_URL}/${key}`
}
