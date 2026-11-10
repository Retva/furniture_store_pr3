import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/formatting.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../state/product_list_notifier.dart';
import '../state/reference_data_notifier.dart';
import '../widgets/entity_detail_page.dart';
import '../widgets/info_table.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final refs = context.watch<ReferenceDataNotifier>();
    return EntityDetailPage<Product>(
      basePath: '/products',
      backLabel: 'К каталогу',
      backLocation: (c) => c.read<ProductListNotifier>().query.toLocation(),
      title: (p) => p.name,
      subtitle: (p) => 'Артикул ${p.sku}',
      rows: (context, p) {
        final manufacturer = refs.manufacturerOf(p.manufacturerId);
        return [
          ('Цена', Text(formatPrice(p.price))),
          (
            'Наличие',
            Text(
              p.inStock ? 'В наличии: ${formatStock(p.stock)}' : 'Под заказ',
            ),
          ),
          (
            'Производитель',
            manufacturer == null
                ? const Text('—')
                : InfoLink(
                    text: '${manufacturer.name} (${manufacturer.country})',
                    onTap: () =>
                        context.go('/manufacturers/${manufacturer.id}'),
                  ),
          ),
          (
            'Категории',
            Wrap(
              spacing: 12,
              children: [
                for (final id in p.categoryIds)
                  InfoLink(
                    text: refs.categoryName(id),
                    onTap: () =>
                        context.go(ProductQuery(categoryId: id).toLocation()),
                  ),
              ],
            ),
          ),
          ('Материалы', Text(refs.materialNames(p.materialIds))),
          ('Габариты (Ш × Г × В)', Text(p.dimensions)),
          ('Цвет', Text(p.color.isEmpty ? '—' : p.color)),
          ('Описание', Text(p.description.isEmpty ? '—' : p.description)),
        ];
      },
    );
  }
}
