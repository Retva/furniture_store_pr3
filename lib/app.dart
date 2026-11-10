import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/scroll_behavior.dart';
import 'models/customer.dart';
import 'models/furniture_material.dart';
import 'models/manufacturer.dart';
import 'models/product.dart';
import 'models/product_category.dart';
import 'repositories/category_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/local_category_repository.dart';
import 'repositories/local_customer_repository.dart';
import 'repositories/local_manufacturer_repository.dart';
import 'repositories/local_material_repository.dart';
import 'repositories/local_product_repository.dart';
import 'repositories/local_storage.dart';
import 'repositories/manufacturer_repository.dart';
import 'repositories/material_repository.dart';
import 'repositories/network_simulator.dart';
import 'repositories/product_repository.dart';
import 'state/manufacturer_list_notifier.dart';
import 'state/network_settings_notifier.dart';
import 'state/other_list_notifiers.dart';
import 'state/product_list_notifier.dart';
import 'state/reference_data_notifier.dart';
import 'state/unsaved_changes_guard.dart';

class FurnitureStoreApp extends StatefulWidget {
  const FurnitureStoreApp({
    super.key,
    required this.store,
    required this.report,
    this.network,
  });

  final KeyValueStore store;
  final StorageReport report;
  final NetworkSimulator? network;

  @override
  State<FurnitureStoreApp> createState() => _FurnitureStoreAppState();
}

class _FurnitureStoreAppState extends State<FurnitureStoreApp> {
  late final NetworkSimulator _network = widget.network ?? NetworkSimulator();
  final UnsavedChangesGuard _guard = UnsavedChangesGuard();
  late final GoRouter _router = createRouter(_guard);
  final GlobalKey<ScaffoldMessengerState> _messenger = GlobalKey();

  late final LocalProductRepository _products;
  late final LocalManufacturerRepository _manufacturers;
  late final LocalCategoryRepository _categories;
  late final LocalMaterialRepository _materials;
  late final LocalCustomerRepository _customers;

  EntityStore<T> _storeFor<T>(
    String key,
    String title,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
  ) => EntityStore<T>(
    store: widget.store,
    key: key,
    title: title,
    fromJson: fromJson,
    toJson: toJson,
    report: widget.report,
  );

  @override
  void initState() {
    super.initState();
    _products = LocalProductRepository(
      network: _network,
      store: _storeFor<Product>(
        StorageKeys.products,
        'Товары',
        Product.fromJson,
        (p) => p.toJson(),
      ),
    );
    // Удалить производителя, категорию или материал нельзя, пока на них
    // ссылаются товары: репозиторий спрашивает число ссылок у товаров.
    _manufacturers = LocalManufacturerRepository(
      network: _network,
      usageCount: _products.countByManufacturer,
      store: _storeFor<Manufacturer>(
        StorageKeys.manufacturers,
        'Производители',
        Manufacturer.fromJson,
        (m) => m.toJson(),
      ),
    );
    _categories = LocalCategoryRepository(
      network: _network,
      usageCount: _products.countByCategory,
      store: _storeFor<ProductCategory>(
        StorageKeys.categories,
        'Категории',
        ProductCategory.fromJson,
        (c) => c.toJson(),
      ),
    );
    _materials = LocalMaterialRepository(
      network: _network,
      usageCount: _products.countByMaterial,
      store: _storeFor<FurnitureMaterial>(
        StorageKeys.materials,
        'Материалы',
        FurnitureMaterial.fromJson,
        (m) => m.toJson(),
      ),
    );
    _customers = LocalCustomerRepository(
      network: _network,
      store: _storeFor<Customer>(
        StorageKeys.customers,
        'Покупатели',
        Customer.fromJson,
        (c) => c.toJson(),
      ),
    );

    // Сообщения о миграции или сбросе данных показываются один раз после
    // первого кадра, когда уже есть куда их вывести.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final message in widget.report.messages) {
        _messenger.currentState?.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 8),
          ),
        );
      }
      widget.report.messages.clear();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>.value(value: _products),
        Provider<ManufacturerRepository>.value(value: _manufacturers),
        Provider<CategoryRepository>.value(value: _categories),
        Provider<MaterialRepository>.value(value: _materials),
        Provider<CustomerRepository>.value(value: _customers),
        Provider<UnsavedChangesGuard>.value(value: _guard),
        ChangeNotifierProvider(create: (_) => ProductListNotifier(_products)),
        ChangeNotifierProvider(
          create: (_) => ManufacturerListNotifier(_manufacturers),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryListNotifier(_categories),
        ),
        ChangeNotifierProvider(create: (_) => MaterialListNotifier(_materials)),
        ChangeNotifierProvider(create: (_) => CustomerListNotifier(_customers)),
        ChangeNotifierProvider(
          create: (_) =>
              ReferenceDataNotifier(_categories, _manufacturers, _materials)
                ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => NetworkSettingsNotifier(_network),
        ),
      ],
      child: MaterialApp.router(
        title: 'МебельДом',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        routerConfig: _router,
        scaffoldMessengerKey: _messenger,
        scrollBehavior: const AppScrollBehavior(),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
