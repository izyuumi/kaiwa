# Security Policy

## Reporting a Vulnerability

Please report security issues responsibly:

1. **Do not** open a public issue
2. Use [GitHub's private vulnerability reporting](https://github.com/izyuumi/kaiwa/security/advisories/new)
3. Include reproduction steps and impact assessment

## Security Considerations

- **API keys**: Soniox and OpenAI keys are stored server-side in Convex environment variables. The iOS client receives rate-limited, time-scoped access.
- **Authentication**: User auth is handled by Clerk. No passwords are stored in the app.
- **Audio data**: Audio is streamed directly to Soniox via WebSocket. It is not stored on Convex servers.
- **Translations**: Text is sent to OpenAI for translation. Refer to OpenAI's data usage policy.
- **Network**: All connections use TLS (wss:// for Soniox, https:// for Convex and Clerk).
