import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CashierPro());
}

// ============================================================
// APP
// ============================================================

class CashierPro extends StatelessWidget {
  const CashierPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CASHIER PRO',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class Product {
  String id;
  String name;
  double price;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get total => product.price * quantity;
}

class Sale {
  final String id;
  final DateTime date;
  final double total;
  final double paid;
  final double change;
  final int items;

  Sale({
    required this.id,
    required this.date,
    required this.total,
    required this.paid,
    required this.change,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total': total,
      'paid': paid,
      'change': change,
      'items': items,
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'].toString(),
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0,
      change: (json['change'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  List<Product> products = [];
  List<Sale> sales = [];

  bool loading = true;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final productsData = prefs.getString('products');
      final salesData = prefs.getString('sales');

      if (productsData != null && productsData.isNotEmpty) {
        final decoded = jsonDecode(productsData);

        if (decoded is List) {
          products = decoded
              .map(
                (item) => Product.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }

      if (salesData != null && salesData.isNotEmpty) {
        final decoded = jsonDecode(salesData);

        if (decoded is List) {
          sales = decoded
              .map(
                (item) => Sale.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }

      darkMode = prefs.getBool('darkMode') ?? false;
    } catch (_) {
      products = [];
      sales = [];
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'products',
      jsonEncode(
        products.map((product) => product.toJson()).toList(),
      ),
    );

    await prefs.setString(
      'sales',
      jsonEncode(
        sales.map((sale) => sale.toJson()).toList(),
      ),
    );

    await prefs.setBool('darkMode', darkMode);
  }

  double get todaySales {
    final now = DateTime.now();

    return sales
        .where(
          (sale) =>
              sale.date.year == now.year &&
              sale.date.month == now.month &&
              sale.date.day == now.day,
        )
        .fold(0.0, (sum, sale) => sum + sale.total);
  }

  int get todayInvoices {
    final now = DateTime.now();

    return sales.where(
      (sale) =>
          sale.date.year == now.year &&
          sale.date.month == now.month &&
          sale.date.day == now.day,
    ).length;
  }

  double get totalSales {
    return sales.fold(
      0.0,
      (sum, sale) => sum + sale.total,
    );
  }

  int get totalProducts {
    return products.length;
  }

  int get totalStock {
    return products.fold(
      0,
      (sum, product) => sum + product.quantity,
    );
  }

  void addProduct(Product product) {
    setState(() {
      products.add(product);
    });

    saveData();
  }

  void updateProduct(Product product) {
    setState(() {});
    saveData();
  }

  void deleteProduct(Product product) {
    setState(() {
      products.removeWhere(
        (item) => item.id == product.id,
      );
    });

    saveData();
  }

  void completeSale(Sale sale) {
    setState(() {
      sales.add(sale);
    });

    saveData();
  }

  void toggleTheme() {
    setState(() {
      darkMode = !darkMode;
    });

    saveData();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final pages = [
      DashboardPage(
        products: products,
        todaySales: todaySales,
        todayInvoices: todayInvoices,
        totalSales: totalSales,
        totalProducts: totalProducts,
        totalStock: totalStock,
      ),
      CashierPage(
        products: products,
        onSaleComplete: completeSale,
        onStockChanged: saveData,
      ),
      ProductsPage(
        products: products,
        onAdd: addProduct,
        onUpdate: updateProduct,
        onDelete: deleteProduct,
      ),
      ReportsPage(
        sales: sales,
      ),
      SettingsPage(
        darkMode: darkMode,
        onThemeChanged: toggleTheme,
      ),
    ];

    const titles = [
      'الرئيسية',
      'الكاشير',
      'المنتجات',
      'التقارير',
      'الإعدادات',
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              titles[currentIndex],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    'V5.0',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: pages[currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: 'الكاشير',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'المنتجات',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'التقارير',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'الإعدادات',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatelessWidget {
  final List<Product> products;
  final double todaySales;
  final int todayInvoices;
  final double totalSales;
  final int totalProducts;
  final int totalStock;

  const DashboardPage({
    super.key,
    required this.products,
    required this.todaySales,
    required this.todayInvoices,
    required this.totalSales,
    required this.totalProducts,
    required this.totalStock,
  });

  @override
  Widget build(BuildContext context) {
    final lowStock =
        products.where((product) => product.quantity <= 5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: const Icon(
                      Icons.point_of_sale,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحبًا بك 👋',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'CASHIER PRO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'نظام إدارة المبيعات والمخزون',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width > 700
                    ? 4
                    : 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              StatCard(
                title: 'مبيعات اليوم',
                value:
                    '${todaySales.toStringAsFixed(2)} ج',
                icon: Icons.payments,
              ),
              StatCard(
                title: 'فواتير اليوم',
                value: '$todayInvoices',
                icon: Icons.receipt_long,
              ),
              StatCard(
                title: 'إجمالي المبيعات',
                value:
                    '${totalSales.toStringAsFixed(2)} ج',
                icon: Icons.trending_up,
              ),
              StatCard(
                title: 'عدد المنتجات',
                value: '$totalProducts',
                icon: Icons.inventory_2,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.inventory,
                size: 32,
              ),
              title: const Text(
                'إجمالي المخزون',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '$totalStock قطعة',
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ExpansionTile(
              leading: Icon(
                lowStock.isEmpty
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
              ),
              title: const Text(
                'حالة المخزون',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                lowStock.isEmpty
                    ? 'المخزون جيد حاليًا'
                    : '${lowStock.length} منتج منخفض المخزون',
              ),
              children: lowStock.isEmpty
                  ? const [
                      ListTile(
                        title: Text(
                          'لا توجد منتجات منخفضة المخزون',
                        ),
                      ),
                    ]
                  : lowStock
                      .map(
                        (product) => ListTile(
                          leading: const Icon(
                            Icons.warning,
                          ),
                          title: Text(product.name),
                          trailing: Text(
                            '${product.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Icon(
              icon,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CASHIER V5
// ============================================================

class CashierPage extends StatefulWidget {
  final List<Product> products;
  final Function(Sale) onSaleComplete;
  final Future<void> Function() onStockChanged;

  const CashierPage({
    super.key,
    required this.products,
    required this.onSaleComplete,
    required this.onStockChanged,
  });

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final List<CartItem> cart = [];

  String searchQuery = '';

  double get total {
    return cart.fold(
      0.0,
      (sum, item) => sum + item.total,
    );
  }

  int get totalItems {
    return cart.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  List<Product> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.products;
    }

    return widget.products.where((product) {
      return product.name.toLowerCase().contains(query);
    }).toList();
  }

  void addToCart(Product product) {
    if (product.quantity <= 0) {
      showMessage(
        context,
        'المنتج "${product.name}" غير متوفر',
      );
      return;
    }

    final index = cart.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index == -1) {
      setState(() {
        cart.add(
          CartItem(
            product: product,
            quantity: 1,
          ),
        );
      });
      return;
    }

    if (cart[index].quantity >= product.quantity) {
      showMessage(
        context,
        'لا توجد كمية إضافية من هذا المنتج',
      );
      return;
    }

    setState(() {
      cart[index].quantity++;
    });
  }

  void increaseItem(CartItem item) {
    if (item.quantity >= item.product.quantity) {
      showMessage(
        context,
        'وصلت للكمية الموجودة في المخزون',
      );
      return;
    }

    setState(() {
      item.quantity++;
    });
  }

  void decreaseItem(CartItem item) {
    if (item.quantity <= 1) {
      setState(() {
        cart.remove(item);
      });
      return;
    }

    setState(() {
      item.quantity--;
    });
  }

  void clearCart() {
    if (cart.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تفريغ السلة'),
          content: const Text(
            'هل تريد إزالة جميع المنتجات من السلة؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  cart.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('تفريغ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkout() async {
    if (cart.isEmpty) {
      showMessage(
        context,
        'السلة فارغة',
      );
      return;
    }

    final paidController = TextEditingController(
      text: total.toStringAsFixed(2),
    );

    final paid = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إتمام البيع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الإجمالي: ${total.toStringAsFixed(2)} ج',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: paidController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع',
                  suffixText: 'ج',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () {
                final value =
                    double.tryParse(
                          paidController.text.trim(),
                        ) ??
                        0;

                Navigator.pop(
                  context,
                  value,
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('تأكيد البيع'),
            ),
          ],
        );
      },
    );

    paidController.dispose();

    if (paid == null) return;

    if (paid < total) {
      showMessage(
        context,
        'المبلغ المدفوع أقل من الإجمالي',
      );
      return;
    }

    final change = paid - total;

    for (final item in cart) {
      if (item.quantity > item.product.quantity) {
        showMessage(
          context,
          'الكمية المطلوبة غير متوفرة',
        );
        return;
      }
    }

    for (final item in cart) {
      item.product.quantity -= item.quantity;
    }

    final sale = Sale(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      date: DateTime.now(),
      total: total,
      paid: paid,
      change: change,
      items: totalItems,
    );

    widget.onSaleComplete(sale);
    await widget.onStockChanged();

    setState(() {
      cart.clear();
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'تمت عملية البيع بنجاح ✅',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              infoRow(
                'الإجمالي',
                '${sale.total.toStringAsFixed(2)} ج',
              ),
              infoRow(
                'المدفوع',
                '${sale.paid.toStringAsFixed(2)} ج',
              ),
              infoRow(
                'الباقي',
                '${sale.change.toStringAsFixed(2)} ج',
              ),
              infoRow(
                'عدد القطع',
                '${sale.items}',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('تم'),
            ),
          ],
        );
      },
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            6,
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              prefixIcon: const Icon(
                Icons.search,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        Expanded(
          flex: 5,
          child: filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    widget.products.isEmpty
                        ? 'لا توجد منتجات\nأضف منتجات من قسم المنتجات'
                        : 'لا يوجد منتج بهذا الاسم',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context)
                                .size
                                .width >
                            900
                            ? 5
                            : MediaQuery.of(context)
                                        .size
                                        .width >
                                    600
                                ? 4
                                : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemCount:
                      filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product =
                        filteredProducts[index];

                    final outOfStock =
                        product.quantity <= 0;

                    return Card(
                      clipBehavior:
                          Clip.antiAlias,
                      child: InkWell(
                        onTap: outOfStock
                            ? null
                            : () =>
                                addToCart(product),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                outOfStock
                                    ? Icons
                                        .remove_shopping_cart
                                    : Icons
                                        .shopping_bag,
                                size: 34,
                              ),
                              const SizedBox(
                                height: 7,
                              ),
                              Text(
                                product.name,
                                maxLines: 2,
                                textAlign:
                                    TextAlign.center,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                '${product.price.toStringAsFixed(2)} ج',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                outOfStock
                                    ? 'نفد المخزون'
                                    : 'المتاح: ${product.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      outOfStock
                                          ? Colors.red
                                          : product.quantity <=
                                                  5
                                              ? Colors.orange
                                              : null,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        const Divider(height: 1),

        Expanded(
          flex: 4,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  4,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'السلة ($totalItems)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (cart.isNotEmpty)
                      TextButton.icon(
                        onPressed: clearCart,
                        icon: const Icon(
                          Icons.delete_sweep,
                        ),
                        label: const Text(
                          'تفريغ',
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: cart.isEmpty
                    ? const Center(
                        child: Text(
                          'السلة فارغة',
                          style:
                              TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: cart.length,
                        itemBuilder:
                            (context, index) {
                          final item =
                              cart[index];

                          return ListTile(
                            dense: true,
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons
                                    .shopping_bag,
                              ),
                            ),
                            title: Text(
                              item.product.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                            subtitle: Text(
                              '${item.product.price.toStringAsFixed(2)} ج × ${item.quantity}',
                            ),
                            trailing: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      decreaseItem(
                                    item,
                                  ),
                                  icon:
                                      const Icon(
                                    Icons.remove,
                                  ),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      increaseItem(
                                    item,
                                  ),
                                  icon:
                                      const Icon(
                                    Icons.add,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  '${item.total.toStringAsFixed(2)} ج',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              Container(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الإجمالي: ${total.toStringAsFixed(2)} ج',
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: checkout,
                      icon: const Icon(
                        Icons.receipt_long,
                      ),
                      label: const Text('بيع'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PRODUCTS
// ============================================================

class ProductsPage extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onAdd;
  final Function(Product) onUpdate;
  final Function(Product) onDelete;

  const ProductsPage({
    super.key,
    required this.products,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ProductsPage> createState() =>
      _ProductsPageState();
}

class _ProductsPageState
    extends State<ProductsPage> {
  String searchQuery = '';

  List<Product> get filteredProducts {
    final query =
        searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.products;
    }

    return widget.products.where((product) {
      return product.name
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  void showProductDialog({
    Product? product,
  }) {
    final nameController =
        TextEditingController(
      text: product?.name ?? '',
    );

    final priceController =
        TextEditingController(
      text: product == null
          ? ''
          : product.price.toString(),
    );

    final quantityController =
        TextEditingController(
      text: product == null
          ? ''
          : product.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            product == null
                ? 'إضافة منتج'
                : 'تعديل المنتج',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText: 'اسم المنتج',
                    prefixIcon:
                        Icon(Icons.inventory_2),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller:
                      priceController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'السعر',
                    suffixText: 'ج',
                    prefixIcon:
                        Icon(Icons.payments),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller:
                      quantityController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText: 'الكمية',
                    prefixIcon:
                        Icon(Icons.numbers),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () {
                final name =
                    nameController.text
                        .trim();

                final price =
                    double.tryParse(
                          priceController
                              .text
                              .trim(),
                        ) ??
                        0;

                final quantity =
                    int.tryParse(
                          quantityController
                              .text
                              .trim(),
                        ) ??
                        0;

                if (name.isEmpty ||
                    price <= 0 ||
                    quantity < 0) {
                  showMessage(
                    context,
                    'أدخل بيانات صحيحة',
                  );
                  return;
                }

                if (product == null) {
                  widget.onAdd(
                    Product(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      name: name,
                      price: price,
                      quantity: quantity,
                    ),
                  );
                } else {
                  product.name = name;
                  product.price = price;
                  product.quantity =
                      quantity;

                  widget.onUpdate(product);
                }

                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'حذف المنتج',
          ),
          content: Text(
            'هل تريد حذف "${product.name}"؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                widget.onDelete(product);
                Navigator.pop(context);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration:
                    InputDecoration(
                  hintText:
                      'ابحث في المنتجات...',
                  prefixIcon:
                      const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                      searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                setState(() {
                                  searchQuery =
                                      '';
                                });
                              },
                              icon:
                                  const Icon(
                                Icons.clear,
                              ),
                            ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        widget.products.isEmpty
                            ? 'لا توجد منتجات\nاضغط + لإضافة منتج'
                            : 'لا يوجد منتج بهذا الاسم',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 19,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(
                        12,
                        0,
                        12,
                        90,
                      ),
                      itemCount:
                          filteredProducts.length,
                      itemBuilder:
                          (context, index) {
                        final product =
                            filteredProducts[
                                index];

                        final lowStock =
                            product.quantity <=
                                5;

                        return Card(
                          child: ListTile(
                            leading:
                                CircleAvatar(
                              child: Icon(
                                lowStock
                                    ? Icons
                                        .warning
                                    : Icons
                                        .inventory_2,
                              ),
                            ),
                            title: Text(
                              product.name,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            subtitle:
                                Text(
                              'السعر: ${product.price.toStringAsFixed(2)} ج\n'
                              'المخزون: ${product.quantity}',
                            ),
                            isThreeLine: true,
                            trailing:
                                PopupMenuButton<
                                    String>(
                              onSelected:
                                  (value) {
                                if (value ==
                                    'edit') {
                                  showProductDialog(
                                    product:
                                        product,
                                  );
                                }

                                if (value ==
                                    'delete') {
                                  confirmDelete(
                                    product,
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) =>
                                      const [
                                PopupMenuItem(
                                  value:
                                      'edit',
                                  child:
                                      Text(
                                    'تعديل',
                                  ),
                                ),
                                PopupMenuItem(
                                  value:
                                      'delete',
                                  child:
                                      Text(
                                    'حذف',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: FloatingActionButton.extended(
            onPressed: () =>
                showProductDialog(),
            icon: const Icon(Icons.add),
            label: const Text(
              'إضافة منتج',
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// REPORTS
// ============================================================

class ReportsPage extends StatelessWidget {
  final List<Sale> sales;

  const ReportsPage({
    super.key,
    required this.sales,
  });

  @override
  Widget build(BuildContext context) {
    final total = sales.fold(
      0.0,
      (sum, sale) => sum + sale.total,
    );

    final totalPaid = sales.fold(
      0.0,
      (sum, sale) => sum + sale.paid,
    );

    final totalChange = sales.fold(
      0.0,
      (sum, sale) => sum + sale.change,
    );

    final items = sales.fold(
      0,
      (sum, sale) => sum + sale.items,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount:
                MediaQuery.of(context)
                        .size
                        .width >
                    700
                    ? 4
                    : 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                title: 'المبيعات',
                value:
                    '${total.toStringAsFixed(2)} ج',
                icon: Icons.analytics,
              ),
              StatCard(
                title: 'الفواتير',
                value: '${sales.length}',
                icon: Icons.receipt_long,
              ),
              StatCard(
                title: 'القطع المباعة',
                value: '$items',
                icon: Icons.shopping_cart,
              ),
              StatCard(
                title: 'المدفوع',
                value:
                    '${totalPaid.toStringAsFixed(2)} ج',
                icon: Icons.payments,
              ),
            ],
          ),
        ),

        if (sales.isNotEmpty)
          Card(
            margin:
                const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: ListTile(
              leading:
                  const Icon(Icons.calculate),
              title: const Text(
                'إجمالي الباقي للعملاء',
              ),
              trailing: Text(
                '${totalChange.toStringAsFixed(2)} ج',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        const Divider(),

        Expanded(
          child: sales.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد مبيعات حتى الآن',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(12),
                  itemCount: sales.length,
                  itemBuilder:
                      (context, index) {
                    final sale =
                        sales[
                            sales.length -
                                1 -
                                index];

                    final shortId =
                        sale.id.length > 6
                            ? sale.id.substring(
                                sale.id.length -
                                    6,
                              )
                            : sale.id;

                    return Card(
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.receipt,
                          ),
                        ),
                        title: Text(
                          'فاتورة #$shortId',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        subtitle:
                            Text(
                          '${sale.date.day}/${sale.date.month}/${sale.date.year}'
                          ' • ${sale.date.hour.toString().padLeft(2, '0')}:${sale.date.minute.toString().padLeft(2, '0')}'
                          ' • ${sale.items} قطعة',
                        ),
                        trailing:
                            Text(
                          '${sale.total.toStringAsFixed(2)} ج',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsPage extends StatelessWidget {
  final bool darkMode;
  final VoidCallback onThemeChanged;

  const SettingsPage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  Future<void> openWhatsApp(
    BuildContext context,
  ) async {
    final uri = Uri.parse(
      'https://wa.me/201030415839',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode:
              LaunchMode.externalApplication,
        );
      } else {
        showMessage(
          context,
          'تعذر فتح واتساب',
        );
      }
    } catch (_) {
      showMessage(
        context,
        'تعذر فتح واتساب',
      );
    }
  }

  Future<void> makeCall(
    BuildContext context,
  ) async {
    final uri = Uri.parse(
      'tel:01012610087',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode:
              LaunchMode.externalApplication,
        );
      } else {
        showMessage(
          context,
          'تعذر فتح تطبيق الاتصال',
        );
      }
    } catch (_) {
      showMessage(
        context,
        'تعذر فتح تطبيق الاتصال',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: SwitchListTile(
            secondary: Icon(
              darkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text(
              'الوضع الليلي',
            ),
            subtitle: const Text(
              'تغيير مظهر التطبيق',
            ),
            value: darkMode,
            onChanged: (_) {
              onThemeChanged();
            },
          ),
        ),

        const SizedBox(height: 15),

        const Text(
          'الدعم والشكاوى',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 55,
                ),
                const SizedBox(height: 10),
                const Text(
                  'للدعم والاستفسارات والشكاوى',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child:
                      FilledButton.icon(
                    onPressed: () =>
                        openWhatsApp(
                      context,
                    ),
                    icon: const Icon(
                      Icons.chat,
                    ),
                    label: const Text(
                      'واتساب الشكاوى',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed: () =>
                        makeCall(context),
                    icon: const Icon(
                      Icons.phone,
                    ),
                    label: const Text(
                      'اتصال مباشر',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'واتساب: 01030415839\n'
                  'المكالمات: 01012610087',
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        const Card(
          child: ListTile(
            leading: Icon(
              Icons.info_outline,
            ),
            title: Text(
              'CASHIER PRO',
            ),
            subtitle: Text(
              'الإصدار V5.0',
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

void showMessage(
  BuildContext context,
  String message,
) {
  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      content: Text(message),
      behavior:
          SnackBarBehavior.floating,
    ),
  );
}