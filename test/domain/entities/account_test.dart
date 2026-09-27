import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/account.dart';

void main() {
  test('Account has value equality and a readable toString', () {
    const a = Account(displayName: 'Kyon', email: 'kyon@example.com');
    const b = Account(displayName: 'Kyon', email: 'kyon@example.com');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == const Account(displayName: 'Kyon'), isFalse);
    expect(a.toString(), 'Account(Kyon)');
  });
}
