import 'package:flutter_test/flutter_test.dart';
import 'package:stepflow/core/constants/iap_constants.dart';
import 'package:stepflow/core/services/iap_config_service.dart';
import 'package:stepflow/models/shop_item.dart';

void main() {
  test('StepFlow IAP ids and N297 endpoint', () {
    expect(IapConstants.productPrefix, 'sf');
    expect(IapConstants.remoteConfigUrl, 'https://api2.blwsmartware.net/N297.json');
    expect(IapConstants.coinPackIds.first, 'sf_pack_1');
    expect(IapConstants.coinPackIds.last, 'sf_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'sf_remove_ads');
    expect(IapConstants.proProductId, 'sf_pro');
    expect(IapConstants.allProductIds, containsAll([...IapConstants.coinPackIds, 'sf_remove_ads', 'sf_pro']));
    expect(IapConstants.coinsForProduct('sf_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'StepFlow'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson({'disable': 0, 'name': 'StepFlow', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'StepFlow');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
