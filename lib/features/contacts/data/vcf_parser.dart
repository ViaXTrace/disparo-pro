/// Parser de arquivos VCF (vCard 2.1, 3.0 e 4.0).
/// Implementação 100% Dart — sem dependências externas.
class VcfParser {
  /// Analisa o conteúdo de um arquivo VCF e retorna a lista de contatos.
  static List<VcfContact> parse(String vcfContent) {
    final contacts = <VcfContact>[];
    final lines = _unfold(vcfContent);

    String? fn;
    String? n;
    String? phone;
    String? email;
    bool inCard = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final upper = trimmed.toUpperCase();

      if (upper == 'BEGIN:VCARD') {
        inCard = true;
        fn = null;
        n = null;
        phone = null;
        email = null;
        continue;
      }
      if (upper == 'END:VCARD') {
        if (inCard && phone != null && phone.isNotEmpty) {
          final name = (fn?.trim().isNotEmpty == true
                  ? fn!
                  : n?.trim().isNotEmpty == true
                      ? n!
                      : null) ??
              phone;
          contacts.add(VcfContact(name: name, phone: phone, email: email));
        }
        inCard = false;
        continue;
      }
      if (!inCard) continue;

      final colonIdx = trimmed.indexOf(':');
      if (colonIdx == -1) continue;
      final keyPart = trimmed.substring(0, colonIdx).toUpperCase();
      final value = trimmed.substring(colonIdx + 1);

      // FN (Formatted Name — preferred)
      if (keyPart == 'FN' || keyPart.startsWith('FN;')) {
        final decoded = _decode(value);
        if (decoded.isNotEmpty) fn = decoded;
        continue;
      }

      // N (structured: Last;First;Middle;Prefix;Suffix)
      if ((keyPart == 'N' || keyPart.startsWith('N;')) && fn == null) {
        final parts = value.split(';').map(_decode).toList();
        final last = parts.isNotEmpty ? parts[0].trim() : '';
        final first = parts.length > 1 ? parts[1].trim() : '';
        final full = [first, last].where((s) => s.isNotEmpty).join(' ');
        if (full.isNotEmpty) n = full;
        continue;
      }

      // TEL — aceita qualquer parâmetro de tipo (CELL, HOME, WORK, VOICE…)
      if (keyPart.contains('TEL') && phone == null) {
        final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
        if (cleaned.isNotEmpty) phone = cleaned;
        continue;
      }

      // EMAIL
      if (keyPart.contains('EMAIL') && email == null) {
        final v = _decode(value).trim();
        if (v.isNotEmpty) email = v;
        continue;
      }
    }

    return contacts;
  }

  // ── internals ─────────────────────────────────────────────────────────────

  /// Unfold multi-line values (RFC 6350 §3.2): linhas que começam com SP/TAB
  /// são continuação da linha anterior.
  static List<String> _unfold(String content) {
    final normalized = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final unfolded = normalized.replaceAll(RegExp(r'\n[ \t]'), '');
    return unfolded.split('\n');
  }

  /// Decodifica valores vCard:
  /// - Quoted-Printable (vCard 2.1): =XX
  /// - Escape sequences: \,  \;  \n  \N
  static String _decode(String value) {
    String result = value;
    // Quoted-Printable soft line breaks
    result = result.replaceAll('=\n', '');
    // QP hex sequences
    result = result.replaceAllMapped(
      RegExp(r'=([0-9A-Fa-f]{2})'),
      (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
    );
    // vCard escape sequences
    result = result
        .replaceAll('\\,', ',')
        .replaceAll('\\;', ';')
        .replaceAll('\\:', ':')
        .replaceAll('\\n', '\n')
        .replaceAll('\\N', '\n')
        .replaceAll('\\\\', '\\');
    return result.trim();
  }
}

class VcfContact {
  final String name;
  final String phone;
  final String? email;
  const VcfContact({required this.name, required this.phone, this.email});
}
