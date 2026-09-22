// Photo URL helpers shared by widgets and repositories.
//
// The API returns absolute R2 URLs (`https://...`) once R2 is switched on,
// but the temporary local storage returns app-relative paths (`/uploads/...`
// served from the API's wwwroot). Anything else is a device-local file path
// produced by `image_picker` that has not been uploaded yet.

/// Whether [path] points at the backend (absolute R2 URL or app-relative
/// `/uploads/...` path) rather than a device-local file.
bool isRemotePhoto(String path) {
  return path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('/');
}

/// Turns an API photo reference into something an image widget can load:
/// app-relative paths are prefixed with the API [baseUrl], everything else
/// passes through untouched.
String resolvePhotoUrl(String path, String baseUrl) {
  if (path.startsWith('/')) return '$baseUrl$path';
  return path;
}
