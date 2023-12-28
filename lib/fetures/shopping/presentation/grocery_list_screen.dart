import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shopping_list/fetures/shopping/data/database/categories.dart';
import 'package:flutter_shopping_list/fetures/shopping/data/domain/provider/grocery_provider.dart';
import '../data/models/grocery_item_model.dart';
import 'new_item.dart';
import 'package:http/http.dart' as http;

class GroceryListScreen extends ConsumerStatefulWidget {
  const GroceryListScreen({super.key});

  @override
  ConsumerState<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends ConsumerState<GroceryListScreen> {
  var _isLoading = true;
  String? _error;

  //TODO 1: Fetch Data
  void _loadItems() async {
    //URL Database (path, name collection)
    final url = Uri.https(
      'flutter-udemy-9ae8c-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list.json',
    );

    try {
      //TODO 1.1: Request Data Api
      final response = await http.get(url);

      //case error 400
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later';
        });
      }
      //case error data null 404
      if (response.body == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      //TODO 1.2: Convert data fromJson
      final Map<String, dynamic> listData = json.decode(response.body);

      //TODO 1.3: Add Data to List
      for (final item in listData.entries) {
        //จับคู่ข้อมูล enum category กับ firebase
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;

        ref.read(groeryProvider.notifier).addItem(
              GroceryItem(
                id: item.key,
                name: item.value['name'],
                quantity: item.value['quantity'],
                category: category,
              ),
            );

        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _error = 'Something is wrong. $error';
      });
    }
  }

  //TODO 2: go to NewItem screen
  void _addItem() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => const NewItemScreen(),
    ));
  }

  //TODO 3: remove item
  void _removeItem(GroceryItem item) async {
    final groceryData = ref.watch(groeryProvider);
    final index = groceryData.indexOf(item);

    //ลบใน List
    ref.read(groeryProvider.notifier).removeItem(item);

    //URL Database (path, query collection)
    final url = Uri.https(
      'flutter-udemy-9ae8c-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list/${item.id}.json',
    );

    //ลบใน Firebase
    final response = await http.delete(url);

    //กันเผื่อ error แล้วมันไม่ลบ (Undo)
    if (response.statusCode >= 400) {
      ref.read(groeryProvider.notifier).addItemIndex(index, item);
      log('400');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

//=============================================================================================================
  @override
  Widget build(BuildContext context) {
    final groceryData = ref.watch(groeryProvider);
    Widget content = const Center(child: Text('No items added yet.'));

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    if (groceryData.isNotEmpty) {
      content = ListView.builder(
        itemCount: groceryData.length,
        itemBuilder: (ctx, index) {
          return Dismissible(
            onDismissed: (direction) {
              _removeItem(groceryData[index]);
            },
            key: ValueKey(groceryData[index].id),
            child: ListTile(
              title: Text(groceryData[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: groceryData[index].category.color,
              ),
              trailing: Text(
                groceryData[index].quantity.toString(),
              ),
            ),
          );
        },
      );
    }

    //-----------------------------------------------------------------------------------------------------------
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
