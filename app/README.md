# EaglEs Property Flutter shell

This directory contains the Phase 1 navigation and tenant-aware session shell.

## Run

1. Install Flutter dependencies with `flutter pub get`.
2. Add platform Firebase configuration using the FlutterFire CLI for the target platform.
3. Configure Firebase Auth and create active membership documents at `users/{uid}/memberships/{tenantId}`.
4. Run `flutter analyze` and `flutter test`.

The demo sign-in is intentionally local-only and does not authenticate against Firebase.
