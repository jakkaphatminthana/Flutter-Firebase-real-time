import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shopping_list/fetures/shopping/data/database/dummy_items.dart';
import 'package:flutter_shopping_list/fetures/shopping/data/models/grocery_item_model.dart';

class GroceryNotifier extends StateNotifier<List<GroceryItem>> {
  GroceryNotifier() : super([]); //data starter

  void addItem(GroceryItem item) {
    state = [...state, item];
  }

  void addItemIndex(int index, GroceryItem item) {
    state.insert(index, item);
  }

  void removeItem(GroceryItem item) {
    state = state.where((t) => t.id != item.id).toList();
  }
}

//=================================================================================================================
final groeryProvider =
    StateNotifierProvider<GroceryNotifier, List<GroceryItem>>(
        (ref) => GroceryNotifier());

final groceryDummyDataProvider =
    Provider<List<GroceryItem>>((ref) => groceryItems);
