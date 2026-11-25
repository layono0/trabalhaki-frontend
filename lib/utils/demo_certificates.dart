import 'dart:convert';
import 'dart:typed_data';

String _pdfEscapeLatin1(String text) {
  final bytes = latin1.encode(text);
  final sb = StringBuffer();
  for (final b in bytes) {
    if (b == 40 || b == 41 || b == 92) {
      sb.write('\\${String.fromCharCode(b)}');
    } else if (b >= 32 && b <= 126) {
      sb.writeCharCode(b);
    } else {
      sb.write('\\${b.toRadixString(8).padLeft(3, '0')}');
    }
  }
  return sb.toString();
}

Uint8List _buildPdf({
  required List<String> lines,
  required String creator,
  required String producer,
  required String author,
  required String creationDate,
  required String modDate,
  bool appendIncrementalTamper = false,
}) {
  final streamSb = StringBuffer()
    ..writeln('BT')
    ..writeln('/F1 13 Tf')
    ..writeln('50 760 Td')
    ..writeln('18 TL');
  for (var i = 0; i < lines.length; i++) {
    final esc = _pdfEscapeLatin1(lines[i]);
    if (i == 0) {
      streamSb.writeln('($esc) Tj');
    } else {
      streamSb.writeln('T* ($esc) Tj');
    }
  }
  streamSb.writeln('ET');
  final contentBytes = latin1.encode(streamSb.toString());

  final objects = <List<int>>[
    latin1.encode('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'),
    latin1.encode('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'),
    latin1.encode(
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
      '/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n',
    ),
    latin1.encode(
      '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n',
    ),
    <int>[
      ...latin1.encode('5 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n'),
      ...contentBytes,
      ...latin1.encode('endstream\nendobj\n'),
    ],
    latin1.encode(
      '6 0 obj\n<< /Creator (${_pdfEscapeLatin1(creator)}) '
      '/Producer (${_pdfEscapeLatin1(producer)}) '
      '/Author (${_pdfEscapeLatin1(author)}) '
      '/CreationDate ($creationDate) '
      '/ModDate ($modDate) >>\nendobj\n',
    ),
  ];

  final out = BytesBuilder();
  out.add(<int>[...latin1.encode('%PDF-1.4\n%'), 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);

  final offsets = <int>[0];
  for (final obj in objects) {
    offsets.add(out.length);
    out.add(obj);
  }

  final xrefPos = out.length;
  final total = objects.length + 1;
  out.add(latin1.encode('xref\n0 $total\n'));
  out.add(latin1.encode('0000000000 65535 f \n'));
  for (var i = 1; i < offsets.length; i++) {
    out.add(latin1.encode('${offsets[i].toString().padLeft(10, '0')} 00000 n \n'));
  }
  out.add(
    latin1.encode(
      'trailer\n<< /Size $total /Root 1 0 R /Info 6 0 R >>\nstartxref\n$xrefPos\n%%EOF\n',
    ),
  );

  if (appendIncrementalTamper) {
    final extraOff = out.length;
    out.add(latin1.encode('7 0 obj\n<< /Type /ExtGState /ca 1.0 >>\nendobj\n'));
    final extraXref = out.length;
    out.add(latin1.encode('xref\n7 1\n${extraOff.toString().padLeft(10, '0')} 00000 n \n'));
    out.add(
      latin1.encode(
        'trailer\n<< /Size 8 /Prev $xrefPos /Root 1 0 R /Info 6 0 R >>\nstartxref\n$extraXref\n%%EOF\n',
      ),
    );
  }

  return out.toBytes();
}

/// Sample authentic certificate for local kDebugMode demonstrations.
Uint8List buildAuthenticAluraPdf(String holderName, String skill) {
  final stamp = DateTime.now().millisecondsSinceEpoch;
  return _buildPdf(
    lines: [
      'ALURA CURSOS ONLINE',
      'Certificado de Conclusão',
      'Certificamos que $holderName concluiu com aproveitamento',
      'Curso: Formação Especialista em $skill',
      'Carga horária: 40 horas',
      'Emitido em 15/09/2026',
      'Código de autenticidade: ALURA-$stamp',
      'https://cursos.alura.com.br/certificate/$stamp',
    ],
    creator: 'Alura Certificate System',
    producer: 'WeasyPrint 62.3',
    author: 'Alura',
    creationDate: 'D:20260915142000Z',
    modDate: 'D:20260915142000Z',
  );
}

/// Sample tampered certificate triggering Python metadata anti-fraud checks.
Uint8List buildTamperedPhotoshopPdf(String holderName, String skill) {
  return _buildPdf(
    lines: [
      'ALURA CURSOS ONLINE',
      'Certificado de Conclusão',
      'Certificamos que $holderName concluiu com aproveitamento',
      'Curso: Formação em $skill',
      'Carga horária: 40 horas',
      'Emitido em 15/09/2026',
      'https://cursos.alura.com.br/certificate/999999-fake',
    ],
    creator: 'Adobe Photoshop 25.0 (Windows)',
    producer: 'Adobe PDF Library 17.0',
    author: 'Editor',
    creationDate: 'D:20260915140000Z',
    modDate: 'D:20260915164500Z',
    appendIncrementalTamper: true,
  );
}
