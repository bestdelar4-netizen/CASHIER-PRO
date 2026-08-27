import 'package:flutter/material.dart';

void main() {
  runApp(const CashierProApp());
}

class CashierProApp extends StatelessWidget {
  const CashierProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cashier Pro',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101216),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1D23),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: CashierHome(),
      ),
    );
  }
}

class Product {
  String name;
  double price;
  int quantity;

  Product({
    required this.name,
    required this.price,
    this.quantity = 0,
  });
}

class Sale {
  final DateTime date;
  final List<Product> products;
  final double total;
  final double paid;

  Sale({
    required this.date,
    required this.products,
    required this.total,
    required this.paid,
  });

  double get change => paid - total;
}

class CashierHome extends StatefulWidget {
  const CashierHome({super.key});

  @override
  State<CashierHome> createState() => _CashierHomeState();
}

class _CashierHomeState extends State<CashierHome> {
  int currentIndex = 0;

  final List<Product> products = [
    Product(name: 'منتج 1', price: 10),
    Product(name: 'منتج 2', price: 20),
    Product(name: 'منتج 3', price: 30),
  ];

  final List<Sale> sales = [];

  final List<Product> cart = [];

  double get cartTotal {
    double total = 0;

    for (final product in cart) {
      total += product.price * product.quantity;
    }

    return total;
  }

  void addToCart(Product product) {
    setState(() {
      final existing = cart.indexWhere(
        (item) => item.name == product.name,
      );

      if (existing >= 0) {
        cart[existing].quantity++;
      } else {
        cart.add(
          Product(
            name: product.name,
            price: product.price,
            quantity: 1,
          ),
        );
      }
    });
  }

  void decreaseFromCart(int index) {
    setState(() {
      if (cart[index].quantity > 1) {
        cart[index].quantity--;
      } else {
        cart.removeAt(index);
      }
    });
  }

  void increaseFromCart(int index) {
    setState(() {
      cart[index].quantity++;
    });
  }

  void removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة منتج'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(
                  priceController.text.trim(),
                );

                if (name.isEmpty || price == null || price < 0) {
                  return;
                }

                setState(() {
                  products.add(
                    Product(
                      name: name,
                      price: price,
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  void showEditProductDialog(int index) {
    final product = products[index];

    final nameController = TextEditingController(
      text: product.name,
    );

    final priceController = TextEditingController(
      text: product.price.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل المنتج'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(
                  priceController.text.trim(),
                );

                if (name.isEmpty || price == null || price < 0) {
                  return;
                }

                setState(() {
                  product.name = name;
                  product.price = price;
                });

                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المنتج'),
          content: Text(
            'هل تريد حذف "${products[index].name}"؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  products.removeAt(index);
                });

                Navigator.pop(context);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  void finishSale() {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('السلة فارغة'),
        ),
      );
      return;
    }

    final paidController = TextEditingController(
      text: cartTotal.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إتمام البيع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الإجمالي: ${cartTotal.toStringAsFixed(2)} جنيه',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: paidController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final paid = double.tryParse(
                  paidController.text.trim(),
                );

                if (paid == null || paid < cartTotal) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'المبلغ المدفوع أقل من الإجمالي',
                      ),
                    ),
                  );
                  return;
                }

                final saleProducts = cart
                    .map(
                      (item) => Product(
                        name: item.name,
                        price: item.price,
                        quantity: item.quantity,
                      ),
                    )
                    .toList();

                setState(() {
                  sales.add(
                    Sale(
                      date: DateTime.now(),
                      products: saleProducts,
                      total: cartTotal,
                      paid: paid,
                    ),
                  );

                  cart.clear();
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تمت عملية البيع بنجاح - الباقي: '
                      '${(paid - cartTotal).toStringAsFixed(2)} جنيه',
                    ),
                  ),
                );
              },
              child: const Text('إتمام البيع'),
            ),
          ],
        );
      },
    );
  }

  Widget buildHome() {
    return Column(
      children: [
        buildHeader(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: buildProducts(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: buildCart(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Cashier Pro',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: showAddProductDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج'),
          ),
        ],
      ),
    );
  }

  Widget buildProducts() {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد منتجات',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 170,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Icon(
                  Icons.inventory_2,
                  size: 42,
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${product.price.toStringAsFixed(2)} جنيه',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => addToCart(product),
                        child: const Text('إضافة'),
                      ),
                    ),
                    const SizedBox(width: 5),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showEditProductDialog(index);
                        } else if (value == 'delete') {
                          deleteProduct(index);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('تعديل'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('حذف'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildCart() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.shopping_cart),
                SizedBox(width: 8),
                Text(
                  'السلة',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text('السلة فارغة'),
                  )
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];

                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.price.toStringAsFixed(2)} × '
                          '${item.quantity}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  decreaseFromCart(index),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                              ),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  increaseFromCart(index),
                              icon: const Icon(
                                Icons.add_circle_outline,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  removeFromCart(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الإجمالي',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${cartTotal.toStringAsFixed(2)} جنيه',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: finishSale,
                    icon: const Icon(Icons.check_circle),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('إتمام البيع'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSales() {
    if (sales.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد مبيعات حتى الآن',
          style: TextStyle(fontSize: 20),
        ),
      );
    }

    double totalSales = 0;

    for (final sale in sales) {
      totalSales += sale.total;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: ListTile(
              leading: const Icon(
                Icons.analytics_outlined,
                size: 35,
              ),
              title: const Text('إجمالي المبيعات'),
              subtitle: Text(
                '${totalSales.toStringAsFixed(2)} جنيه',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[sales.length - 1 - index];

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt_long),
                  ),
                  title: Text(
                    'فاتورة #${sales.length - index}',
                  ),
                  subtitle: Text(
                    '${sale.date.day}/'
                    '${sale.date.month}/'
                    '${sale.date.year} - '
                    '${sale.date.hour}:'
                    '${sale.date.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: Text(
                    '${sale.total.toStringAsFixed(2)} جنيه',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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

  Widget buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.store),
            title: const Text('اسم المتجر'),
            subtitle: const Text('Cashier Pro'),
            trailing: const Icon(Icons.edit),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'يمكن تعديل اسم المتجر من الكود حاليًا',
                  ),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Cashier Pro V1'),
            subtitle: const Text(
              'نسخة أولية قابلة للتطوير',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (currentIndex == 0) {
      body = buildHome();
    } else if (currentIndex == 1) {
      body = buildSales();
    } else {
      body = buildSettings();
    }

    return Scaffold(
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'الكاشير',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'المبيعات',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}