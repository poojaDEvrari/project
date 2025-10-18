// Fill these with your AWS credentials and bucket info.
// WARNING: Embedding long-term AWS keys in a mobile app is not recommended.
// Prefer Cognito or a backend token exchange. This is provided as a fallback
// to unblock development, mirroring the web reference.

const String awsRegion = 'YOUR_AWS_REGION'; // e.g., 'us-east-1'
const String awsBucket = 'YOUR_S3_BUCKET_NAME';
const String awsAccessKeyId = 'YOUR_ACCESS_KEY_ID';
const String awsSecretAccessKey = 'YOUR_SECRET_ACCESS_KEY';
// If using temporary credentials, add session token; otherwise leave empty
const String awsSessionToken = '';
