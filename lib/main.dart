import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const CalculatorPage(title: 'Calculator'),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.title});
  final String title;
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  // ----------------- state -----------------
  String _display = '0';     // ตัวเลขที่พิมพ์อยู่/ผลลัพธ์
  double? _acc;              // สะสมค่าก่อนหน้า
  String? _op;               // operator ปัจจุบัน
  bool _overwrite = true;    // เริ่มพิมพ์ตัวเลขใหม่หรือพิมพ์ต่อท้าย
  bool _justEqual = false;   // เพิ่งกด = ไปล่าสุดไหม (ถ้าใช่แล้วพิมพ์ใหม่จะเริ่มสูตรใหม่)

  // ----------------- helpers -----------------
  double _toDouble(String s) => double.tryParse(s) ?? 0.0;

  String _fmt(double v) {
    var s = v.toStringAsFixed(10).replaceFirst(RegExp(r'\.?0+$'), '');
    if (s.length > 14) s = v.toStringAsExponential(6);
    return s;
  }

  String get _exprLine {
    // แสดงสูตรตามที่กด เช่น "12+3" หรือ "12+"
    if (_op != null && _acc != null) {
      return '${_fmt(_acc!)}$_op${_overwrite ? '' : _display}';
    }
    return _display; // ยังไม่เลือก operator
  }

  void _pressDigit(String d) {
    setState(() {
      if (_justEqual) {
        // เริ่มสูตรใหม่หลังจากกด =
        _acc = null;
        _op = null;
        _display = '0';
        _overwrite = true;
        _justEqual = false;
      }
      if (_overwrite) {
        _display = (d == '.' ? '0.' : d);
        _overwrite = false;
      } else {
        if (d == '.' && _display.contains('.')) return;
        if (_display == '0' && d != '.') {
          _display = d;
        } else {
          _display += d;
        }
      }
    });
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _acc = null;
      _op = null;
      _overwrite = true;
      _justEqual = false;
    });
  }

  void _deleteOne() {
    setState(() {
      if (_overwrite) return;
      if (_display.length <= 1 || (_display.length == 2 && _display.startsWith('-'))) {
        _display = '0';
        _overwrite = true;
      } else {
        _display = _display.substring(0, _display.length - 1);
      }
    });
  }

  void _percent() {
    setState(() {
      final v = _toDouble(_display) / 100.0;
      _display = _fmt(v);
      _overwrite = true;
    });
  }

  void _setOperator(String op) {
    setState(() {
      _justEqual = false;
      final cur = _toDouble(_display);
      if (_acc == null) {
        _acc = cur;
      } else if (_op != null && !_overwrite) {
        _acc = _apply(_acc!, cur, _op!);
        _display = _fmt(_acc!);
      }
      _op = op;
      _overwrite = true;     // เตรียมพิมพ์เลขตัวถัดไป
    });
  }

  void _equal() {
    setState(() {
      if (_op == null || _acc == null) return;
      final cur = _toDouble(_display);
      final res = _apply(_acc!, cur, _op!);
      _display = _fmt(res);
      _acc = null;
      _op = null;
      _overwrite = true;
      _justEqual = true;
    });
  }

  double _apply(double a, double b, String op) {
    switch (op) {
      case '+': return a + b;
      case '−': return a - b;
      case '×': return a * b;
      case '÷': return b == 0 ? double.nan : a / b;
      default:  return b;
    }
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    final btnTextStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.w600,
        );

    Widget btn(String text,
        {VoidCallback? onPressed, bool primary = false, bool danger = false}) {
      final bg = primary
          ? Theme.of(context).colorScheme.primary
          : danger
              ? Colors.red.shade400
              : Theme.of(context).colorScheme.surfaceVariant;
      final fg = primary ? Colors.white : null;

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
            ),
            onPressed: onPressed,
            child: Text(text, style: btnTextStyle),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ------ expression line (เล็ก) ------
            Container(
              height: 28,
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _exprLine,                       // <<<<<< แสดงสูตรตามที่กด
                  style: const TextStyle(fontSize: 22, color: Colors.grey),
                ),
              ),
            ),
            // ------ result / current input (ใหญ่) ------
            Container(
              height: 72,
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _display,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                  flex: 3,
                  child: Column(children: [
                    Row(children: [
                      btn('C', onPressed: _clearAll, danger: true),
                      btn('%', onPressed: _percent),
                      btn('DEL', onPressed: _deleteOne),
                    ]),
                    Row(children: [
                      btn('7', onPressed: () => _pressDigit('7')),
                      btn('8', onPressed: () => _pressDigit('8')),
                      btn('9', onPressed: () => _pressDigit('9')),
                    ]),
                    Row(children: [
                      btn('4', onPressed: () => _pressDigit('4')),
                      btn('5', onPressed: () => _pressDigit('5')),
                      btn('6', onPressed: () => _pressDigit('6')),
                    ]),
                    Row(children: [
                      btn('1', onPressed: () => _pressDigit('1')),
                      btn('2', onPressed: () => _pressDigit('2')),
                      btn('3', onPressed: () => _pressDigit('3')),
                    ]),
                    Row(children: [
                      btn('00', onPressed: () => _pressDigit('00')),
                      btn('0', onPressed: () => _pressDigit('0')),
                      btn('.', onPressed: () => _pressDigit('.')),
                    ]),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      btn('÷', onPressed: () => _setOperator('÷')),
                      btn('×', onPressed: () => _setOperator('×')),
                      btn('−', onPressed: () => _setOperator('−')),
                      btn('+', onPressed: () => _setOperator('+')),
                      btn('=', primary: true, onPressed: _equal),
                    ],
                  ),
                )
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
