import 'package:flutter/material.dart';

import '../../../../utils/responsive.dart';
import '../../../../services/cart_service.dart';
import '../../../../services/app_feedback.dart';
import 'cart_page.dart';

class _Product {
  final String id;
  final String name;
  final String spec;
  final double price;
  final String unit;
  final Color color;
  final IconData icon;
  final String category;

  const _Product({
    required this.id,
    required this.name,
    required this.spec,
    required this.price,
    required this.unit,
    required this.color,
    required this.icon,
    required this.category,
  });

  CartItem toCartItem({int quantity = 1}) => CartItem(
    productId: id,
    name: name,
    spec: spec,
    price: price,
    unit: unit,
    icon: icon,
    color: color,
    quantity: quantity,
  );
}

class AgriMallPage extends StatefulWidget {
  const AgriMallPage({super.key});

  @override
  State<AgriMallPage> createState() => _AgriMallPageState();
}

class _AgriMallPageState extends State<AgriMallPage> {
  int _selectedCategory = 0;
  int _cartCount = 0;

  static const _categories = ['全部', '肥料', '灌溉', '种子', '传感器'];

  static final _allProducts = [
    _Product(
      id: 'p1',
      name: '缓释复合肥',
      spec: 'NPK 15-15-15',
      price: 128,
      unit: '/袋 25kg',
      color: Colors.green,
      icon: Icons.grass,
      category: '肥料',
    ),
    _Product(
      id: 'p2',
      name: '生物有机肥',
      spec: '腐殖酸型',
      price: 89,
      unit: '/袋 20kg',
      color: Colors.brown,
      icon: Icons.compost,
      category: '肥料',
    ),
    _Product(
      id: 'p3',
      name: '滴灌带套装',
      spec: 'φ16mm 1000m',
      price: 256,
      unit: '/套',
      color: Colors.blueAccent,
      icon: Icons.water_drop,
      category: '灌溉',
    ),
    _Product(
      id: 'p4',
      name: '遮阳网',
      spec: '6针加密 4m×50m',
      price: 198,
      unit: '/卷',
      color: Colors.orangeAccent,
      icon: Icons.wb_cloudy,
      category: '灌溉',
    ),
    _Product(
      id: 'p5',
      name: '蔬菜种子礼包',
      spec: '20种应季蔬菜',
      price: 45,
      unit: '/套',
      color: Colors.lightGreen,
      icon: Icons.eco,
      category: '种子',
    ),
    _Product(
      id: 'p6',
      name: '智能传感器',
      spec: '温湿度光照三合一',
      price: 380,
      unit: '/个',
      color: Colors.purpleAccent,
      icon: Icons.sensors,
      category: '传感器',
    ),
    _Product(
      id: 'p7',
      name: '液体菌肥',
      spec: 'EM 复合菌剂 5L',
      price: 68,
      unit: '/桶',
      color: Colors.teal,
      icon: Icons.science_outlined,
      category: '肥料',
    ),
    _Product(
      id: 'p8',
      name: '微喷头套装',
      spec: '360° 可调 50个装',
      price: 145,
      unit: '/箱',
      color: Colors.cyan,
      icon: Icons.water_drop_outlined,
      category: '灌溉',
    ),
    _Product(
      id: 'p9',
      name: '番茄种子',
      spec: '抗病高产品种',
      price: 22,
      unit: '/袋 100粒',
      color: Colors.red,
      icon: Icons.eco_outlined,
      category: '种子',
    ),
    _Product(
      id: 'p10',
      name: '光照传感器',
      spec: '0-200000 Lux',
      price: 185,
      unit: '/个',
      color: Colors.amber,
      icon: Icons.wb_sunny_outlined,
      category: '传感器',
    ),
    _Product(
      id: 'p11',
      name: '水溶肥 A+B',
      spec: '高钾型 10kg+10kg',
      price: 210,
      unit: '/组',
      color: Colors.indigo,
      icon: Icons.inventory_2_outlined,
      category: '肥料',
    ),
    _Product(
      id: 'p12',
      name: 'PE 输水管',
      spec: 'φ25mm 100m',
      price: 320,
      unit: '/卷',
      color: Colors.lightBlue,
      icon: Icons.cable,
      category: '灌溉',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cartCount = CartService.instance.totalCount;
    CartService.instance.countListenable.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartService.instance.countListenable.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    setState(() => _cartCount = CartService.instance.totalCount);
  }

  List<_Product> get _filteredProducts {
    if (_selectedCategory == 0) return _allProducts;
    final cat = _categories[_selectedCategory];
    return _allProducts.where((p) => p.category == cat).toList();
  }

  void _addToCart(_Product product) {
    CartService.instance.addItem(product.toCartItem());
    showAppToast('${product.name} 已加入购物车');
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text(
          '农资商城',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const CartPage()));
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_categories.length, (index) {
                  return _buildChip(index);
                }),
              ),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '该分类暂无商品',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Responsive.gridColumns(context),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProduct(products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(int index) {
    final selected = _selectedCategory == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2B3245) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _categories[index],
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildProduct(_Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: product.color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Center(
              child: Icon(
                product.icon,
                size: 48,
                color: product.color.withValues(alpha: 0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.spec,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '¥${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        Text(
                          product.unit,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _addToCart(product),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B3245),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
