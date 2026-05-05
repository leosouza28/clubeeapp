import 'package:intl/intl.dart';

class Formatters {
  // Formata um número para moeda brasileira (Real)
  static String currency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  // Formata um número para moeda brasileira sem o símbolo
  static String currencyWithoutSymbol(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(value).trim();
  }

  // Formata um número para moeda brasileira compacta (ex: R$ 1,5 mil)
  static String currencyCompact(double value) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 1,
    );
    return formatter.format(value);
  }

  // Formata CPF: 000.000.000-00
  static String cpf(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length != 11) return value;
    return '${value.substring(0, 3)}.${value.substring(3, 6)}.${value.substring(6, 9)}-${value.substring(9)}';
  }

  // Formata CNPJ: 00.000.000/0000-00
  static String cnpj(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length != 14) return value;
    return '${value.substring(0, 2)}.${value.substring(2, 5)}.${value.substring(5, 8)}/${value.substring(8, 12)}-${value.substring(12)}';
  }

  // Formata CPF ou CNPJ automaticamente
  static String cpfCnpj(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length == 11) {
      return cpf(value);
    } else if (value.length == 14) {
      return cnpj(value);
    }
    return value;
  }

  // Formata telefone: (00) 00000-0000 ou (00) 0000-0000
  static String phone(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length == 11) {
      return '(${value.substring(0, 2)}) ${value.substring(2, 7)}-${value.substring(7)}';
    } else if (value.length == 10) {
      return '(${value.substring(0, 2)}) ${value.substring(2, 6)}-${value.substring(6)}';
    }
    return value;
  }

  // Formata CEP: 00000-000
  static String cep(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length != 8) return value;
    return '${value.substring(0, 5)}-${value.substring(5)}';
  }

  // Formata data: DD/MM/YYYY
  static String date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  static String dateFromString(String dateString) {
    return dateString.split("T")[0].split("-").reversed.join("/");
  }

  // Formata data e hora: DD/MM/YYYY HH:mm
  static String dateTime(DateTime dateTime) {
    // aplicar o fuso 
    dateTime = dateTime.toLocal();
    return '${date(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Formata data e hora completa: DD/MM/YYYY HH:mm:ss
  static String dateTimeFull(DateTime dateTime) {
    return '${date(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  // Formata porcentagem
  static String percentage(double value, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Formata número com separador de milhares
  static String number(num value, {int decimals = 0}) {
    final formatter = NumberFormat('#,##0', 'pt_BR');
    if (decimals > 0) {
      return NumberFormat('#,##0.${'0' * decimals}', 'pt_BR').format(value);
    }
    return formatter.format(value);
  }
}
