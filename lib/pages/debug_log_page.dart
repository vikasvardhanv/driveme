import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/utils/logger.dart';

class DebugLogPage extends StatelessWidget {
  const DebugLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: LogService(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debug Logs'),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                final logs = LogService().logs.map((e) => e.toString()).join('\n');
                Clipboard.setData(ClipboardData(text: logs));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logs copied to clipboard')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                LogService().clear();
              },
            ),
          ],
        ),
        body: Consumer<LogService>(
          builder: (context, logService, child) {
            final logs = logService.logs;
            if (logs.isEmpty) {
              return const Center(child: Text('No logs yet'));
            }
            return ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text(
                    log.message,
                    style: TextStyle(
                      color: _getColor(log.level),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                  subtitle: Text(
                    log.timestamp.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.black;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.api:
        return Colors.blue;
    }
  }
}
