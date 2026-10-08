# Chargini Backend

NestJS API for the Chargini mobile application.

## Requirements

- Node.js with npm or pnpm
- MongoDB running on `127.0.0.1:27017`

## Start the backend

```powershell
npm install
npm run start:dev
```

The API listens on `http://localhost:3000` by default.

## User registration

```http
POST /users
Content-Type: application/json
```

Required fields: `firstName`, `lastName`, `birthDate`, `email`, `phone`,
`gender`, `role`, and `password`.

Passwords are hashed with bcrypt and are never returned by the API.
Duplicate email addresses return HTTP `409 Conflict`.

## Flutter API address

The Flutter app automatically uses:

- Android emulator: `http://10.0.2.2:3000`
- Web, iOS simulator, and desktop: `http://127.0.0.1:3000`

For a physical phone, use the computer's local network address:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:3000
```
