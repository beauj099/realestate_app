// Photo URL helpers shared by widgets and repositories.
//
// The API returns absolute R2 URLs (`https://...`) once R2 is switched on,
// but the temporary local storage returns app-relative paths (`/uploads/...`
// served from the API's wwwroot). Anything else is a device-local file path
// produced by `image_picker` that has not been uploaded yet.

/// Prefix of photos served by the API's temporary local storage.
const String _uploadsPrefix = '/uploads/';

/// Whether [path] points at the backend (absolute R2 URL or app-relative
/// `/uploads/...` path) rather than a device-local file.
///
/// Only `/uploads/` counts as app-relative: a device path such as
/// `/data/user/0/…/image.jpg` also starts with `/`, and treating it as a
/// server path made every not-yet-uploaded photo show as "Unavailable".
bool isRemotePhoto(String path) {
  return path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith(_uploadsPrefix);
}

/// Turns an API photo reference into something an image widget can load:
/// app-relative paths are prefixed with the API [baseUrl], everything else
/// passes through untouched.
String resolvePhotoUrl(String path, String baseUrl) {
  if (path.startsWith(_uploadsPrefix)) return '$baseUrl$path';
  return path;
}
