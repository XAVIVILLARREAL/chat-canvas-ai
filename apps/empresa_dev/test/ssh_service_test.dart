import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/ssh_service.dart';

void main() {
  group('SshHost', () {
    test('crea un host con valores por defecto', () {
      final h = SshHost(host: '192.168.100.200', username: 'root', name: 'pve');
      expect(h.port, 22);
      expect(h.host, '192.168.100.200');
      expect(h.username, 'root');
      expect(h.password, '');
      expect(h.name, 'pve');
    });

    test('acepta puerto personalizado', () {
      final h = SshHost(host: 'example.com', port: 2222, username: 'u', name: 'n');
      expect(h.port, 2222);
    });
  });
}
