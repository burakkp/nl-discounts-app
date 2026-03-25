import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _addItem() async {
    final product = _controller.text.trim();
    if (product.isEmpty) return;

    // 1. Show a loading dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Add the item to the Supabase Cloud Database
      await ref.read(apiServiceProvider).addToWatchlist(product);
      _controller.clear();

      // 3. 🔄 Force Riverpod to dump the old cache...
      ref.invalidate(watchlistProvider);
      // 4. ⏳ AND wait for the new data to arrive from the cloud!
      await ref.read(watchlistProvider.future);

      // 5. Close the loading dialog
      if (mounted) Navigator.pop(context);

      // 6. Show the success banner
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Added to Watchlist!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _removeItem(String product) async {
    // 1. Show a loading dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Add the item to the Supabase Cloud Database
      await ref.read(apiServiceProvider).removeFromWatchlist(product);
      _controller.clear();

      // 3. 🔄 Force Riverpod to dump the old cache...
      ref.invalidate(watchlistProvider);

      // 4. ⏳ AND wait for the new data to arrive from the cloud!
      await ref.read(watchlistProvider.future);

      // 5. Close the loading dialog
      if (mounted) Navigator.pop(context);

      // 6. Show the success banner
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Removed from Watchlist!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlistAsync = ref.watch(watchlistProvider);

    return Column(
      children: [
        // Input Field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: 'Track a product (e.g. Melk)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Icon(Icons.add),
              )
            ],
          ),
        ),
        // List of Tracked Items
        Expanded(
          child: watchlistAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (items) {
              if (items.isEmpty) return const Center(child: Text('Your watchlist is empty.'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active, color: Colors.amber),
                      title: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(item),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}