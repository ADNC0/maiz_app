# maiz_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuration & Security

This project communicates with a backend API and therefore requires a
base URL to be supplied at runtime. Create a `.env` file in the root of this folder with the following content:

```
API_BASE_URL=https://api.miapp.com
```

An example is provided in `.env.example`.

> **Note for device testing:** Flutter does not automatically bundle
> non‑code files. If you run on a physical device without copying `.env` to
> the app's storage you will see a `FileNotFoundError` during startup; the
> code now catches this and falls back to the hard‑coded local IP, but to
> change the URL you still need to edit/create `.env` before running.

If you prefer the file to be bundled, add this line under `flutter.assets`
in `pubspec.yaml`:

```yaml
- .env
```

and then `flutter pub get` again.
Additional dependencies have been added for secure storage of JWT tokens
and environment variable loading; run `flutter pub get` after pulling
latest changes.

The mobile client now obtains a JSON Web Token from the server during
login/registration and automatically includes it in the `Authorization`
header of every request. The token is saved in `flutter_secure_storage`
and cleared on logout or when the server returns a 401 status.

Make sure the backend you deploy implements the corresponding token
endpoints (see docs or coordinate with the backend team).

When preparing the app for release, remove any `.env` files from
version control and replace the development URL with your production
domain.
