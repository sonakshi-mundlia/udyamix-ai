import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_model.dart';
import '../widgets/inventory_widget.dart';
import '../providers/inventory_provider.dart';
import '../providers/language_provider.dart';

class InventoryScreen extends StatefulWidget {
  final InventoryItem? prefillItem;

  const InventoryScreen({super.key, this.prefillItem});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController searchController = TextEditingController();
  String query = "";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchInventory();
    });

    if (widget.prefillItem != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = context.read<InventoryProvider>();

        await provider.fetchInventory();

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => InventoryWidget(
            items: const [],
            prefill: widget.prefillItem,

            onAdd: (item) async {
              await provider.addItem(item);
              await provider.fetchInventory();

              if (mounted) {
                Navigator.of(context).pop();
              }
            },

            onUpdate: (i, item) async {
              await provider.updateItem(
                item.id.toString(),
                item,
              );

              await provider.fetchInventory();

              if (mounted) {
                Navigator.of(context).pop();
              }
            },

            onDelete: (i) async {
              await provider.deleteItem(
                widget.prefillItem!.id.toString(),
              );

              await provider.fetchInventory();

              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      });
    }

    searchController.addListener(() {
      setState(() {
        query = searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;

    final provider = context.watch<InventoryProvider>();

    final items = provider.items.where((item) {
      return item.productName.toLowerCase().contains(query) ||
          (item.brand ?? "").toLowerCase().contains(query);
    }).toList();

    final size = MediaQuery.of(context).size;

    final horizontalPadding = size.width < 400
        ? 10.0
        : size.width < 800
        ? 16.0
        : 32.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(t("inventory.title")),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.fetchInventory,
          child: provider.loading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : Column(
            children: [
              /// SEARCH BAR
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  8,
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: t("inventory.search_hint"),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                    searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              /// INVENTORY
              Expanded(
                child: InventoryWidget(
                  items: items,

                  onAdd: (item) async {
                    await provider.addItem(item);
                    await provider.fetchInventory();

                    if (mounted) {
                      setState(() {});
                    }
                  },

                  onUpdate: (i, item) async {
                    await provider.updateItem(
                      item.id.toString(),
                      item,
                    );

                    await provider.fetchInventory();

                    if (mounted) {
                      setState(() {});
                    }
                  },

                  onDelete: (i) async {
                    await provider.deleteItem(
                      provider.items[i].id.toString(),
                    );

                    await provider.fetchInventory();

                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
