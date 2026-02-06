import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> fetchItems(String userId) async {
    final response = await client
        .from('items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createItem(Map<String, dynamic> data) async {
    await client.from('items').insert(data);
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await client.from('items').update(data).eq('id', id);
  }

  Future<void> deleteItem(String id) async {
    await client.from('items').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchListings(String userId) async {
    final response = await client
        .from('listings')
        .select('*, items(*)')
        .eq('user_id', userId)
        .order('listed_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createListing(Map<String, dynamic> data) async {
    await client.from('listings').insert(data);
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await client.from('listings').update(data).eq('id', id);
  }

  Future<void> deleteListing(String id) async {
    await client.from('listings').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchSales(String userId) async {
    final response = await client
        .from('sales')
        .select('*, listings(*), items(*)')
        .eq('user_id', userId)
        .order('sold_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createSale(Map<String, dynamic> data) async {
    await client.from('sales').insert(data);
  }

  Future<void> updateSale(String id, Map<String, dynamic> data) async {
    await client.from('sales').update(data).eq('id', id);
  }

  Future<void> deleteSale(String id) async {
    await client.from('sales').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchItemStock(String userId) async {
    final response = await client
        .from('item_stock')
        .select('*, items(*)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> upsertItemStock(Map<String, dynamic> data) async {
    await client.from('item_stock').upsert(data, onConflict: 'item_id,size,user_id');
  }

  Future<void> updateItemStock(String id, Map<String, dynamic> data) async {
    await client.from('item_stock').update(data).eq('id', id);
  }

  Future<void> deleteItemStock(String id) async {
    await client.from('item_stock').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchPurchases(String userId) async {
    final response = await client
        .from('item_purchases')
        .select('*, items(*)')
        .eq('user_id', userId)
        .order('purchased_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createPurchase(Map<String, dynamic> data) async {
    await client.from('item_purchases').insert(data);
  }

  Future<void> updatePurchase(String id, Map<String, dynamic> data) async {
    await client.from('item_purchases').update(data).eq('id', id);
  }

  Future<void> deletePurchase(String id) async {
    await client.from('item_purchases').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchItemCosts(String userId) async {
    final response = await client.from('item_costs').select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> importVinted(String url) async {
    final response = await client.functions.invoke('import-vinted', body: {'url': url});
    if (response.status != 200) {
      throw Exception(response.data);
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}
