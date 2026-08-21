import 'package:flutter/material.dart';
import '../../../core/services/sync_manager.dart';
import '../../../domain/entities/expense.dart';
import '../../../injection/injection_container.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final syncManager = sl<SyncManager>();

    return StreamBuilder<SyncStatus>(
      stream: syncManager.syncStatusStream,
      initialData: syncManager.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.synced;

        if (compact) {
          return _buildCompactIcon(context, status, syncManager);
        }

        return _buildBanner(context, status, syncManager);
      },
    );
  }

  Widget _buildCompactIcon(BuildContext context, SyncStatus status, SyncManager syncManager) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      case SyncStatus.pending:
        return IconButton(
          icon: const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
          tooltip: 'غير متصل — يتم عرض آخر بيانات تمت مزامنتها',
          onPressed: () => syncManager.syncAll(),
        );
      case SyncStatus.failed:
        return IconButton(
          icon: const Icon(Icons.sync_problem, color: Colors.red, size: 20),
          tooltip: 'فشلت المزامنة — انقر لإعادة المحاولة',
          onPressed: () => syncManager.syncAll(),
        );
      case SyncStatus.synced:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBanner(BuildContext context, SyncStatus status, SyncManager syncManager) {
    if (status == SyncStatus.synced) return const SizedBox.shrink();

    final Color bgColor;
    final IconData icon;
    final String message;
    final bool showRetry;

    switch (status) {
      case SyncStatus.syncing:
        bgColor = Colors.orange.shade700;
        icon = Icons.sync;
        message = 'جارٍ مزامنة البيانات مع الخادم...';
        showRetry = false;
        break;
      case SyncStatus.pending:
        bgColor = Colors.blueGrey.shade800;
        icon = Icons.cloud_off;
        message = 'غير متصل بالإنترنت — يتم عرض آخر بيانات محفوظة محلياً';
        showRetry = true;
        break;
      case SyncStatus.failed:
        bgColor = Colors.red.shade800;
        icon = Icons.sync_problem;
        message = 'تعذر إتمام المزامنة — انقر لإعادة المحاولة';
        showRetry = true;
        break;
      case SyncStatus.synced:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            status == SyncStatus.syncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showRetry)
              InkWell(
                onTap: () => syncManager.syncAll(),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'مزامنة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
