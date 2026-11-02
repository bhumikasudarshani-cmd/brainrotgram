/// API constants from BRAINROTGRAM.md Part 3
class ApiConstants {
  ApiConstants._();

  /// Brainrotten hosted API
  static const String apiBaseUrl =
      'https://fqfewiusg8.execute-api.ap-south-1.amazonaws.com/api/v1';

  /// Cognito auth
  static const String cognitoDomain =
      'https://brainrotten.auth.ap-south-1.amazoncognito.com';
  static const String clientId = '162fuccsquq1md62vftam7cnjc';
  static const String issuer =
      'https://cognito-idp.ap-south-1.amazonaws.com/ap-south-1_QIYaO2Hex';
  static const String authorizeEndpoint =
      '$cognitoDomain/oauth2/authorize';
  static const String tokenEndpoint =
      '$cognitoDomain/oauth2/token';
  static const String logoutEndpoint =
      '$cognitoDomain/logout';
  static const String redirectUri = 'brainrotgram://auth/callback';
  static const String signOutUri = 'brainrotgram://auth/signout';
  static const String scopes = 'openid email profile';

  /// CDN
  static const String characterBaseUrl =
      'https://d3sk6lwsh4ufyv.cloudfront.net/characters';
  static const String websiteUrl =
      'https://d3sk6lwsh4ufyv.cloudfront.net';
}
