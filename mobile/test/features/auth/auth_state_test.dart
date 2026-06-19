import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('AuthState.copyWith', () {
    test('copyWith avec clearError efface le message d erreur', () {
      const state = AuthState(error: 'Erreur test');
      final updated = state.copyWith(clearError: true);
      expect(updated.error, isNull);
    });

    test('copyWith préserve les valeurs non modifiées', () {
      const state = AuthState(isLoading: true, isAuthenticated: false);
      final updated = state.copyWith(isAuthenticated: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isAuthenticated, isTrue);
    });

    test('état initial est cohérent', () {
      const state = AuthState();
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, isNull);
      expect(state.user, isNull);
    });
  });
}
