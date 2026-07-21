import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionControllerProvider = AsyncNotifierProvider<SessionController, SessionState>(SessionController.new);

class TenantOption {
  const TenantOption({required this.id, required this.name});
  final String id;
  final String name;
}

class SessionState {
  const SessionState.unauthenticated()
      : isAuthenticated = false,
        tenantId = null,
        tenantName = '',
        role = '',
        tenants = const [];

  const SessionState.authenticated({
    required this.tenantId,
    required this.tenantName,
    required this.role,
    required this.tenants,
  }) : isAuthenticated = true;

  final bool isAuthenticated;
  final String? tenantId;
  final String tenantName;
  final String role;
  final List<TenantOption> tenants;
}

class SessionController extends AsyncNotifier<SessionState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<SessionState> build() async {
    final user = _auth.currentUser;
    if (user == null) return const SessionState.unauthenticated();
    return _loadFromToken(user, forceRefresh: true, claimsSyncAttempted: false);
  }

  Future<SessionState> _loadFromToken(
    User user, {
    required bool forceRefresh,
    required bool claimsSyncAttempted,
  }) async {
    final token = await user.getIdTokenResult(forceRefresh);
    final tenantId = token.claims?['tenantId'] as String?;
    final role = token.claims?['role'] as String?;
    final tenantIds = (token.claims?['tenants'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);

    if (tenantId == null || role == null) {
      if (claimsSyncAttempted) {
        throw StateError('Authentication claims are not available after synchronization.');
      }
      final callable = _functions.httpsCallable('syncUserClaims');
      await callable.call();
      await user.getIdToken(true);
      return _loadFromToken(user, forceRefresh: true, claimsSyncAttempted: true);
    }

    final tenantOptions = await _loadTenantOptions(tenantIds, tenantId);
    final activeTenant = tenantOptions.firstWhere((tenant) => tenant.id == tenantId);
    return SessionState.authenticated(
      tenantId: tenantId,
      tenantName: activeTenant.name,
      role: role,
      tenants: tenantOptions,
    );
  }

  Future<List<TenantOption>> _loadTenantOptions(List<String> tenantIds, String activeTenantId) async {
    final result = await _functions.httpsCallable('listTenantMemberships').call();
    final options = (result.data as List<dynamic>? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((item) => TenantOption(
              id: item['id'] as String? ?? activeTenantId,
              name: item['name'] as String? ?? activeTenantId,
            ))
        .where((tenant) => tenantIds.isEmpty || tenantIds.contains(tenant.id))
        .toList(growable: false);
    return options.isEmpty ? [TenantOption(id: activeTenantId, name: activeTenantId)] : options;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credentials = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return _loadFromToken(credentials.user!, forceRefresh: true, claimsSyncAttempted: false);
    });
  }

  Future<void> switchTenant(String tenantId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('switchTenant').call({'tenantId': tenantId});
      await user.getIdToken(true);
      return _loadFromToken(user, forceRefresh: true, claimsSyncAttempted: false);
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncData(SessionState.unauthenticated());
  }
}
