# Flutter Integration Documentation

Welcome to the comprehensive API documentation and Flutter integration guide for the Hotel Management System Django REST Framework API.

## 📚 Documentation Structure

This documentation is organized into three main sections:

### 1. [Swagger/OpenAPI Documentation](./swagger/)
- **openapi.yaml** - Complete OpenAPI 3.0 specification for all API endpoints
- Interactive API documentation that can be viewed in Swagger UI or Postman

### 2. [API Documentation](./api_documentation/)
- **[API_OVERVIEW.md](./api_documentation/API_OVERVIEW.md)** - Overview of the API architecture, base URL, and general information
- **[ENDPOINTS.md](./api_documentation/ENDPOINTS.md)** - Detailed documentation of all API endpoints
- **[AUTHENTICATION.md](./api_documentation/AUTHENTICATION.md)** - Authentication methods, JWT tokens, and security
- **[ERROR_HANDLING.md](./api_documentation/ERROR_HANDLING.md)** - Error response formats and handling strategies

### 3. [Flutter Integration](./flutter_integration/)
- **[SETUP_GUIDE.md](./flutter_integration/SETUP_GUIDE.md)** - Initial setup and project configuration
- **[HTTP_CLIENT_SETUP.md](./flutter_integration/HTTP_CLIENT_SETUP.md)** - HTTP client configuration with Dio
- **[API_SERVICE_EXAMPLE.dart](./flutter_integration/API_SERVICE_EXAMPLE.dart)** - Complete API service implementation
- **[AUTHENTICATION_EXAMPLE.dart](./flutter_integration/AUTHENTICATION_EXAMPLE.dart)** - Authentication flow implementation
- **[REQUEST_RESPONSE_EXAMPLES.md](./flutter_integration/REQUEST_RESPONSE_EXAMPLES.md)** - Request/response examples for common operations
- **[COMMON_ISSUES.md](./flutter_integration/COMMON_ISSUES.md)** - Troubleshooting guide for common issues

## 🚀 Quick Start

1. **Read the API Overview** - Start with [API_OVERVIEW.md](./api_documentation/API_OVERVIEW.md) to understand the API structure
2. **Set Up Flutter Project** - Follow [SETUP_GUIDE.md](./flutter_integration/SETUP_GUIDE.md) to configure your Flutter app
3. **Configure HTTP Client** - Set up Dio client using [HTTP_CLIENT_SETUP.md](./flutter_integration/HTTP_CLIENT_SETUP.md)
4. **Implement Authentication** - Use [AUTHENTICATION_EXAMPLE.dart](./flutter_integration/AUTHENTICATION_EXAMPLE.dart) as a reference
5. **Build API Services** - Follow [API_SERVICE_EXAMPLE.dart](./flutter_integration/API_SERVICE_EXAMPLE.dart) patterns

## 🔑 Key Features

- **JWT Token Authentication** - Secure token-based authentication
- **OTP-based Login** - Mobile number verification for user authentication
- **RESTful API Design** - Standard REST conventions
- **Comprehensive Error Handling** - Detailed error responses
- **Real-time Updates** - WebSocket support for live data
- **File Upload Support** - Image and document uploads
- **Pagination** - Efficient data pagination
- **Filtering & Search** - Advanced query capabilities

## 📱 API Base URL

**Development:**
```
http://localhost:8000/api
```

**Production:**
```
https://your-domain.com/api
```

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication. See [AUTHENTICATION.md](./api_documentation/AUTHENTICATION.md) for detailed information.

## 📦 Required Flutter Packages

```yaml
dependencies:
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.2
  flutter_secure_storage: ^9.0.0
```

## 🛠️ Development Tools

- **Swagger UI** - View interactive API documentation
- **Postman** - Import OpenAPI spec for testing
- **Dio Inspector** - Debug HTTP requests in Flutter

## 📞 Support

For issues or questions:
1. Check [COMMON_ISSUES.md](./flutter_integration/COMMON_ISSUES.md) first
2. Review the API documentation
3. Contact the development team

## 📄 License

This API documentation is part of the Hotel Management System project.

---

**Last Updated:** 2024
**API Version:** 1.0.0

